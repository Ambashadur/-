class WorkerPosition:

    def __init__(self, pos:str, id:int=1):
        self.__id = id
        self.__position = pos

    @property
    def id(self):
        return self.__id

    @property
    def position(self):
        return self.__position

    @position.setter
    def position(self, pos):
        self.__position = pos
