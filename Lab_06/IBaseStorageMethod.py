from StorageMethod import StorageMethod
from DBConnection import DBConnection, sql, Error


class IBaseStorageMethod(DBConnection):
    def GetAll(self) -> dict:
        records = self.Execute(query='SELECT * FROM storage_method ORDER BY id', mode='All')
        if not isinstance(records, list):
            return records

        methods = dict()
        for record in records:
            methods[record[0]] = StorageMethod(id=record[0], name=record[1])

        return methods

    def GetById(self, id_sm: int) -> StorageMethod:
        get_query = sql.SQL('SELECT * FROM storage_method WHERE id = {}').format(
            sql.Literal(id_sm))
        record = self.Execute(query=get_query, mode='One')
        if not isinstance(record, tuple):
            return record

        return StorageMethod(id=record[0], name=record[1])

    def Append(self, name: str) -> StorageMethod:
        append_query = sql.SQL('INSERT INTO storage_method(name) VALUES ({}) RETURNING id;').format(
            sql.Literal(name))
        sm_id = self.Execute(query=append_query, mode='One')
        if not isinstance(sm_id, tuple):
            return sm_id

        return StorageMethod(id=sm_id[0], name=name)

    def Delete(self, storage_method: StorageMethod) -> int:
        delete_query = sql.SQL('DELETE FROM storage_method WHERE id = {};').format(
            sql.Literal(storage_method.id))
        return self.Execute(query=delete_query)

    def Update(self, storage_method: StorageMethod) -> int:
        update_query = sql.SQL('UPDATE storage_method SET name = {} WHERE id = {};').format(
            sql.Literal(storage_method.name),
            sql.Literal(storage_method.id))
        return self.Execute(query=update_query)
