from MedicineEquipment import MedicineEquipment
from DBConnection import DBConnection, sql, Error


class IBaseMedEquipRep(DBConnection):
    def GetAll(self, id_pharmacy_warehouse: int) -> dict:
        get_query = sql.SQL('SELECT medicine_equipment.id, '
                            'medicine_equipment.name, '
                            'medicine_equipment.price,'
                            'warhouse_stores_m_equipment.number '
                            'FROM medicine_equipment '
                            'JOIN warhouse_stores_m_equipment '
                            'ON warhouse_stores_m_equipment.id_medicine_equipment = medicine_equipment.id '
                            'AND warhouse_stores_m_equipment.id_pharmacy_warhouse = {};').format(
            sql.Literal(id_pharmacy_warehouse))
        records = self.Execute(get_query, 'All')
        if not isinstance(records, list):
            return records

        m_equipments = dict()
        for record in records:
            m_equipments[record[0]] = MedicineEquipment(id=record[0], name=record[1], price=record[2], number=record[3])

        return m_equipments

    def GetById(self, id_m_equip: int, id_pharmacy_warehouse: int) -> MedicineEquipment:
        get_query = sql.SQL('SELECT medicine_equipment.id, '
                            'medicine_equipment.name, '
                            'medicine_equipment.price,'
                            'warhouse_stores_m_equipment.number '
                            'FROM medicine_equipment '
                            'JOIN warhouse_stores_m_equipment '
                            'ON warhouse_stores_m_equipment.id_medicine_equipment = medicine_equipment.id '
                            'AND warhouse_stores_m_equipment.id_pharmacy_warhouse = {} '
                            'WHERE medicine_equipment.id = {}').format(
            sql.Literal(id_pharmacy_warehouse),
            sql.Literal(id_m_equip))
        record = self.Execute(get_query, 'One')
        if not isinstance(record, tuple):
            return record

        med_equip = MedicineEquipment(id=record[0], name=record[1], price=record[2], number=record[3])
        return med_equip

    def Append(self, name: str, price: float, number: int, id_pharmacy_warehouse: int) -> MedicineEquipment:
        test_query = sql.SQL('SELECT * FROM medicine_equipment WHERE name = {} AND price = money({});').format(
            sql.Literal(name),
            sql.Literal(price))
        record = self.Execute(test_query, 'One')
        if not isinstance(record, tuple) and record is not None:
            return record

        if record is None:
            append_query = sql.SQL('INSERT INTO medicine_equipment(name, price) '
                                   'VALUES ({}, money({})) RETURNING id;').format(
                sql.Literal(name),
                sql.Literal(price))
            rec = self.Execute(append_query, 'One')
            if not isinstance(rec, tuple):
                return rec

            id_m_equip = rec[0]
        else:
            id_m_equip = record[0]

        new_append_query = sql.SQL('INSERT INTO warhouse_stores_m_equipment(id_medicine_equipment, '
                                   'id_pharmacy_warhouse, number) '
                                   'VALUES ({}, {}, {});').format(
            sql.Literal(id_m_equip),
            sql.Literal(id_pharmacy_warehouse),
            sql.Literal(number))
        result = self.Execute(new_append_query)
        if result != 0:
            return result
        else:
            return MedicineEquipment(id=id_m_equip, name=name, price=price, number=number)

    def Delete(self, id_pharmacy_warehouse: int, id_medicine_equipment: int) -> int:
        count_query = sql.SQL('SELECT COUNT(warhouse_stores_m_equipment.id_medicine_equipment) '
                              'FROM warhouse_stores_m_equipment '
                              'WHERE warhouse_stores_m_equipment.id_medicine_equipment = {};').format(
            sql.Literal(id_medicine_equipment))
        count = self.Execute(count_query, 'One')
        if not isinstance(count, tuple):
            return count

        delete_query = sql.SQL('DELETE FROM warhouse_stores_m_equipment '
                               'WHERE warhouse_stores_m_equipment.id_medicine_equipment = {} '
                               'AND warhouse_stores_m_equipment.id_pharmacy_warhouse = {};').format(
                 sql.Literal(id_medicine_equipment),
                 sql.Literal(id_pharmacy_warehouse))
        delete_result = self.Execute(delete_query)
        if delete_result != 0:
            return delete_result

        if count[0] == 1:
            new_delete_query = sql.SQL('DELETE FROM medicine_equipment WHERE medicine_equipment.id = {};').format(
                sql.Literal(id_medicine_equipment))
            return self.Execute(new_delete_query)
        else:
            return 0

    def Update(self, m_equip: MedicineEquipment, id_pharmacy_warhouse: int) -> int:
        update_query = sql.SQL('UPDATE medicine_equipment '
                               'SET name = {}, '
                               'price = money({}) '
                               'WHERE id = {};').format(
            sql.Literal(m_equip.name),
            sql.Literal(m_equip.price),
            sql.Literal(m_equip.id))
        result = self.Execute(update_query)
        if result != 0:
            return result

        new_update_query = sql.SQL('UPDATE warhouse_stores_m_equipment '
                                   'SET number = {} '
                                   'WHERE warhouse_stores_m_equipment.id_medicine_equipment = {} AND '
                                   'warhouse_stores_m_equipment.id_pharmacy_warhouse = {};').format(
            sql.Literal(m_equip.number),
            sql.Literal(m_equip.id),
            sql.Literal(id_pharmacy_warhouse))
        new_result = self.Execute(new_update_query)
        return new_result

    def MostExpMEquip(self, id_pharmacy_warehouse: int) -> MedicineEquipment:
        query = sql.SQL('SELECT medicine_equipment.id, medicine_equipment.name, '
                        'medicine_equipment.price, warhouse_stores_m_equipment.number '
                        'FROM warhouse_stores_m_equipment '
                        'JOIN medicine_equipment '
                        'ON medicine_equipment.id = warhouse_stores_m_equipment.id_medicine_equipment '
                        'WHERE warhouse_stores_m_equipment.id_pharmacy_warhouse = {} '
                        'AND medicine_equipment.price = (SELECT MAX(medicine_equipment.price) FROM medicine_equipment '
                        'JOIN warhouse_stores_m_equipment '
                        'ON warhouse_stores_m_equipment.id_medicine_equipment = medicine_equipment.id '
                        'WHERE warhouse_stores_m_equipment.id_pharmacy_warhouse = {});').format(
            sql.Literal(id_pharmacy_warehouse),
            sql.Literal(id_pharmacy_warehouse)
        )
        record = self.Execute(query=query, mode='One')
        if not isinstance(record, tuple):
            return record

        mequip = MedicineEquipment(id=record[0], name=record[1], price=record[2], number=record[3])
        return mequip
