from Worker import Worker
from DBConnection import DBConnection
from DBConnection import Error
from DBConnection import sql

class IBaseWorkerRep:

    def GetAll(self, p_warhouse, wor_pos):
        try:
            self.start_connection()
            self.cursor.execute('SELECT * FROM worker;')
            records = self.cursor.fetchall()

            workers = list()

            for record in records:
                
