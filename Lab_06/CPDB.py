from IBasePharmacyWarhouseRep import IBasePharmacyWarhouseRep, PharmacyWarhouse
from IBaseWorkerPositionRep import IBaseWorkerPositionRep, WorkerPosition
from IBaseMedEquipRep import  IBaseMedEquipRep, MedicineEquipment
from IBaseWorkerRep import IBaseWorkerRep, Worker
from IBaseManufacturerFirm import IBaseManufacturerFirm
from IBaseMedicineForm import IBaseMedicineForm
from IBasePharmacologicalGroup import IBasePharmacologicalGroup
from IBaseStorageMethod import IBaseStorageMethod
from prompt_toolkit.shortcuts import radiolist_dialog, message_dialog, input_dialog


# Глобальные переменные для обращения к записям в базе данных
pw_repository = IBasePharmacyWarhouseRep()
wp_repository = IBaseWorkerPositionRep()
w_repository = IBaseWorkerRep()
me_repository = IBaseMedEquipRep()
medform_repository = IBaseMedicineForm()
manfirm_repository = IBaseManufacturerFirm()
pg_repository = IBasePharmacologicalGroup()
sm_repository = IBaseStorageMethod()


def main():
    try:
        res = -1
        while res is not None:
            res = StartApp()
            if res == 0:
                res = PrintObjects(empty_message_text='Нет ни одного аптечного склада',
                                   radio_title='Доступные аптечные склады',
                                   radio_text='Какой склад выбрать?',
                                   object_rep=pw_repository)

                if res is not None:
                    PrintPWCommands(res)

            elif res == 1:
                time = input_dialog(title='Добавление аптченого склада',
                                    text='Часы работы:',
                                    ok_text='Далее',
                                    cancel_text='Отменить').run()

                if time is None:
                    continue

                # Если неправельно введы часы работы => запрашивать ввод пока не станет правильно
                while time is not None and not CorrectTimeForPW(time):
                    time = input_dialog(title='Ошибка',
                                        text='Вы ввели неправельные часы работы\nФормат часов работы: чч:мм-чч:мм'
                                             '\nПовторите попытку',
                                        ok_text='Далее',
                                        cancel_text='Отменить').run()

                if time is None:
                    continue

                address = input_dialog(title='Добавление аптечного склада',
                                       text='Часы работы: ' + time + '\nАдрес',
                                       ok_text='Принять',
                                       cancel_text='Отменить').run()

                if address is None:
                    continue

                # Запрашивать ввод адреса пока не будет введён правильный
                while address is not None and len(address) < 8:
                    address = input_dialog(title='Ошибка',
                                           text='Вы ввели неправильный адрес\nПовторите попытку',
                                           ok_text='Принять',
                                           cancel_text='Отменить').run()

                if address is None:
                    continue

                new_object = pw_repository.Append(o_opening_hours=time, o_address=address)
                if not isinstance(new_object, PharmacyWarhouse):
                    message_dialog(title='Ошибка',
                                   text=str(new_object),
                                   ok_text='Понятно').run()
                    continue
    except EOFError:
        message_dialog(title='Ошибка',
                       text='Почему-то возникла ошибка',
                       ok_text='Понятно').run()

    message_dialog(title='Завершение программы',
                   text='До новых встреч!',
                   ok_text='Пока!').run()


def PrintObjects(empty_message_text: str, radio_title: str, radio_text: str, object_rep, add_args: list = None) -> int:
    object_print_list = list()

    if isinstance(object_rep, IBaseWorkerRep):
        object_dict = object_rep.GetAll(add_args[0], wp_repository.GetAll())
    elif isinstance(object_rep, IBaseMedEquipRep):
        object_dict = object_rep.GetAll(add_args[0].id)
    else:
        object_dict = object_rep.GetAll()

    if not isinstance(object_dict, dict):
        message_dialog(title='Ошибка',
                       text=str(object_dict),
                       ok_text='Понятно').run()
        return None
    elif len(object_dict) == 0:
        message_dialog(title='Упс',
                       text=empty_message_text,
                       ok_text='Понятно').run()
        return None

    if isinstance(object_rep, IBasePharmacyWarhouseRep):
        for key in object_dict:
            object_print_list.append(tuple((key, object_dict[key].address)))
    elif isinstance(object_rep, IBaseWorkerPositionRep):
        for key in object_dict:
            object_print_list.append(tuple((key, object_dict[key].position)))
    elif isinstance(object_rep, IBaseWorkerRep):
        for key in object_dict:
            object_print_list.append(tuple((key, object_dict[key].surname + '-' + object_dict[key].position.position)))
    elif isinstance(object_rep, IBaseMedEquipRep):
        for key in object_dict:
            object_print_list.append(tuple((key, object_dict[key].name)))

    result = radiolist_dialog(title=radio_title,
                              text=radio_text,
                              values=object_print_list,
                              ok_text='Выбрать',
                              cancel_text='Назад'
                              ).run()

    return result


# Начальный экран программы
def StartApp():
    res = radiolist_dialog(title='Начальный экран',
                           text='Добро пожаловать. Какое действие вы хотите выполнить?',
                           values=[
                               (0, 'Показать список аптечных складов'),
                               (1, 'Добавить аптечный склад')
                           ],
                           ok_text='Выполнить',
                           cancel_text='Завершить'
                           ).run()

    return res


def PrintPWCommands(id_pw_object):

    pw_object = pw_repository.GetById(id_pw_object)
    res = 1

    while res is not None:

        res = radiolist_dialog(title=pw_object.address,
                               text='Что сделать?',
                               values=[
                                   (0, 'Показать информацию об текущем складе'),
                                   (1, 'Изменить информацию об текущем складе'),
                                   (2, 'Показать список работников'),
                                   (3, 'Добавить работника'),
                                   (4, 'Показать список медицинского оборудования'),
                                   (5, 'Показать самое дорогое оборудование на этом складе'),
                                   (6, 'Добавить медицинское оборудование'),
                                   (7, 'Показать лекарства в карантине'),
                                   (8, 'Удалить текущий склад из списка'),
                               ],
                               ok_text='Выполнить',
                               cancel_text='Назад'
                               ).run()

        if res == 0:
            message_dialog(title='Информация об аптечном складе',
                           text='Адрес: ' + pw_object.address + '\nЧасы работы: ' + pw_object.opening_hours).run()
        elif res == 1:
            time = input_dialog(title='Изменение информации об аптечном складе',
                                text='Старые часы работы: ' + pw_object.opening_hours + '\nНовые часы работы:',
                                ok_text='Далее',
                                cancel_text='Отменить',
                                ).run()

            if time is None:
                continue

            # Если неправельно введы часы работы => запрашивать ввод пока не станет правильно
            while time is not None and not CorrectTimeForPW(time):
                time = input_dialog(title='Ошибка',
                                    text='Вы ввели неправельные часы работы\nФормат часов работы: чч:мм-чч:мм'
                                         '\nСтарые часы работы: ' + pw_object.opening_hours + '\nПовторите попытку',
                                    ok_text='Далее',
                                    cancel_text='Отменить').run()

            if time is None:
                continue

            address = input_dialog(title='Изменение информации об аптечном складе',
                                   text='Часы работы: ' + time + '\nСтарый адрес: ' + pw_object.address +
                                        '\nНовый адрес',
                                   ok_text='Принять',
                                   cancel_text='Отменить').run()

            if address is None:
                continue

            # Запрашивать ввод адреса пока не будет введён правильный
            while address is not None and len(address) < 8:
                address = input_dialog(title='Ошибка',
                                       text='Вы ввели неправильный адрес\nСтарый адрес: ' + pw_object.address +
                                            '\nПовторите попытку',
                                       ok_text='Принять',
                                       cancel_text='Отменить').run()

            if address is None:
                continue

            new_object = pw_repository.Update(PharmacyWarhouse(op_hours=time, adr=address, id=pw_object.id))
            if new_object != 0:
                message_dialog(title='Ошибка',
                               text=str(new_object),
                               ok_text='Понятно').run()
                continue

            pw_object.address = address
            pw_object.opening_hours = time
        elif res == 2:
            worker_result = 1
            while worker_result is not None:
                worker_result = PrintObjects(empty_message_text='В данном аптечном складе никто не работает',
                                             radio_title='Список работников',
                                             radio_text='Какого работника выбрать?',
                                             object_rep=w_repository,
                                             add_args=[
                                                 pw_object
                                             ])

                if worker_result is not None:
                    PrintWCommands(worker_result, pw_object)
        elif res == 3:
            new_name = input_dialog(title='Добавление работника',
                                    text='Имя:',
                                    ok_text='Далее',
                                    cancel_text='Отменить').run()

            if new_name is None:
                continue

            while new_name is not None and not new_name.isalpha():
                new_name = input_dialog(title='Ошибка',
                                        text='Вы ввели неправильное имя\nПовторите попытку',
                                        ok_text='Далее',
                                        cancel_text='Отменить').run()

            if new_name is None:
                continue

            new_surname = input_dialog(title='Добавление работника',
                                       text='Имя: ' + new_name + '\nФамилия:',
                                       ok_text='Далее',
                                       cancel_text='Отменить').run()

            if new_surname is None:
                continue

            while new_surname is not None and not new_surname.isalpha():
                new_surname = input_dialog(title='Ошибка',
                                           text='Вы ввели неправильную фамилию\nИмя: ' + new_name
                                                + '\nПовторите попытку',
                                           ok_text='Даллее',
                                           cancel_text='Отменить').run()

            if new_surname is None:
                continue

            new_wpos_id = PrintObjects(empty_message_text='Почему-то нет профессий',
                                       radio_title='Добавление работника',
                                       radio_text='Имя: ' + new_name + '\nФамилия: ' + new_surname + '\nПрофессия:',
                                       object_rep=wp_repository)

            if new_wpos_id is None:
                continue

            new_object = w_repository.Append(o_name=new_name, o_surname=new_surname,
                                             o_position=wp_repository.GetById(new_wpos_id),
                                             o_pharmacy_warhouse=pw_object)

            if not isinstance(new_object, Worker):
                message_dialog(title='Ошибка',
                               text=str(new_object),
                               ok_text='Понятно').run()
                continue
        elif res == 4:
            me_result = 1
            while me_result is not None:
                me_result = PrintObjects(empty_message_text='На складе не медицинского оборудования',
                                         radio_title='Список медицинского оборудования',
                                         radio_text='Какое медицинское оборудование выбрать?',
                                         object_rep=me_repository,
                                         add_args=[pw_object])
                if me_result is not None:
                    PrintMECommands(me_result, pw_object)
        elif res == 5:
            mequip = me_repository.MostExpMEquip(pw_object.id)
            if not isinstance(mequip, MedicineEquipment):
                message_dialog(title='Ошибка',
                               text=str(mequip),
                               ok_text='Понятно').run()
                continue

            message_dialog(title='Результат',
                           text='Название: ' + mequip.name + '\nЦена: ' + mequip.price,
                           ok_text='Понятно').run()
        elif res == 6:
            new_name = input_dialog(title='Добавление медицинского оборудования',
                                    text='Название:',
                                    ok_text='Далее',
                                    cancel_text='Отменить').run()

            if new_name is None:
                continue

            new_price = input_dialog(title='Добавление медицинского оборудования',
                                     text='Название: ' + new_name + '\nЦена:',
                                     ok_text='Далее',
                                     cancel_text='Отменить').run()

            if new_price is None:
                continue

            while new_price is not None and not new_price.isdigit():
                new_price = input_dialog(title='Ошибка',
                                         text='Вы ввели неправильную цену\nНазвание: ' + new_name
                                              + '\nЦена:',
                                         ok_text='Далее',
                                         cancel_text='Отменить').run()

            if new_price is None:
                continue

            new_number = input_dialog(title='Добавление медецинского оборудования',
                                      text='Название: ' + new_name + '\nЦена: ' + new_price
                                           + '\nКоличество:',
                                      ok_text='Принять',
                                      cancel_text='Отменить').run()

            if new_number is None:
                continue

            while new_number is not None and not new_number.isdigit():
                new_number = input_dialog(title='Ошибка',
                                          text='Вы ввели неправильное количество\nНазвание: ' + new_name
                                               + '\nЦена: ' + new_price + '\nКоличество:',
                                          ok_text='Принять',
                                          cancel_text='Отменить').run()

            if new_number is None:
                continue

            append_result = me_repository.Append(name=new_name,
                                                 price=float(new_price),
                                                 number=int(new_number),
                                                 id_pharmacy_warehouse=pw_object.id)

            if not isinstance(append_result, MedicineEquipment):
                message_dialog(title='Ошибка',
                               text=str(append_result),
                               ok_text='Понятно').run()
                continue

            message_dialog(title='Уведомление',
                           text='Запись успешно добавлена',
                           ok_text='Понятно').run()
        elif res == 7:
            meds = pw_repository.MedsInQuarantine(id_pharmacy_warehouse=pw_object.id,
                                                  mf_dict=medform_repository.GetAll(),
                                                  manf_dict=manfirm_repository.GetAll(),
                                                  sm_dict=sm_repository.GetAll(),
                                                  pg_dict=pg_repository.GetAll())
            if not isinstance(meds, dict):
                message_dialog(title='Ошибка',
                               text=str(meds),
                               ok_text='Понятно').run()
                continue
            elif len(meds) == 0:
                message_dialog(title='Упс',
                               text='Таких лекарств нет',
                               ok_text='Понятно').run()

            print_list = list()
            for key in meds:
                print_list.append(tuple((key, meds[key].name + ' - ' + str(meds[key].date_quarantine_zone))))

            radiolist_dialog(title='Список лекартсв в карантине',
                             values=print_list,
                             ok_text='Понятно',
                             cancel_text='Назад').run()

        elif res == 8:
            result_of_delete = pw_repository.Delete(pw_object)
            if result_of_delete != 0:
                message_dialog(title='Ошибка',
                               text=str(result_of_delete),
                               ok_text='Понятно').run()
                continue
            else:
                message_dialog(title='Удаление записи',
                               text='Запись успешно удалена',
                               ok_text='Понятно').run()
                break


def CorrectTimeForPW(time):
    if len(time) == 11 and time[2] == ':' and time[5] == '-' and time[8] == ':':
        correct_hours = 0 <= int(time[0:1]) <= 23 and 0 <= int(time[6:7]) <= 23
        correct_minutes = 0 <= int(time[3:4]) <= 59 and 0 <= int(time[9:10]) <= 59
        if correct_minutes and correct_hours and int(time[0:1]) < int(time[6:7]):
            return True

    return False


def PrintMECommands(id_medicine_equipment: int, pharmacy_warehouse: PharmacyWarhouse):
    current_me = me_repository.GetById(id_m_equip=id_medicine_equipment,
                                       id_pharmacy_warehouse=pharmacy_warehouse.id)

    res = 1

    while res is not None:
        res = radiolist_dialog(title=pharmacy_warehouse.address + ' : ' + current_me.name,
                               text='Что сделать?',
                               values=[
                                   (0, 'Показать информацию о текущем медицинском оборудовании'),
                                   (1, 'Изменить информацию о текущем медицинском оборудовании'),
                                   (2, 'Удалить текущее медицинское оборудование со склада')
                               ],
                               ok_text='Выполнить',
                               cancel_text='Назад').run()

        if res == 0:
            message_dialog(title='Информация о текущем медицинском оборудовании',
                           text='Название: ' + current_me.name + '\nЦена за одну штуку: ' + str(current_me.price)
                                + '\nХранится на складе: ' + pharmacy_warehouse.address + '\nВ количестве: '
                                + str(current_me.number) + ' штук',
                           ok_text='Понятно').run()
        elif res == 1:
            new_name = input_dialog(title='Изменение информации об медицинском оборудовании',
                                    text='Предыдущие название: ' + current_me.name + '\nНовое название:',
                                    ok_text='Далее',
                                    cancel_text='Отменить').run()

            if new_name is None:
                continue

            new_price = input_dialog(title='Изменение информации об медецинском оборудовании',
                                     text='Название: ' + new_name + '\nПредыдущая цена: ' + str(current_me.price)
                                          + '\nНовая цена:',
                                     ok_text='Далее',
                                     cancel_text='Отменить').run()

            if new_price is None:
                continue

            while new_price is not None and not new_price.isdigit():
                new_price = input_dialog(title='Ошибка',
                                         text='Вы ввели неправильную цену\nНазвание: ' + new_name
                                              + '\nПредыдущая цена: ' + str(current_me.price) + '\nНовая цена:',
                                         ok_text='Далее',
                                         cancel_text='Отменить').run()

            if new_price is None:
                continue

            new_number = input_dialog(title='Изменение информации об медецинском оборудовании',
                                      text='Название: ' + new_name + '\nЦена: ' + new_price
                                           + '\nПредыдущие количество: ' + str(current_me.number) + '\nНовое количество:',
                                      ok_text='Принять',
                                      cancel_text='Отменить').run()

            if new_number is None:
                continue

            while new_number is not None and not new_number.isdigit():
                new_number = input_dialog(title='Ошибка',
                                          text='Вы ввели неправильное количество\nНазвание: ' + new_name
                                               + '\nЦена: ' + new_price + '\nПредыдущие количество'
                                               + str(current_me.number) + '\nНовое количество:',
                                          ok_text='Принять',
                                          cancel_text='Отменить').run()

            if new_number is None:
                continue

            update_result = me_repository.Update(m_equip=MedicineEquipment(name=new_name,
                                                                           price=float(new_price),
                                                                           number=int(new_number)),
                                                 id_pharmacy_warhouse=pharmacy_warehouse.id)

            if update_result != 0:
                message_dialog(title='Ошибка',
                               text=str(update_result),
                               ok_text='Понятно').run()
                continue

            current_me.price = new_price
            current_me.name = new_name
            current_me.number = new_number

            message_dialog(title='Уведомление',
                           text='Запись успешно обнавлена',
                           ok_text='Понятно').run()
        elif res == 2:
            delete_result = me_repository.Delete(pharmacy_warehouse.id, current_me.id)
            if delete_result == 0:
                message_dialog(title='Уведомление',
                               text='Запись успешно удалена',
                               ok_text='Понятно').run()
                break
            else:
                message_dialog(title='Ошибка',
                               text=str(delete_result),
                               ok_text='Понятно').run()
                continue


def PrintWCommands(id_worker_object: int, f_pw_object: PharmacyWarhouse):
    current_worker = w_repository.GetById(id=id_worker_object,
                                          pw_object=f_pw_object,
                                          wor_pos_dict=wp_repository.GetAll())
    res = 1

    while res is not None:
        res = radiolist_dialog(title=current_worker.name + ' ' + current_worker.surname + ': '
                                     + current_worker.position.position,
                               text='Что сделать?',
                               values=[
                                   (0, 'Показать информацию о текущем работнике'),
                                   (1, 'Изменить информацию о текущем работнике'),
                                   (2, 'Удалить текущего работника из списка')
                               ],
                               ok_text='Выполнить',
                               cancel_text='Назад').run()

        if res == 0:
            message_dialog(title='Информация о текущем работнике',
                           text='Имя: ' + current_worker.name + '\nФамилия: ' + current_worker.surname + '\nДолжность: '
                                + current_worker.position.position + '\nМесто работы: '
                                + current_worker.pharmacy_warhouse.address,
                           ok_text='Понятно').run()

        elif res == 1:
            new_name = input_dialog(title='Изменение информации об работнике',
                                    text='Предыдущие имя: ' + current_worker.name + '\nНовое имя:',
                                    ok_text='Далее',
                                    cancel_text='Отменить').run()

            if new_name is None:
                continue

            while new_name is not None and not new_name.isalpha():
                new_name = input_dialog(title='Ошибка',
                                        text='Вы ввели неправильное имя\nПредыдущие имя: ' + current_worker.name
                                             + '\nПовторите попытку',
                                        ok_text='Далее',
                                        cancel_text='Отменить').run()

            if new_name is None:
                continue

            new_surname = input_dialog(title='Изменение информации об работнике',
                                       text='Имя: ' + new_name + '\nПредыдущая фамилия: ' + current_worker.surname
                                            + '\nНовая фамилия:',
                                       ok_text='Далее',
                                       cancel_text='Отменить').run()

            if new_surname is None:
                continue

            while new_surname is not None and not new_surname.isalpha():
                new_surname = input_dialog(title='Ошибка',
                                           text='Вы ввели неправильную фамилию\nИмя: ' + new_name
                                                + '\nПредыдущая фамилия: ' + current_worker.surname
                                                + '\nПовторите попытку',
                                           ok_text='Даллее',
                                           cancel_text='Отменить').run()

            if new_surname is None:
                continue

            new_id_pw = PrintObjects(empty_message_text='Нет ни одного аптечного склада',
                                     radio_title='Изменение информации об работнике',
                                     radio_text='Имя: ' + new_name + '\nФамилия: ' + new_surname
                                                + '\nПредыдущий аптечный склад: '
                                                + current_worker.pharmacy_warhouse.address + '\nНовый адрес:',
                                     object_rep=pw_repository)

            if new_id_pw is None:
                continue

            new_wpos_id = PrintObjects(empty_message_text='Почему-то не профессий',
                                       radio_title='Изменение информации об работнике',
                                       radio_text='Имя: ' + new_name + '\nФамилия: ' + new_surname
                                                  + '\nАдрес работы: ' + pw_repository.GetById(new_id_pw).address
                                                  + '\nСтарая проффесия: ' + current_worker.position.position
                                                  + '\nНовая профессия:',
                                       object_rep=wp_repository)

            if new_wpos_id is None:
                continue

            new_object = w_repository.Update(Worker(id=current_worker.id, name=new_name, surname=new_surname,
                                                    pos=wp_repository.GetById(new_wpos_id),
                                                    p_warhouse=pw_repository.GetById(new_id_pw)))

            if new_object != 0:
                message_dialog(title='Ошибка',
                               text=str(new_object),
                               ok_text='Понятно').run()
                continue

            current_worker.name = new_name
            current_worker.surname = new_surname
            current_worker.position = wp_repository.GetById(new_wpos_id)
            current_worker.pharmacy_warhouse = pw_repository.GetById(new_id_pw)
        elif res == 2:
            result_of_delete = w_repository.Delete(current_worker)
            if result_of_delete != 0:
                message_dialog(title='Ошибка',
                               text=str(result_of_delete),
                               ok_text='Понятно').run()
                continue
            else:
                message_dialog(title='Удаление записи',
                               text='Запись успешно удалена',
                               ok_text='Понятно').run()
                break


if __name__ == '__main__':
    main()

