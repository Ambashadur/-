from Worker import Worker
from DBConnection import DBConnection, sql, Error


class IBaseWorkerRep(DBConnection):

    def GetAll(self, p_warhouse_obj, wor_pos_list):
        try:
            self.start_connection()

            get_query = sql.SQL('SELECT * FROM worker WHERE id_warhouse = {};').format(
                sql.Literal(p_warhouse_obj.id))

            self.cursor.execute(get_query)
            records = self.cursor.fetchall()
            workers = list()

            for record in records:
                workers.append(Worker(id=record[0], name=record[1], surname=record[2],
                                      p_warhouse=p_warhouse_obj, pos=wor_pos_list[record[4]]))

            if self.connection:
                self.finish_connection()
                return workers

        except (Exception, Error) as error:
            return error

    def Append(self, o_name, o_surname, o_pharmacy_warhouse, o_position):
        try:
            self.start_connection()

            append_query = sql.SQL('INSERT INTO worker(name, surname, id_warhouse, id_position) '
                                   'VALUES ({}, {}, {}, {});').format(
                sql.Literal(o_name),
                sql.Literal(o_surname),
                sql.Literal(o_pharmacy_warhouse.id),
                sql.Literal(o_position.id))

            self.cursor.execute(append_query)
            self.connection.commit()

            new_worker = Worker(id=self.cursor.lastrowid, name=o_name,
                                surname=o_surname, p_warhouse=o_pharmacy_warhouse,
                                pos=o_position)

            if self.connection:
                self.finish_connection()
                return new_worker

        except (Exception, Error) as error:
            return error

    def Delete(self, worker_object):
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

    def Update(self, worker_object):
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
