from ManufacturerFirm import ManufacturerFirm
from DBConnection import DBConnection, sql, Error


class IBaseManufacturerFirm(DBConnection):
    def GetAll(self) -> dict:
        try:
            self.start_connection()
            self.cursor.execute('SELECT * FROM manufacturer_firm;')
            records = self.cursor.fetchall()
            firms = dict()

            for record in records:
                firms[record[0]] = ManufacturerFirm(id=record[0], name=record[1], address=record[2])

            if self.connection:
                self.finish_connection()
                return firms

        except (Exception, Error) as error:
            return error

    def GetById(self, firm_id: int) -> ManufacturerFirm:
        try:
            self.start_connection()
            get_query = sql.SQL('SELECT * FROM manufacturer_firm WHERE id = {};').format(
                sql.Literal(firm_id)
            )
            self.cursor.execute(get_query)
            record = self.cursor.fetchone()
            firm = ManufacturerFirm(id=record[0], name=record[1], address=record[2])

            if self.connection:
                self.finish_connection()
                return firm

        except (Exception, Error) as error:
            return error

    def Append(self, name: str, address: str) -> ManufacturerFirm:
        try:
            self.start_connection()
            append_query = sql.SQL('INSERT INTO manufacturer_firm(name, address) '
                                   'VALUES ({}, {}) RETURNING id;').format(
                sql.Literal(name),
                sql.Literal(address)
            )
            self.cursor.execute(append_query)
            firm_id = self.cursor.fetchone()
            self.connection.commit()

            new_firm = ManufacturerFirm(id=firm_id[0], name=name, address=address)

            if self.connection:
                self.finish_connection()
                return new_firm

        except (Exception, Error) as error:
            return error

    def Delete(self, manufacturer_firm: ManufacturerFirm) -> int:
        try:
            self.start_connection()
            delete_query = sql.SQL('DELETE FROM manufacturer_firm WHERE id = {};').format(
                sql.Literal(manufacturer_firm.id)
            )
            self.cursor.execute(delete_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error

    def Update(self, manufacturer_firm: ManufacturerFirm) -> int:
        try:
            self.start_connection()
            update_query = sql.SQL('UPDATE manufacturer_firm SET name = {}, address = {} '
                                   'WHERE id = {};').format(
                sql.Literal(manufacturer_firm.name),
                sql.Literal(manufacturer_firm.address),
                sql.Literal(manufacturer_firm.id)
            )
            self.cursor.execute(update_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error