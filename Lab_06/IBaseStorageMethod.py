from StorageMethod import StorageMethod
from DBConnection import DBConnection, sql, Error


class IBaseStorageMethod(DBConnection):
    def GetAll(self) -> dict:
        try:
            self.start_connection()
            self.cursor.execute('SELECT * FROM storage_method ORDER BY id')
            records = self.cursor.fetchall()

            sm = dict()

            for record in records:
                sm[record[0]] = StorageMethod(id=record[0], name=record[1])

            if self.connection:
                self.finish_connection()
                return sm

        except (Exception, Error) as error:
            return error

    def GetById(self, id_sm: int) -> StorageMethod:
        try:
            self.start_connection()
            get_query = sql.SQL('SELECT * FROM storage_method WHERE id = {}').format(
                sql.Literal(id_sm)
            )
            self.cursor.execute(get_query)
            record = self.cursor.fetchone()

            storage_method = StorageMethod(id=record[0], name=record[1])

            if self.connection:
                self.finish_connection()
                return storage_method

        except (Exception, Error) as error:
            return error

    def Append(self, name: str) -> StorageMethod:
        try:
            self.start_connection()
            append_query = sql.SQL('INSERT INTO storage_method(name) VALUES ({}) RETURNING id;').format(
                sql.Literal(name))
            self.cursor.execute(append_query)
            sm_id = self.cursor.fetchone()
            self.connection.commit()

            new_sm = StorageMethod(id=sm_id, name=name)

            if self.connection:
                self.finish_connection()
                return new_sm

        except (Exception, Error) as error:
            return error

    def Delete(self, storage_method: StorageMethod) -> int:
        try:
            self.start_connection()
            delete_query = sql.SQL('DELETE FROM storage_method WHERE id = {};').format(
                sql.Literal(storage_method.id))
            self.cursor.execute(delete_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error

    def Update(self, storage_method: StorageMethod) -> int:
        try:
            self.start_connection()
            update_query = sql.SQL('UPDATE storage_method SET name = {} WHERE id = {};').format(
                sql.Literal(storage_method.name),
                sql.Literal(storage_method.id))
            self.cursor.execute(update_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error
