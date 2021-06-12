class StorageMethod:
    def __init__(self, name: str, id: int = 1):
        self.__name = name
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
