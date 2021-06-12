from MedicineForm import MedicineForm
from ManufacturerFirm import ManufacturerFirm
from PharmacologicalGroup import PharmacologicalGroup
from StorageMethod import StorageMethod
from datetime import date

class Medicine:
    def __init__(self, price: float, name: str, expiration_date: date, series: str, gross_weight: int,
                 medicine_form: MedicineForm, manufacturer_firm: ManufacturerFirm, storage_method: StorageMethod,
                 pharmacological_group: PharmacologicalGroup, id: int = 1, date_quarantine_zone: date = None,
                 return_distruction_date: date = None):
        self.price = price
        self.name = name
        self.expiration_date = expiration_date
        self.series = series
        self.date_quarantine_zone = date_quarantine_zone
        self.return_distruction_date = return_distruction_date
        self.gross_weight = gross_weight
        self.medicine_form = medicine_form
        self.manufacturer_firm = manufacturer_firm
        self.storage_method = storage_method
        self.pharmacological_group = pharmacological_group
        self.__id = id

    @property
    def id(self):
        return self.__id
