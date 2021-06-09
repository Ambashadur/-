from IBasePharmacyWarhouseRep import IBasePharmacyWarhouseRep, PharmacyWarhouse
from IBaseWorkerPositionRep import IBaseWorkerPositionRep, WorkerPosition
from IBaseWorkerRep import IBaseWorkerRep, Worker
from prompt_toolkit import PromptSession
from prompt_toolkit.shortcuts import radiolist_dialog
from prompt_toolkit.shortcuts import message_dialog
from prompt_toolkit.shortcuts import input_dialog

# Глобальные переменные для обращения к записям в базе данных
pw_repository = IBasePharmacyWarhouseRep()
wp_repository = IBaseWorkerPositionRep()
w_repository = IBaseWorkerRep()


def main():
    session = PromptSession()

    try:
        res = -1
        while res is not None:
            res = StartApp()

            if res == 0:
                res = PrintPWarhouses()

                if res is not None:
                    PrintPWCommands(res)
            elif res == 1:
                time = input_dialog(title='Изменение информации об аптечном складе',
                                    text='Часы работы:',
                                    ok_text='Далее',
                                    cancel_text='Отменить',
                                    ).run()

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

                address = input_dialog(title='Изменение информации об аптечном складе',
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
                if  not isinstance(new_object, PharmacyWarhouse):
                    message_dialog(title='Ошибка',
                                   text=str(new_object),
                                   ok_text='Понятно').run()
                    continue
    except EOFError:
        print('Error')

    message_dialog(title='Завершение программы',
                   text='До новых встреч!',
                   ok_text='Пока!').run()


# Вывод всех аптечных складов
def PrintPWarhouses() -> int:

    # Список кортежей для вывода в консоль
    pw_print_list = list()

    # Список обьектов PharmacyWarhouse, полученных из базы данных
    pw_dict = pw_repository.GetAll()

    if not isinstance(pw_dict, dict):
        message_dialog(title='Ошибка',
                       text=str(pw_dict),
                       ok_text='Понятно').run()
        return None

    if len(pw_dict) == 0:
        message_dialog(title='Упс',
                       text='Нет ни одного аптечного склада',
                       ok_text='Понятно').run()
        return None

    for key in pw_dict:
        pw_print_list.append(tuple((key, pw_dict[key].address)))

    result = radiolist_dialog(title='Доступные аптечные склады',
                              text='Какой склад выбрать?',
                              values=pw_print_list,
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
                                   (4, 'Удалить текущий склад из списка'),
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
                worker_result = PrintWorkers(pw_object)

                if worker_result is not None:
                    PrintWCommands(worker_result, pw_object)
        elif res == 3:
            new_name = input_dialog(title='Изменение информации об работнике',
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

            new_surname = input_dialog(title='Изменение информации об работнике',
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

            new_wpos_id = PrintWPositions()

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


def PrintWorkers(pw_object: PharmacyWarhouse):

    # Список кортежей для вывода
    w_print_list = list()

    # Список работников
    w_dict = w_repository.GetAll(pw_object, wp_repository.GetAll())

    if not isinstance(w_dict, dict):
        message_dialog(title='Ошибка',
                       text=str(w_dict),
                       ok_text='Понятно').run()

        return None

    if len(w_dict) == 0:
        message_dialog(title='Упс',
                       text='В данном аптечном складе никто не работает',
                       ok_text='Понятно').run()
        return None

    for key in w_dict:
        w_print_list.append(tuple((key, w_dict[key].surname + '-' + w_dict[key].position.position)))

    result = radiolist_dialog(title='Список работников',
                              text='Какого работника выбрать?',
                              values=w_print_list,
                              ok_text='Выбрать',
                              cancel_text='Назад').run()

    return result


def PrintWPositions() -> int:
    wp_print_list = list()

    wp_dict = wp_repository.GetAll()

    if not isinstance(wp_dict, dict):
        message_dialog(title='Ошибка',
                       text=str(wp_dict),
                       ok_text='Понятно').run()
        return None

    for key in wp_dict:
        wp_print_list.append(tuple((key, wp_dict[key].position)))

    result = radiolist_dialog(title='Список профессий',
                              text='Какую проффесию выбрать',
                              values=wp_print_list,
                              ok_text='Выбрать',
                              cancel_text='Назад').run()

    return result


def PrintWCommands(id_worker_object: int, f_pw_object: PharmacyWarhouse):
    current_worker = w_repository.GetById(id=id_worker_object, pw_object=f_pw_object, wor_pos_dict=wp_repository.GetAll())
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
                                            + 'Новая фамилия:',
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

            new_id_pw = PrintPWarhouses()

            if new_id_pw is None:
                continue

            new_wpos_id = PrintWPositions()

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

