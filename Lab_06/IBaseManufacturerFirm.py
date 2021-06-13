from ManufacturerFirm import ManufacturerFirm
from DBConnection import DBConnection, sql, Error


class IBaseManufacturerFirm(DBConnection):
    def GetAll(self) -> dict:
        records = self.Execute(query='SELECT * FROM manufacturer_firm;', mode='All')
        if not isinstance(records, list):
            return records

        firms = dict()
        for record in records:
            firms[record[0]] = ManufacturerFirm(id=record[0], name=record[1], address=record[2])

        return firms

    def GetById(self, firm_id: int) -> ManufacturerFirm:
        get_query = sql.SQL('SELECT * FROM manufacturer_firm WHERE id = {};').format(
            sql.Literal(firm_id))
        record = self.Execute(query=get_query, mode='One')
        if not isinstance(record, tuple):
            return record

        return ManufacturerFirm(id=record[0], name=record[1], address=record[2])

    def Append(self, name: str, address: str) -> ManufacturerFirm:
        append_query = sql.SQL('INSERT INTO manufacturer_firm(name, address) VALUES ({}, {}) RETURNING id;').format(
            sql.Literal(name),
            sql.Literal(address))
        firm_id = self.Execute(query=append_query, mode='One')
        if not isinstance(firm_id, tuple):
            return firm_id

        return ManufacturerFirm(id=firm_id[0], name=name, address=address)

    def Delete(self, manufacturer_firm: ManufacturerFirm) -> int:
        delete_query = sql.SQL('DELETE FROM manufacturer_firm WHERE id = {};').format(
            sql.Literal(manufacturer_firm.id))
        return self.Execute(query=delete_query)

    def Update(self, manufacturer_firm: ManufacturerFirm) -> int:
        update_query = sql.SQL('UPDATE manufacturer_firm SET name = {}, address = {} WHERE id = {};').format(
            sql.Literal(manufacturer_firm.name),
            sql.Literal(manufacturer_firm.address),
            sql.Literal(manufacturer_firm.id))
        return self.Execute(query=update_query)
