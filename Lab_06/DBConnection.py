import psycopg2
from psycopg2 import Error
from psycopg2 import sql


class DBConnection:
    def __init__(self):
        self.__connection_string = 'user=postgres password=INDIGORED host=192.168.1.50 port=5432 dbname=p_warhouse'

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
