from model.dml_models import get_result_by_date
import config as cfg
import xlsxwriter
import datetime
import os.path
from flask import redirect
#import win32api
#import win32print
from datetime import date, timedelta


def print_result_by_date(dat):
    file_name = 'list_result_' + dat + '.xlsx'
    file_path = cfg.REPORTS_PATH + file_name
    # Для тестирования через __main__ раскомментарить
    # file_path = file_name

    if cfg.debug_level > 2:
        print('++++ print_date_report: ' + dat + ', file_name: ' + file_name)
    if os.path.isfile(file_path):
        os.remove(file_path)
        # return file_name

    workbook = xlsxwriter.Workbook(file_path)
    worksheet = workbook.add_worksheet()
    worksheet.set_column(0, 0, 1)
    worksheet.set_column(1, 1, 5)
    worksheet.set_column(2, 2, 32)
    worksheet.set_column(3, 3, 32)
    worksheet.set_column(4, 4, 18)
    worksheet.set_column(5, 5, 18)
    worksheet.set_column(6, 6, 12)

    worksheet.set_row(0, 32)
    worksheet.set_row(1, 20)

    cursor = get_result_by_date(dat)

    title1_cell_format = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'size': 18})
    worksheet.merge_range('B1:G1', "", title1_cell_format)

    title2_cell_format = workbook.add_format(
        {'align': 'left', 'valign': 'vcenter', 'size': 12, 'underline': True})
    worksheet.merge_range('B2:C2', "", title2_cell_format)

    header_table_format = workbook.add_format({'align': 'center', 'bold': True, 'valign': 'vcenter', 'border': 1})
    header_table_format.set_text_wrap()

    value_table_format = workbook.add_format({'align': 'center', 'valign': 'vcenter', 'border': 1})
    value_left_table_format = workbook.add_format({'align': 'left', 'valign': 'vcenter', 'border': 1, 'text_wrap': True})
    value_left_table_format.set_text_wrap()

    worksheet.write('B1', 'РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ', title1_cell_format)
    worksheet.write('B2', 'За: ' + dat, title2_cell_format)
    worksheet.write('B4', '№', header_table_format)
    worksheet.write('C4', 'ФИО', header_table_format)
    worksheet.write('D4', 'Департамент/Филиал', header_table_format)
    worksheet.write('E4', 'Начало тестирования', header_table_format)
    worksheet.write('F4', 'Конец тестирования', header_table_format)
    worksheet.write('G4', 'Кол-во правильных ответов', header_table_format)
    row = 1
    for record in cursor:
        worksheet.write(row + 3, 1, row, value_table_format)
        worksheet.write(row + 3, 2, record.fio, value_left_table_format)
        worksheet.write(row + 3, 3, record.depart, value_left_table_format)
        worksheet.write(row + 3, 4, record.beg_time, value_table_format)
        worksheet.write(row + 3, 5, record.end_time, value_table_format)
        worksheet.write(row + 3, 6, record.true_score, value_table_format)
        row += 1

    worksheet.write(row + 3 + 1, 1, datetime.datetime.now().strftime("%d-%m-%Y %H:%M:%S"))
    workbook.close()

    if cfg.print_at_once > 2:
        print("Завершен расчет: " + datetime.datetime.now().strftime("%d-%m-%Y %H:%M:%S"))
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


if __name__ == "__main__":
    now = '16.08.2021'
    print("Тестируем списочный отчет по результатам тестирования за: " + now)
    print_result_by_date(now)
