from db_oracle.connect import get_connection
from model.models import TaskF, ThemesF, ResultF, ResultFullF, ResultList
from flask import redirect, url_for, request, g
import config as cfg
import cx_Oracle


def programs():
    if cfg.debug_level > 3:
        print('Programs List ...')
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_task, coalesce(period_for_testing,0) period_for_testing, name_task from tasks order by 1 desc'
    cursor.execute(cmd)
    cursor.rowfactory = TaskF
    if cfg.debug_level > 3:
        print('List programs have got...')
    return cursor


def program(id_task):
    if cfg.debug_level > 3:
        print('Programs List ...')
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_task, coalesce(period_for_testing,0) period_for_testing, name_task ' \
          'from tasks t ' \
          'where t.id_task=:id ' \
          'order by 1 desc'
    cursor.execute(cmd, [id_task])
    cursor.rowfactory = TaskF
    if cfg.debug_level > 3:
        print('List programs have got...')
    return cursor


def program_upd(id_task, period_for_testing, name_task):
    if cfg.debug_level > 0:
        print("1.+++ History Create " + name_task + " : ")
    try:
        con = get_connection()
        cursor = con.cursor()
        cursor.callproc('admin.program_upd', [id_task, period_for_testing, name_task])
        cursor.close()
        con.close()
        if cfg.debug_level > 0:
            print("2. Успешное завершение добавления программы!")
    except cx_Oracle.IntegrityError as e:
        errorObj, = e.args
        print("Error Code:", errorObj.code)
        print("Error Message:", errorObj.message)
        print("При добавлении программы произошла ошибка")
        return


def program_add(period_for_testing, name_task):
    if cfg.debug_level > 0:
        print("1.+++ History Create " + name_task + " : " + period_for_testing)
    try:
        con = get_connection()
        cursor = con.cursor()
        cursor.callproc('admin.program_add', [period_for_testing, name_task])
        cursor.close()
        con.close()
        if cfg.debug_level > 0:
            print("2. Успешное завершение добавления программы!")
    except cx_Oracle.IntegrityError as e:
        errorObj, = e.args
        print("Error Code:", errorObj.code)
        print("Error Message:", errorObj.message)
        print("При добавлении программы произошла ошибка")
        return


def get_name_program(id_task):
    if cfg.debug_level > 3:
        print("Get Name Program " + str(id_task))
    try:
        con = get_connection()
        cursor = con.cursor()
        mess = cursor.callfunc('admin.get_name_program', str, [id_task])
        cursor.close()
        con.close()
        if cfg.debug_level > 3:
            print("2. Успешное завершение добавления программы!")
        return mess
    except cx_Oracle.IntegrityError as e:
        errorObj, = e.args
        print("Error Code:", errorObj.code)
        print("Error Message:", errorObj.message)
        print("При добавлении программы произошла ошибка")
        return


def program_delete(id_task):
    if cfg.debug_level > 2:
        print("program_delete. id_task " + str(id_task))
    try:
        con = get_connection()
        cursor = con.cursor()
        cursor.callproc('admin.program_delete', [id_task])
        cursor.close()
        con.close()
        return
    except cx_Oracle.IntegrityError as e:
        errorObj, = e.args
        print("Error Code:", errorObj.code)
        print("Error Message:", errorObj.message)
        print("Произошла ошибка при удалении Программы: " + str(id_task))
        return


def themes(id_task):
    if cfg.debug_level > 2:
        print('History Detail id_hist: '+str(id_task))
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select bt.id_task, bt.id_theme, bt.theme_number, bt.count_question, bt.count_success, ' \
          't.descr as theme_name ' \
          'from bundle_themes bt, themes t ' \
          'where bt.id_task=:id ' \
          'and   bt.id_theme=t.id_theme'
    # print('CMD: '+cmd)
    cursor.execute(cmd, [id_task])
    cursor.rowfactory = ThemesF
    if cfg.debug_level > 3:
        print('History list have got...')
    return cursor


def theme(id_task, id_theme):
    if cfg.debug_level > 2:
        print('Theme id_theme: '+str(id_theme))
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select bt.id_task, bt.id_theme, bt.theme_number, bt.count_question, bt.count_success,  t.descr as theme_name ' \
          'from bundle_themes bt, themes t ' \
          'where bt.id_task=:id1 ' \
          'and   bt.id_theme=:id2 ' \
          'and   bt.id_theme=t.id_theme'
    # print('CMD: '+cmd)
    cursor.execute(cmd, [id_task, id_theme])
    cursor.rowfactory = ThemesF
    if cfg.debug_level > 3:
        print('History list have got...')
    return cursor


def theme_update(id_task, id_theme, theme_name, theme_number, count_question, count_success):
    if cfg.debug_level > 2:
        print('Theme update. id_task: ' + str(id_task) + ', id_theme' + str(id_theme))
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc("admin.theme_update", [id_task, id_theme, theme_name, theme_number, count_question, count_success])
    cursor.close()
    con.close()


def theme_delete(id_theme):
    if cfg.debug_level > 2:
        print('Theme delete. id_theme' + str(id_theme))
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc("admin.theme_delete", [id_theme])
    cursor.close()
    con.close()


def get_result_info():
    if cfg.debug_level > 1:
        print('Get Result Info: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    id_reg = cursor.var(cx_Oracle.DB_TYPE_NUMBER)
    iin = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
    time_beg = cursor.var(cx_Oracle.DB_TYPE_DATE)
    time_end = cursor.var(cx_Oracle.DB_TYPE_DATE)
    fio = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
    cursor.callproc('test.get_personal_info', (g.user.id_user, id_reg, iin, time_beg, time_end, fio))
    print('Got result info ' + fio.getvalue())
    return id_reg.getvalue(), iin.getvalue(), time_beg.getvalue(), time_end.getvalue(), fio.getvalue()


def get_result_info(id_reg):
    if cfg.debug_level > 1:
        print('Get Result Info: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    iin = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
    time_beg = cursor.var(cx_Oracle.DB_TYPE_DATE)
    time_end = cursor.var(cx_Oracle.DB_TYPE_DATE)
    fio = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
    cursor.callproc('test.get_personal_info', (id_reg, iin, time_beg, time_end, fio))
    if cfg.debug_level > 1 and iin.getvalue() != '':
        print('Got result info ' + str(iin.getvalue()))
    if iin != '':
        return id_reg, iin.getvalue(), time_beg.getvalue(), time_end.getvalue(), fio.getvalue()
    else:
        return id_reg, '', '', '', ''


def get_result(id_registration):
    if cfg.debug_level > 1:
        print('Get answer for: ' + str(g.user.id_user) + ' : ' + str(g.user.username))
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select * from ( ' \
          '  select theme_number, theme_name, count_question, true_score, false_score ' \
          '  from ( ' \
          '    select theme_number, theme_name, count_question, ' \
          '           sum(true_result) true_score, sum(false_result) false_score ' \
          '    from ( ' \
          '       select theme_number, to_char(th.descr) theme_name, tft.count_question, tft.count_success, ' \
          '              case when correctly=\'Y\' then 1 else 0 end true_result, ' \
          '              case when correctly != \'Y\' then 1 else 0 end false_result ' \
          '       from questions_for_testing qft, answers a, themes_for_testing tft, themes th ' \
          '       where qft.id_registration=tft.id_registration ' \
          '       and qft.id_theme=th.id_theme ' \
          '       and a.id_answer(+) = qft.id_answer ' \
          '       and tft.id_registration = :id ' \
          '       and tft.id_theme = th.id_theme ' \
          '    ) ' \
          '    group by theme_number, count_question, count_success, theme_name ' \
          '  ) ' \
          '  union ' \
          '  select theme_number, theme_name, count(id_question_for_testing) count_question, ' \
          '         sum(true_result) true_score, sum(false_result) false_score ' \
          '  from ( ' \
          '      select 100 theme_number, \'Итого: \' as  theme_name, qft.id_question_for_testing, tft.count_success, ' \
          '             case when correctly=\'Y\' then 1 else 0 end true_result, ' \
          '             case when correctly != \'Y\' then 1 else 0 end false_result ' \
          '      from questions_for_testing qft, answers a, themes_for_testing tft, themes th ' \
          '      where qft.id_registration=tft.id_registration ' \
          '      and qft.id_theme=th.id_theme ' \
          '      and a.id_answer(+) = qft.id_answer ' \
          '      and tft.id_registration = :id ' \
          '      and tft.id_theme = th.id_theme ' \
          '   ) ' \
          '   group by(theme_number, theme_name) ' \
          ' ) order by 1'
    cursor.execute(cmd, [id_registration])
    cursor.rowfactory = ResultF
    return cursor


def get_id_reg_by_iin(iin):
    if cfg.debug_level > 1:
        print('Got request for ИИН: ' + iin)
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_registration ' \
          'from testing t, persons p ' \
          'where p.iin = :iin ' \
          'and t.id_person=p.id_person ' \
          'and t.status=\'Active\' '
    cursor.execute(cmd, [iin])
    id_reg = 0
    for rec in cursor:
        id_reg = rec[0]
    if cfg.debug_level > 1:
        print('ID_REG: ' + str(id_reg))
    return id_reg


def get_result_by_date(dat):
    if cfg.debug_level > 2:
        print('get_result_by_date: ' + str(g.user.id_user) + ' : ' + str(g.user.username) + ', dat: ' + dat)
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select fio, depart, beg_time_testing, end_time_testing, sum(true_score) true_score ' \
          'from ( ' \
          'select fio, depart, to_char(beg_time_testing,\'dd.mm.yyyy HH24:MI:SS\') as beg_time_testing, ' \
          'to_char(end_time_testing,\'dd.mm.yyyy hh24:mi:ss\') as end_time_testing, ' \
          'theme_number, ' \
          'descr as theme_name, ' \
          'count_question, count_success, sum(true_result) true_score, sum(false_result) false_score ' \
          'from ( ' \
          '  select p.fio, p.depart, t.beg_time_testing, t.end_time_testing, ' \
          '  th.id_theme, theme_number, th.descr, tft.count_question, tft.count_success, ' \
          '  case when correctly=\'Y\' then 1 else 0 end true_result, ' \
          '  case when correctly != \'Y\' then 1 else 0 end false_result ' \
          '  from questions_for_testing qft, ' \
          '       answers a, ' \
          '       themes_for_testing tft, themes th, ' \
          '       persons p, testing t ' \
          '  where qft.id_registration=tft.id_registration ' \
          '  and   p.id_person=t.id_person ' \
          '  and   t.id_registration=tft.id_registration ' \
          '  and   qft.id_theme=th.id_theme ' \
          '  and   a.id_answer(+) = qft.id_answer ' \
          '  and tft.id_theme = th.id_theme ' \
          '  and trunc(t.beg_time_testing,\'DD\')=:dat ' \
          ') ' \
          'group by fio, depart,  beg_time_testing, end_time_testing, ' \
          'theme_number, count_question, count_success, descr ' \
          ') ' \
          'group by fio, depart,  beg_time_testing, end_time_testing ' \
          'order by fio '
    cursor.execute(cmd, [dat])
    cursor.rowfactory = ResultList
    return cursor


def get_full_result(id_registration):
    if cfg.debug_level > 2:
        print('Get Full Result: id_registration' + str(id_registration))
    con = get_connection()
    cursor = con.cursor()
    cmd = "select descr as theme_name, qft.id_question, qft.order_num_question, question, correctly, answer " \
          "from  testing t, themes_for_testing tft, themes th, questions_for_testing qft, questions q, answers a " \
          "where t.id_registration=:id " \
          "and   tft.id_registration=t.id_registration " \
          "and   th.id_theme=tft.id_theme " \
          "and   qft.id_registration=t.id_registration " \
          "and   qft.id_theme=tft.id_theme " \
          "and   qft.id_question=q.id_question " \
          "and   a.id_answer=qft.id_answer " \
          "order by tft.theme_number, qft.order_num_question"
    cursor.execute(cmd, [id_registration])
    cursor.rowfactory = ResultFullF
    return cursor
