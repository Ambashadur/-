from WorkerPosition import WorkerPosition
from DBConnection import DBConnection, sql, Error

class IBaseWorkerPositionRep(DBConnection):

    def GetAll(self):
        try:
            self.start_connection()
            self.cursor.execute('SELECT * FROM worker_position')
            records = self.cursor.fetchall()

            worker_position = list()

            for record in records:
                worker_position.append(WorkerPosition(id=record[0], pos=record[1]))

            if self.connection:
                self.finish_connection()
                return worker_position

        except (Exception, Error) as error:
            return error

    def Append(self, o_position):
        try:
            self.start_connection()

            append_query = sql.SQL('INSERT INTO worker_position(position) VALUES ({});').format(
                sql.Literal(o_position))

            self.cursor.execute(append_query)
            self.connection.commit()

            new_worker_position = WorkerPosition(id=self.cursor.lastrowid, pos=o_position)

            if self.connection:
                self.finish_connection()
                return new_worker_position

        except (Exception, Error) as error:
            return error

    def Delete(self, work_pos_object):
        try:
            self.start_connection()

            delete_query = sql.SQL('DELETE FROM worker_position WHERE id = {};').format(
                sql.Literal(work_pos_object.id))

            self.cursor.execute(delete_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error

    def Update(self, work_pos_object):
        try:
            self.start_connection()

            update_query = sql.SQL('UPDATE worker_position SET position = {} WHERE id = {};').format(
                sql.Literal(work_pos_object.position),
                sql.Literal(work_pos_object.id))

            self.cursor.execute(update_query)
            self.connection.commit()

            if self.connection:
                self.finish_connection()
                return 0

        except (Exception, Error) as error:
            return error
