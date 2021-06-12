from MedicineEquipment import MedicineEquipment
from DBConnection import DBConnection, sql, Error


class IBaseMedEquipRep(DBConnection):
    def GetAll(self, id_pharmacy_warehouse: int) -> dict:
        try:
            self.start_connection()
            get_query = sql.SQL('SELECT medicine_equipment.id, '
                                'medicine_equipment.name, '
                                'medicine_equipment.price,'
                                'warhouse_stores_m_equipment.number '
                                'FROM medicine_equipment '
                                'JOIN warhouse_stores_m_equipment '
                                'ON warhouse_stores_m_equipment.id_medicine_equipment = medicine_equipment.id '
                                'AND warhouse_stores_m_equipment.id_pharmacy_warhouse = {};').format(
                sql.Literal(id_pharmacy_warehouse)
            )

            self.cursor.execute(get_query)
            records = self.cursor.fetchall()
            m_equipments = dict()

            for record in records:
                m_equipments[record[0]] = MedicineEquipment(id=record[0], name=record[1],
                                                            price=record[2], number=record[3])

            if self.connection:
                self.finish_connection()
                return m_equipments

        except (Exception, Error) as error:
            return error

    def GetById(self, id_m_equip: int, id_pharmacy_warehouse: int) -> MedicineEquipment:
        try:
            self.start_connection()
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
                sql.Literal(id_m_equip)
            )

            self.cursor.execute(get_query)
            record = self.cursor.fetchone()

            m_eqipment = MedicineEquipment(id=record[0], name=record[1], price=record[2], number=record[3])

            if self.connection:
                self.finish_connection()
                return m_eqipment

        except (Exception, Error) as error:
            return error

    def Append(self, name: str, price: float, number: int, id_pharmacy_warehouse: int) -> MedicineEquipment:
        try:
            self.start_connection()
            test_query = sql.SQL('SELECT * FROM medicine_equipment WHERE name = {} AND price = money({});').format(
                sql.Literal(name),
                sql.Literal(price)
            )

            self.cursor.execute(test_query)
            record = self.cursor.fetchone()

            if record is None:
                append_query = sql.SQL('INSERT INTO medicine_equipment(name, price) '
                                       'VALUES ({}, money({})) RETURNING id;').format(
                    sql.Literal(name),
                    sql.Literal(price)
                )

                self.cursor.execute(append_query)
                id_m_equip = self.cursor.fetchone()
                self.connection.commit()
            else:
                id_m_equip = record[0]

            new_append_query = sql.SQL('INSERT INTO warhouse_stores_m_equipment(id_medicine_equipment, id_pharmacy_warhouse, number) '
                                       'VALUES ({}, {}, {});').format(
                sql.Literal(id_m_equip),
                sql.Literal(id_pharmacy_warehouse),
                sql.Literal(number)
            )

            self.cursor.execute(new_append_query)
            self.connection.commit()

            new_medicine_equipment = MedicineEquipment(id=id_m_equip, name=name, price=price, number=number)

            if self.connection:
                self.finish_connection()
                return new_medicine_equipment

        except (Exception, Error) as error:
            return error

    def Delete(self, id_pharmacy_warehouse: int, id_medicine_equipment: int) -> int:
        try:
            self.start_connection()
            count_query = sql.SQL('SELECT COUNT(warhouse_stores_m_equipment.id_medicine_equipment) '
                                  'FROM warhouse_stores_m_equipment '
                                  'WHERE warhouse_stores_m_equipment.id_medicine_equipment = {};').format(
                sql.Literal(id_medicine_equipment)
            )
            self.cursor.execute(count_query)
            count = self.cursor.fetchone()

            delete_query = sql.SQL('DELETE FROM warhouse_stores_m_equipment '
                                   'WHERE warhouse_stores_m_equipment.id_medicine_equipment = {} '
                                   'AND warhouse_stores_m_equipment.id_pharmacy_warhouse = {};').format(
                sql.Literal(id_medicine_equipment),
                sql.Literal(id_pharmacy_warehouse)
            )

            self.cursor.execute(delete_query)
            self.connection.commit()

            if count == 1:
                delete_query = sql.SQL('DELETE FROM medicine_equipment WHERE medicine_equipment.id = {};').format(
                    sql.Literal(id_medicine_equipment)
                )
                self.cursor.execute(delete_query)
                self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error

    def Update(self, m_equip: MedicineEquipment, id_pharmacy_warhouse: int) -> int:
        try:
            self.start_connection()
            update_query = sql.SQL('UPDATE medicine_equipment '
                                   'SET name = {}, '
                                   'price = money({}) '
                                   'WHERE id = {};').format(
                sql.Literal(m_equip.name),
                sql.Literal(m_equip.price),
                sql.Literal(m_equip.id)
            )
            self.cursor.execute(update_query)
            self.connection.commit()

            new_update_query = sql.SQL('UPDATE warhouse_stores_m_equipment '
                                       'SET number = {} '
                                       'WHERE warhouse_stores_m_equipment.id_medicine_equipment = {} AND '
                                       'warhouse_stores_m_equipment.id_pharmacy_warhouse = {};').format(
                sql.Literal(m_equip.number),
                sql.Literal(m_equip.id),
                sql.Literal(id_pharmacy_warhouse)
            )

            self.cursor.execute(new_update_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error

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
