class MedicineEquipment:
    def __init__(self, price: float, name: str, number: int, id: int = 1):
        self.__price = price
        self.__name = name
        self.__number = number
        self.__id = id

    @property
    def id(self):
        return self.__id

    @property
    def price(self):
        return self.__price

    @price.setter
    def price(self, price):
        self.__price = price

    @property
    def name(self):
        return self.__name

    @name.setter
    def name(self, name):
        self.__name = name

    @property
    def number(self):
        return self.__number

    @number.setter
    def number(self, number):
        self.__number = number
