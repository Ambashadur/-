from PharmacologicalGroup import PharmacologicalGroup
from DBConnection import DBConnection, sql, Error

class IBasePharmacologicalGroup(DBConnection):
    def GetAll(self) -> dict:
        try:
            self.start_connection()
            self.cursor.execute('SELECT * FROM pharmacological_group;')
            records = self.cursor.fetchall()
            p_groups = dict()

            for record in records:
                p_groups[record[0]] = PharmacologicalGroup(id=record[0], name=record[1])

            if self.connection:
                self.finish_connection()
                return p_groups

        except (Exception, Error) as error:
            return error

    def GetById(self, pg_id) -> PharmacologicalGroup:
        try:
            self.finish_connection()
            get_query = sql.SQL('SELECT * FROM pharmacological_group WHERE id = {};').format(
                sql.Literal(pg_id)
            )
            self.cursor.execute(get_query)
            record = self.cursor.fetchone()
            pg = PharmacologicalGroup(id=record[0], name=record[1])

            if self.connection:
                self.finish_connection()
                return pg

        except (Exception, Error) as error:
            return error

    def Append(self, name: str) -> PharmacologicalGroup:
        try:
            self.start_connection()
            append_query = sql.SQL('INSERT INTO pharmacological_group(name) '
                                   'VALUES ({}) RETURNING id;').format(
                sql.Literal(name)
            )
            self.cursor.execute(append_query)
            pg_id = self.cursor.fetchone()
            self.connection.commit()
            new_pg = PharmacologicalGroup(id=pg_id[0], name=name)

            if self.connection:
                self.finish_connection()
                return new_pg

        except (Exception, Error) as error:
            return error

    def Delete(self, pharmacological_group: PharmacologicalGroup) -> int:
        try:
            self.start_connection()
            delete_query = sql.SQL('DELETE FROM pharmacological_group WHERE id = {};').format(
                sql.Literal(pharmacological_group.id)
            )
            self.cursor.execute(delete_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error

    def Update(self, pg_object: PharmacologicalGroup) -> int:
        try:
            self.start_connection()
            update_query = sql.SQL('UPDATE pharmacological_group '
                                   'SET name = {} '
                                   'WHERE id = {};').format(
                sql.Literal(pg_object.name),
                sql.Literal(pg_object.id)
            )
            self.cursor.execute(update_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error