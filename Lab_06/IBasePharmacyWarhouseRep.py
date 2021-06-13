from PharmacyWarhouse import PharmacyWarhouse
from Medicine import Medicine
from DBConnection import DBConnection, sql


class IBasePharmacyWarhouseRep(DBConnection):
    def GetAll(self) -> dict:
        get_query = sql.SQL('SELECT * FROM pharmacy_warhouse ORDER BY id;')
        records = self.Execute(get_query, 'All')
        if not isinstance(records, list):
            return records

        p_warehouses = dict()
        for record in records:
            p_warehouses[record[0]] = PharmacyWarhouse(id=record[0], op_hours=record[1], adr=record[2])

        return p_warehouses

    def GetById(self, id: int) -> PharmacyWarhouse:
        get_query = sql.SQL('SELECT * FROM pharmacy_warhouse WHERE id = {};').format(
            sql.Literal(id))
        record = self.Execute(get_query, 'One')
        if not isinstance(record, tuple):
            return record

        return PharmacyWarhouse(id=record[0], op_hours=record[1], adr=record[2])

    def Append(self, o_opening_hours: str, o_address: str) -> PharmacyWarhouse:
        append_query = sql.SQL('INSERT INTO pharmacy_warhouse(opening_hours, address) '
                               'VALUES ({}, {}) RETURNING id;').format(
            sql.Literal(o_opening_hours),
            sql.Literal(o_address))
        pw_id = self.Execute(append_query, 'One')
        if not isinstance(pw_id, tuple):
            return pw_id

        return PharmacyWarhouse(id=pw_id[0], op_hours=o_opening_hours, adr=o_address)

    def Delete(self, p_warhouse_object: PharmacyWarhouse) -> int:
        delete_query = sql.SQL('DELETE FROM pharmacy_warhouse WHERE id = {};').format(
            sql.Literal(p_warhouse_object.id))
        return self.Execute(delete_query)

    def Update(self, p_warhouse_object: PharmacyWarhouse) -> int:
        update_query = sql.SQL('UPDATE pharmacy_warhouse SET address = {}, opening_hours = {} WHERE id = {};').format(
            sql.Literal(p_warhouse_object.address),
            sql.Literal(p_warhouse_object.opening_hours),
            sql.Literal(p_warhouse_object.id))
        return self.Execute(update_query)

    def MedsInQuarantine(self, id_pharmacy_warehouse: int, mf_dict: dict, manf_dict: dict, sm_dict: dict, pg_dict: dict):
        query = sql.SQL('SELECT * FROM medicine '
                        'JOIN department_stores_medicine ON department_stores_medicine.id_medicine = medicine.id '
                        'JOIN storage_department '
                        'ON storage_department.id = department_stores_medicine.id_storage_department '
                        'JOIN pharmacy_warhouse ON pharmacy_warhouse.id = storage_department.id_pharmacy_warhouse '
                        'WHERE medicine.date_quarantine_zone IS NOT NULL '
                        'AND medicine.return_distruction_date IS NULL '
                        'AND pharmacy_warhouse.id = {};').format(
            sql.Literal(id_pharmacy_warehouse))
        records = self.Execute(query=query, mode='All')
        if not isinstance(records, list):
            return records

        meds = dict()
        for record in records:
            meds[record[0]] = Medicine(id=record[0], price=record[1], name=record[2], expiration_date=record[3],
                                       series=record[4], date_quarantine_zone=record[5],
                                       return_distruction_date=record[6], gross_weight=record[7],
                                       medicine_form=mf_dict[record[8]], manufacturer_firm=manf_dict[record[9]],
                                       storage_method=sm_dict[record[10]], pharmacological_group=pg_dict[record[11]])

        return meds
