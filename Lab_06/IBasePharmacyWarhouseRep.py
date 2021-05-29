from PharmacyWarhouse import PharmacyWarhouse
import psycopg2
from psycopg2 import Error
from psycopg2 import sql

class IBasePharmacyWarhouseRep:

    def __init__(self):
        self.__connection_string = 'user=postgres password=INDIGORED host=127.0.0.1 port=5432 dbname=p_warhouse'
    
    def GetAll(self):
        try:
            connection = psycopg2.connect(self.__connection_string)
            cursor = connection.cursor()
            cursor.execute('SELECT * FROM pharmacy_warhouse;')
            records = cursor.fetchall()

            p_warhouses = list()

            for record in records:
                p_warhouses.append(PharmacyWarhouse(id = record[0], op_hours = record[1], adr = record[2]))

            if connection:
                cursor.close()
                connection.close()
                return p_warhouses

        except (Exception, Error) as error:
            return error

    def Append(self, p_warhouse_object):
        try:
            connection = psycopg2.connect(self.__connection_string)
            cursor = connection.cursor()

            append_query = sql.SQL('INSERT INTO pharmacy_warhouse(opening_hours, address) VALUES ({}, {});').format(
                sql.Literal(str(p_warhouse_object.opening_hours)),
                sql.Literal(str(p_warhouse_object.address)))
            
            cursor.execute(append_query)
            connection.commit()

            get_query = sql.SQL('SELECT * FROM pharmacy_warhouse WHERE opening_hours = {} AND address = {};').format(
                sql.Literal(p_warhouse_object.opening_hours),
                sql.Literal(p_warhouse_object.address))

            cursor.execute(get_query)

            record = cursor.fetchone()
            new_object = PharmacyWarhouse(id = record[0], op_hours = record[1], adr = record[2])

            if connection:
                cursor.close()
                connection.close()
                return new_object
                
        except (Exception, Error) as error:
            return error

    def Delete(self, p_warhouse_object):
        try:
            connection = psycopg2.connect(self.__connection_string)
            cursor = connection.cursor()

            delete_query = sql.SQL('DELETE FROM pharmacy_warhouse WHERE address = {} AND opening_hours = {};').format(
                sql.Literal(p_warhouse_object.address),
                sql.Literal(p_warhouse_object.opening_hours))

            cursor.execute(delete_query)
            connection.commit()

            if connection:
                cursor.close()
                connection.close()
                return 0
            
        except (Exception, Error) as error:
            return error

    def Update(self, p_warhouse_object):
        try:
            connection = psycopg2.connect(self.__connection_string)
            cursor = connection.cursor()

            update_query = sql.SQL('UPDATE pharmacy_warhouse SET address = {}, opening_hours = {} WHERE id = {};').format(
                sql.Literal(p_warhouse_object.address),
                sql.Literal(p_warhouse_object.opening_hours),
                sql.Literal(p_warhouse_object.id))

            cursor.execute(update_query)
            connection.commit()

            if connection:
                cursor.close()
                connection.close()
                return 0

        except (Exception, Error) as error:
            return error
            
