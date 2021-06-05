from IBasePharmacyWarhouseRep import IBasePharmacyWarhouseRep, PharmacyWarhouse
from IBaseWorkerPositionRep import IBaseWorkerPositionRep, WorkerPosition
from IBaseWorkerRep import IBaseWorkerRep, Worker

from prompt_toolkit import PromptSession
from prompt_toolkit.shortcuts import radiolist_dialog
from prompt_toolkit.shortcuts import  message_dialog


def main():
    session = PromptSession()

    pwbrep = IBasePharmacyWarhouseRep()
    wpbrep = IBaseWorkerPositionRep()
    wbrep = IBaseWorkerRep()

    print('Hello!')

    while True:
        try:
            res = PrintPWarhouses(pwbrep)

            if res == -1:
                break

        except KeyboardInterrupt:
            continue
        except EOFError:
            break
        else:
            print('You entered:')

    print('GoodBye!')


def PrintPWarhouses(pwrep:IBasePharmacyWarhouseRep):
    pw_print_list = list()
    pw_list = pwrep.GetAll()

    if not isinstance(pw_list, list):
        message_dialog(title='Error',
                       text=str(pw_list)).run()
        return -1

    for record in pw_list:
        pw_print_list.append(tuple(record.id, record.address))

    result = radiolist_dialog(title="Pharmacy Warehouses",
                              text='Which warehouse would you like to choose?',
                              values=pw_print_list).run()

    return result


if __name__ == '__main__':
    main()

