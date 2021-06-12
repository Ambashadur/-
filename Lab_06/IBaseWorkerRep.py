from Worker import Worker, PharmacyWarhouse, WorkerPosition
from DBConnection import DBConnection, sql, Error


class IBaseWorkerRep(DBConnection):

    def GetAll(self, p_warhouse_obj: PharmacyWarhouse, wor_pos_dict: dict) -> dict:
        try:
            self.start_connection()

            get_query = sql.SQL('SELECT * FROM worker WHERE id_warhouse = {} ORDER BY id;').format(
                sql.Literal(p_warhouse_obj.id))

            self.cursor.execute(get_query)
            records = self.cursor.fetchall()
            workers = dict()

            for record in records:
                workers[record[0]] = Worker(id=record[0], name=record[1], surname=record[2],
                                            p_warhouse=p_warhouse_obj, pos=wor_pos_dict[record[4]])

            if self.connection:
                self.finish_connection()
                return workers

        except (Exception, Error) as error:
            return error

    def GetById(self, id: int, pw_object: PharmacyWarhouse, wor_pos_dict: dict) -> Worker:
        try:
            self.start_connection()

            get_query = sql.SQL('SELECT * FROM worker WHERE id = {}').format(
                sql.Literal(id)
            )

            self.cursor.execute(get_query)
            record = self.cursor.fetchone()

            worker = Worker(id=record[0], name=record[1], surname=record[2],
                            p_warhouse=pw_object, pos=wor_pos_dict[record[4]])

            if self.connection:
                self.finish_connection()
                return worker

        except (Exception, Error) as error:
            return error

    def Append(self, o_name: str, o_surname: str, o_pharmacy_warhouse: PharmacyWarhouse, o_position: WorkerPosition):
        try:
            self.start_connection()

            append_query = sql.SQL('INSERT INTO worker(name, surname, id_warhouse, id_position) '
                                   'VALUES ({}, {}, {}, {}) RETURNING id;').format(
                sql.Literal(o_name),
                sql.Literal(o_surname),
                sql.Literal(o_pharmacy_warhouse.id),
                sql.Literal(o_position.id))

            self.cursor.execute(append_query)
            w_id = self.cursor.fetchone()
            self.connection.commit()

            new_worker = Worker(id=w_id[0], name=o_name,
                                surname=o_surname, p_warhouse=o_pharmacy_warhouse,
                                pos=o_position)

            if self.connection:
                self.finish_connection()
                return new_worker

        except (Exception, Error) as error:
            return error

    def Delete(self, worker_object: Worker) -> int:
        try:
            self.start_connection()

            delete_query = sql.SQL('DELETE FROM worker WHERE id = {};').format(
                sql.Literal(worker_object.id))

            self.cursor.execute(delete_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error

    def Update(self, worker_object: Worker) -> int:
        try:
            self.start_connection()

            update_query = sql.SQL('UPDATE worker SET name = {}, surname = {}, id_warhouse = {}, id_position = {} '
                                   'WHERE id = {};').format(
                sql.Literal(worker_object.name),
                sql.Literal(worker_object.surname),
                sql.Literal(worker_object.pharmacy_warhouse.id),
                sql.Literal(worker_object.position.id),
                sql.Literal(worker_object.id))

            self.cursor.execute(update_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error
