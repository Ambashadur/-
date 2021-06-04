class PharmacyWarhouse:

    def __init__(self, op_hours:str, adr:str, id:int = 1):
        self.__opening_hours = op_hours
        self.__address = adr
        self.__id = id

    @property
    def id(self):
        return self.__id

    @property
    def opening_hours(self):
        return self.__opening_hours

    @opening_hours.setter
    def opening_hours(self, op_hours):
        self.__opening_hours = op_hours

    @property
    def address(self):
        return self.__address

    @address.setter
    def address(self, adr):
        self.__address = adr
