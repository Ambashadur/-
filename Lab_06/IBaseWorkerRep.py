from Worker import Worker, PharmacyWarhouse, WorkerPosition
from DBConnection import DBConnection, sql, Error


class IBaseWorkerRep(DBConnection):
    def GetAll(self, p_warhouse_obj: PharmacyWarhouse, wor_pos_dict: dict) -> dict:
        get_query = sql.SQL('SELECT * FROM worker WHERE id_warhouse = {} ORDER BY id;').format(
            sql.Literal(p_warhouse_obj.id))
        records = self.Execute(query=get_query, mode='All')
        if not isinstance(records, list):
            return records

        workers = dict()
        for record in records:
            workers[record[0]] = Worker(id=record[0], name=record[1], surname=record[2], p_warhouse=p_warhouse_obj,
                                        pos=wor_pos_dict[record[4]])

        return workers

    def GetById(self, w_id: int, pw_object: PharmacyWarhouse, wor_pos_dict: dict) -> Worker:
        get_query = sql.SQL('SELECT * FROM worker WHERE id = {};').format(
            sql.Literal(w_id))
        record = self.Execute(query=get_query, mode='One')
        if not isinstance(record, tuple):
            return record

        return Worker(id=record[0], name=record[1], surname=record[2], p_warhouse=pw_object,
                      pos=wor_pos_dict[record[4]])

    def Append(self, o_name: str, o_surname: str, o_pharmacy_warhouse: PharmacyWarhouse, o_position: WorkerPosition):
        append_query = sql.SQL('INSERT INTO worker(name, surname, id_warhouse, id_position) '
                               'VALUES ({}, {}, {}, {}) RETURNING id;').format(
            sql.Literal(o_name),
            sql.Literal(o_surname),
            sql.Literal(o_pharmacy_warhouse.id),
            sql.Literal(o_position.id))
        w_id = self.Execute(query=append_query, mode='One')
        if not isinstance(w_id, tuple):
            return w_id

        return Worker(id=w_id[0], name=o_name, surname=o_surname, p_warhouse=o_pharmacy_warhouse, pos=o_position)

    def Delete(self, worker_object: Worker) -> int:
        delete_query = sql.SQL('DELETE FROM worker WHERE id = {};').format(
            sql.Literal(worker_object.id))
        return self.Execute(query=delete_query)

    def Update(self, worker_object: Worker) -> int:
        update_query = sql.SQL('UPDATE worker SET name = {}, surname = {}, id_warhouse = {}, id_position = {} '
                               'WHERE id = {};').format(
            sql.Literal(worker_object.name),
            sql.Literal(worker_object.surname),
            sql.Literal(worker_object.pharmacy_warhouse.id),
            sql.Literal(worker_object.position.id),
            sql.Literal(worker_object.id))
        return self.Execute(query=update_query)

