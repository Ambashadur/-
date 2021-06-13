from MedicineForm import MedicineForm
from DBConnection import DBConnection, sql, Error


class IBaseMedicineForm(DBConnection):
    def GetAll(self) -> dict:
        records = self.Execute(query='SELECT * FROM medicine_form;', mode='All')
        if not isinstance(records, list):
            return records

        forms = dict()
        for record in records:
            forms[record[0]] = MedicineForm(id=record[0], name=record[1])

        return forms

    def GetById(self, mf_id: int) -> MedicineForm:
        get_query = sql.SQL('SELECT * FROM medicine WHERE id = {}').format(
            sql.Literal(mf_id))
        record = self.Execute(query=get_query, mode='One')
        if not isinstance(record, tuple):
            return record

        return MedicineForm(id=record[0], name=record[1])

    def Append(self, name: str) -> MedicineForm:
        append_query = sql.SQL('INSERT INTO medicine_form(name) '
                               'VALUES ({}) RETURNING id;').format(
            sql.Literal(name))
        form_id = self.Execute(query=append_query, mode='One')
        if not isinstance(form_id, tuple):
            return form_id

        new_mf = MedicineForm(id=form_id[0], name=name)
        return new_mf

    def Delete(self, medicine_form: MedicineForm) -> int:
        delete_query = sql.SQL('DELETE FROM medicine_form WHERE id = {};').format(
            sql.Literal(medicine_form.id))
        return self.Execute(query=delete_query)

    def Update(self, medicine_form: MedicineForm) -> int:
        update_query = sql.SQL('UPDATE worker SET name = {} WHERE id = {};').format(
            sql.Literal(medicine_form.name),
            sql.Literal(medicine_form.id))
        return update_query
