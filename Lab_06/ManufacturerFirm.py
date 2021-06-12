class ManufacturerFirm:
    def __init__(self, name: str, address: str, id: int = 1):
        self.__name = name
        self.__address = address
        self.__id = id

    @property
    def id(self):
        return self.__id

    @property
    def name(self):
        return self.__name

    @name.setter
    def name(self, name: str):
        self.__name = name

    @property
    def address(self):
        return self.__address

    @address.setter
    def address(self, address: str):
        self.__address = address