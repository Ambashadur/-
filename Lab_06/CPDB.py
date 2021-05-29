from IBasePharmacyWarhouseRep import IBasePharmacyWarhouseRep
from PharmacyWarhouse import PharmacyWarhouse

test = IBasePharmacyWarhouseRep()
#print(test.GetAll())

test2 = PharmacyWarhouse(op_hours = input('time '), adr = input('adr '))

print(test.Append(test2))
#if isinstance(ret, PharmacyWarhouse):
    #test2 = ret
    #print(test2)

#print(ret.id)

#test2.address = input('new adr')
#print(test2.id)
#print(test.Update(test2))

#print(test.Delete(test2))
