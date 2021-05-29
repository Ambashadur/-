from WorkerPosition import WorkerPosition
from DBConnection import DBConnection

class IBaseWorkerPositionRep(DBConnection):

    def GetAll(self):
        try:
            self.start_connection()
            self.cursor.execute('SELECT * FROM worker_position')
            records = self.cursor.fetchall()

            worker_position = list()

            for record in records:
                worker_position.append(WorkerPosition(id = record[0], pos = record[1]))

            if self.connection:
                self.finish_connection()
                return worker_position

        except (Exception, Error) as error:
            return error

    def Append(self, work_pos_object):
        try:
            self.start_connection()

            append_query = sql.SQL('INSERT INTO worker_position(position) VALUES ({});').format(
                sql.Literal(work_pos_object.position))

            self.cursor.execute(append_query)
            self.connection.commit()

            get_query = sql.SQL('SELECT * FROM worker_position WHERE position = {};').format(
                sql.Literal(work_pos_object.position))

            self.cursor.execute(get_query)

            recod = self.cursor.fetchone()
            new_object = WorkerPosition(id = record[0], pos = record[1])

            if self.connection:
                self.finish_connection()
                return new_object

        except (Exception, Error) as error:
            return error

    def Delete(self, work_pos_object):
        try:
            self.start_connection()

            

    
