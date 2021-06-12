from Medicine import Medicine, MedicineForm, StorageMethod, PharmacologicalGroup, ManufacturerFirm
from PharmacyWarhouse import PharmacyWarhouse
from DBConnection import DBConnection, sql, Error


class IBaseMedicine(DBConnection):
    def GetAll(self, pharmacy_warehouse: PharmacyWarhouse, medicine_form: dict,
               storage_method: dict, pharmacological_group: dict, manufacturer_firm: dict) -> dict:
        try:
            self.start_connection()
            get_query = sql.SQL('')