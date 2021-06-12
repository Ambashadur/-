from MedicineForm import MedicineForm
from DBConnection import DBConnection, sql, Error

class IBaseMedicineForm(DBConnection):
    def GetAll(self) -> dict:
        try:
            self.start_connection()
            self.cursor.execute('SELECT * FROM medicine_form')
            records = self.cursor.fetchall()
            forms = dict()

            for record in records:
                forms[record[0]] = MedicineForm(id=record[0], name=record[1])

            if self.connection:
                self.finish_connection()
                return forms

        except (Exception, Error) as error:
            return error

    def GetById(self, id: int) -> MedicineForm:
        try:
            self.start_connection()
            get_query = sql.SQL('SELECT * FROM medicine WHERE id = {}').format(
                sql.Literal(id)
            )
            self.cursor.execute(get_query)
            record = self.cursor.fetchone()

            form = MedicineForm(id=record[0], name=record[1])

            if self.connection:
                self.finish_connection()
                return form

        except (Exception, Error) as error:
            return error

    def Append(self, name: str) -> MedicineForm:
        try:
            self.start_connection()
            append_query = sql.SQL('INSERT INTO medicine_form(name) '
                                   'VALUES ({}) RETURNING id;').format(
                sql.Literal(name))

            self.cursor.execute(append_query)
            form_id = self.cursor.fetchone()
            self.connection.commit()

            new_worker = MedicineForm(id=form_id[0], name=name)

            if self.connection:
                self.finish_connection()
                return new_worker

        except (Exception, Error) as error:
            return error

    def Delete(self, medicine_form: MedicineForm) -> int:
        try:
            self.start_connection()
            delete_query = sql.SQL('DELETE FROM medicine_form WHERE id = {};').format(
                sql.Literal(medicine_form.id))
            self.cursor.execute(delete_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error

    def Update(self, medicine_form: MedicineForm) -> int:
        try:
            self.start_connection()
            update_query = sql.SQL('UPDATE worker SET name = {} '
                                   'WHERE id = {};').format(
                sql.Literal(medicine_form.name),
                sql.Literal(medicine_form.id)
            )
            self.cursor.execute(update_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error
