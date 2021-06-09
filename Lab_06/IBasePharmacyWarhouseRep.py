from PharmacyWarhouse import PharmacyWarhouse
from DBConnection import DBConnection, sql, Error


class IBasePharmacyWarhouseRep(DBConnection):
    
    def GetAll(self) -> dict:
        try:
            self.start_connection()
            self.cursor.execute('SELECT * FROM pharmacy_warhouse ORDER BY id;')
            records = self.cursor.fetchall()

            p_warhouses = dict()

            for record in records:
                p_warhouses[record[0]] = PharmacyWarhouse(id=record[0], op_hours=record[1], adr=record[2])

            if self.connection:
                self.finish_connection()
                return p_warhouses

        except (Exception, Error) as error:
            return error

    def GetById(self, id: int) -> PharmacyWarhouse:
        try:
            self.start_connection()

            get_query = sql.SQL('SELECT * FROM pharmacy_warhouse WHERE id = {}').format(
                sql.Literal(id)
            )

            self.cursor.execute(get_query)
            record = self.cursor.fetchone()

            p_warhouse = PharmacyWarhouse(id=record[0], op_hours=record[1], adr=record[2])

            if self.connection:
                self.finish_connection()
                return p_warhouse

        except (Exception, Error) as error:
            return error

    def Append(self, o_opening_hours: str, o_address: str) -> PharmacyWarhouse:
        try:
            self.start_connection()

            append_query = sql.SQL('INSERT INTO pharmacy_warhouse(opening_hours, address) VALUES ({}, {});').format(
                sql.Literal(o_opening_hours),
                sql.Literal(o_address)
            )
            
            self.cursor.execute(append_query)
            self.connection.commit()

            new_pharmacy_warhouse = PharmacyWarhouse(id=self.cursor.lastrowid, op_hours=o_opening_hours, adr=o_address)

            if self.connection:
                self.finish_connection()
                return new_pharmacy_warhouse
                
        except (Exception, Error) as error:
            return error

    def Delete(self, p_warhouse_object: PharmacyWarhouse) -> int:
        try:
            self.start_connection()

            delete_query = sql.SQL('DELETE FROM pharmacy_warhouse WHERE id = {};').format(
                sql.Literal(p_warhouse_object.id)
            )

            self.cursor.execute(delete_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0
            
        except (Exception, Error) as error:
            return error

    def Update(self, p_warhouse_object: PharmacyWarhouse) -> int:
        try:
            self.start_connection()

            update_query = sql.SQL('UPDATE pharmacy_warhouse SET address = {}, opening_hours = {} WHERE id = {};').format(
                sql.Literal(p_warhouse_object.address),
                sql.Literal(p_warhouse_object.opening_hours),
                sql.Literal(p_warhouse_object.id)
            )

            self.cursor.execute(update_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error

