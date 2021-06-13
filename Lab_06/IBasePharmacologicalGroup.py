from PharmacologicalGroup import PharmacologicalGroup
from DBConnection import DBConnection, sql, Error


class IBasePharmacologicalGroup(DBConnection):
    def GetAll(self) -> dict:
        records = self.Execute(query='SELECT * FROM pharmacological_group', mode='All')
        if not isinstance(records, list):
            return records

        groups = dict()
        for record in records:
            groups[record[0]] = PharmacologicalGroup(id=record[0], name=record[1])

        return groups

    def GetById(self, pg_id) -> PharmacologicalGroup:
        get_query = sql.SQL('SELECT * FROM pharmacological_group WHERE id = {};').format(
            sql.Literal(pg_id))
        record = self.Execute(query=get_query, mode='One')
        if not isinstance(record, tuple):
            return record

        return PharmacologicalGroup(id=record[0], name=record[1])

    def Append(self, name: str) -> PharmacologicalGroup:
        append_query = sql.SQL('INSERT INTO pharmacological_group(name) VALUES ({}) RETURNING id;').format(
            sql.Literal(name))
        pg_id = self.Execute(query=append_query, mode='One')
        if not isinstance(pg_id, tuple):
            return pg_id

        return PharmacologicalGroup(id=pg_id[0], name=name)

    def Delete(self, pharmacological_group: PharmacologicalGroup) -> int:
        delete_query = sql.SQL('DELETE FROM pharmacological_group WHERE id = {};').format(
            sql.Literal(pharmacological_group.id))
        return self.Execute(query=delete_query)

    def Update(self, pg_object: PharmacologicalGroup) -> int:
        update_query = sql.SQL('UPDATE pharmacological_group SET name = {} WHERE id = {};').format(
            sql.Literal(pg_object.name),
            sql.Literal(pg_object.id))
        return self.Execute(query=update_query)
