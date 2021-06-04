from PharmacyWarhouse import PharmacyWarhouse
from WorkerPosition import WorkerPosition

class Worker:

    def __init__(self, name:str, surname:str, pos:WorkerPosition, p_warhouse:PharmacyWarhouse, id:int=1):
        self.__id = id
        self.__name = name
        self.__surname = surname
        self.__position = pos
        self.__pharmacy_warhouse = p_warhouse

    @property
    def id(self):
        return self.__id

    @property
    def name(self):
        return self.__name

    @name.setter
    def name(self, name):
        self.__name = name

    @property
    def surname(self):
        return self.__surname

    @surname.setter
    def surname(self, surname):
        self.__surname = surname

    @property
    def position(self):
        return self.__position

    @position.setter
    def position(self, pos):
        self.__position = pos

    @property
    def pharmacy_warhouse(self):
        return self.__pharmacy_warhouse

    @pharmacy_warhouse.setter
    def pharmacy_warhouse(self, p_warhouse):
        self.__pharmacy_warhouse = p_warhouse
