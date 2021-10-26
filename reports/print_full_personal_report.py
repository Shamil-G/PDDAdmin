from model.dml_models import get_full_result, get_result_info, get_id_reg_by_iin
import config as cfg
import xlsxwriter
import datetime
import os.path
from flask import redirect
#import win32api
#import win32print
from datetime import date, timedelta

module_result_path = ''


def print_full_result_test(id_registration):
    print('++++ print_result_test: ' + str(id_registration))
    now = datetime.datetime.now()
    # today = datetime.date.today()
    id_reg, iin, time_beg, time_end, fio = get_result_info(id_registration)

    if iin is None:
        return ''

    file_name = 'result_full_' + str(id_reg) + '.xlsx'
    if not module_result_path:
        file_path = cfg.REPORTS_PATH + file_name
    else:
        file_path = module_result_path + file_name

    if os.path.isfile(file_path):
        return file_name

    workbook = xlsxwriter.Workbook(file_path)
    worksheet = workbook.add_worksheet()
    worksheet.set_column(0, 0, 1)
    worksheet.set_column(1, 1, 5)
    worksheet.set_column(2, 2, 32)
    # worksheet.set_column(3, 3, 8)
    worksheet.set_column(4, 3, 64)
    worksheet.set_column(5, 4, 8)
    worksheet.set_column(6, 5, 64)

    cursor = get_full_result(id_registration)

    # print("Провели расчет и формируем Excel: " + datetime.datetime.now().strftime("%d-%m-%Y %H:%M:%S"))

    title1_cell_format = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'size': 18})
    worksheet.merge_range('B1:F1', "", title1_cell_format)
    worksheet.set_row(0, 32)
    worksheet.set_row(1, 24)
    worksheet.set_row(2, 16)

    title2_cell_format = workbook.add_format({'align': 'left', 'bold': True, 'valign': 'vcenter', 'size': 14, 'underline': True})
    title3_cell_format = workbook.add_format({'align': 'left', 'bold': True, 'valign': 'vcenter', 'size': 12})
    title3_1_cell_format = workbook.add_format({'align': 'left', 'valign': 'vcenter', 'size': 12})
    theme_name_format = workbook.add_format({'align': 'left', 'valign': 'vcenter', 'border': 1, 'text_wrap': True})

    worksheet.merge_range('B2:F2', "", title2_cell_format)
    worksheet.merge_range('B5:C5', "", title3_cell_format)
    worksheet.merge_range('B6:C6', "", title3_cell_format)

    common_format = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'border': 1})
    common_format.set_text_wrap()
    common_format_2 = workbook.add_format({'align': 'center', 'bold': True, 'border': 1})
    common_format_2.set_align('vcenter')
    common_format_2.set_text_wrap()
    sum_pay_format = workbook.add_format({'num_format': '#,###,##0.00', 'font_color': 'black', 'align': 'vcenter'})
    #date_format = workbook.add_format({'num_format':'dd/mm/yy', 'align': 'vcenter'})

    worksheet.write('B1', 'РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ', title1_cell_format)
    worksheet.write('B2', fio, title2_cell_format)
    worksheet.write('B3', 'Ид:', title3_cell_format)
    worksheet.write('C3', id_reg, title3_1_cell_format)
    worksheet.write('B4', 'ИИН:', title3_cell_format)
    worksheet.write('C4', iin, title3_1_cell_format)

    ft_beg = time_beg.strftime('%d.%m.%Y  %H:%M:%S')
    ft_end = time_end.strftime('%d.%m.%Y  %H:%M:%S')

    worksheet.write('B5', 'Начало тестирования:', title3_cell_format)
    worksheet.write('D5', ft_beg, title3_1_cell_format)
    worksheet.write('B6', 'Окончание тестирования:', title3_cell_format)
    worksheet.write('D6', ft_end, title3_1_cell_format)

    worksheet.write('B8', '№', common_format_2)
    worksheet.write('C8', 'НПА', common_format_2)
    # worksheet.write('D8', '№ вопроса', common_format_2)
    worksheet.write('D8', 'Вопрос', common_format_2)
    worksheet.write('E8', 'Ответ верен', common_format_2)
    worksheet.write('F8', 'Ответ', common_format_2)
    row = 0
    for record in cursor:
        if not record.theme_name:
            break
        worksheet.write(row + 8, 1, row + 1, common_format)
        worksheet.write(row + 8, 2, record.theme_name, theme_name_format)
        # worksheet.write(row + 8, 3, record.order_num_question, common_format)
        worksheet.write(row + 8, 3, record.question,  theme_name_format)
        if record.correctly == 'Y':
            worksheet.write(row + 8, 4, 'Да', common_format)
        else:
            worksheet.write(row + 8, 4, 'Нет', common_format)
        worksheet.write(row + 8, 5, record.answer, theme_name_format)
        row += 1

    worksheet.write(row + 8 + 1, 1, now.strftime("%d.%m.%Y %H:%M:%S"))
    workbook.close()

    # print("Завершен расчет: " + datetime.datetime.now().strftime("%d-%m-%Y %H:%M:%S"))
    if cfg.print_at_once:
       None
#        my_printer = win32print.GetDefaultPrinter()
#        win32api.ShellExecute(
#            0,
#            "print",
#            file_name,
#            my_printer,
#            ".",
#            0
#        )
    return file_name


def print_full_result_test_by_iin(iin):
    id_reg = get_id_reg_by_iin(iin)
    if cfg.debug_level > 2:
        print('print_result_test_by_iin: ' + iin)
    return print_full_result_test(id_reg)


if __name__ == "__main__":
    module_result_path = './'
    my_iin = '777'
    print('Testing app Print Full Result for: ' + my_iin)
    print_full_result_test_by_iin(my_iin)
