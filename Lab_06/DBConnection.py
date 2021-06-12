import psycopg2
from psycopg2 import Error
from psycopg2 import sql


class DBConnection:
    def __init__(self):
        self.__connection_string = 'user=postgres password=INDIGORED host=192.168.1.50 port=5432 dbname=p_warhouse'

    def Execute(self, query, mode: str = ''):
        try:
            connection = psycopg2.connect(self.__connection_string)
            cursor = connection.cursor()
            cursor.execute(query)

            if mode == 'All':
                result = cursor.fetchall()
            elif mode == 'One':
                result = cursor.fetchone()
            else:
                result = 0

            connection.commit()

            if connection:
                cursor.close()
                connection.close()
                return result

        except (Exception, Error) as error:
            return error

    @property
    def cursor(self):
        return self.__cursor

    @property
    def connection(self):
        return self.__connection
    
    def start_connection(self):
        self.__connection = psycopg2.connect(self.__connection_string)
        self.__cursor = self.__connection.cursor()

    def finish_connection(self):
        self.__connection.close()
        self.__cursor.close()
