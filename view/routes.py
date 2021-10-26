from main_app import app
from flask import render_template, request, redirect, g, flash
from flask_login import login_required
from reports.load_theme import load_theme, load_persons
from model.dml_models import *
from reports.print_personal_report import *
from reports.print_full_personal_report import *
from reports.print_date_report import *
import cx_Oracle
from datetime import datetime
import config as cfg
from model.utils import *
#  Не удалять - неправильно красит среда!!!

if cfg.debug_level > 0:
    print("Routes стартовал...")


@app.route('/about')
def about():
    return render_template("about.html")


@app.route('/', methods=['GET', 'POST'])
@app.route('/home', methods=['GET', 'POST'])
@app.route('/main', methods=['GET', 'POST'])
@app.route('/programs', methods=['GET', 'POST'])
@login_required
def view_programs():
    return render_template("programs.html", cursor=programs())


@app.route('/program-del/<int:id_task>')
@login_required
def view_program_del(id_task):
    program_delete(id_task)
    return render_template("programs.html", cursor=programs())


@app.route('/program-add', methods=['POST', 'GET'])
@login_required
def view_program_add():
    if cfg.debug_level > 1:
        print("Добавляем программу !")
    if request.method == "POST":
        period_for_testing = request.form['period_for_testing']
        name_task = request.form['name_task']
        try:
            program_add(period_for_testing, name_task)
            return redirect('/programs')
        except cx_Oracle.IntegrityError as e:
            errorObj, = e.args
            if cfg.debug_level > 1:
                print("Error Code:", errorObj.code)
                print("Error Message:", errorObj.message)
                print("При добавлении возврата произошла ошибка")
            return redirect("/programs")
    else:
        if cfg.debug_level > 0:
            print("Вход по GET: goto programs-create.html")
        return render_template("program-add.html")


@app.route('/program-upd/<int:id_task>', methods=['POST', 'GET'])
@login_required
def view_program_upd(id_task):
    if cfg.debug_level > 1:
        print("Добавляем программу !")
    if request.method == "POST":
        period_for_testing = request.form['period_for_testing']
        name_task = request.form['name_task']
        try:
            program_upd(id_task, period_for_testing, name_task)
            return redirect(url_for('view_programs'))
        except cx_Oracle.IntegrityError as e:
            errorObj, = e.args
            if cfg.debug_level > 1:
                print("Error Code:", errorObj.code)
                print("Error Message:", errorObj.message)
                print("При добавлении возврата произошла ошибка")
            return redirect("/")
    return render_template("program-upd.html", cursor=program(id_task))


@app.route('/program-detail/<int:id_task>')
@login_required
def view_program_detail(id_task):
    return render_template("program-detail.html", id_task=id_task, name_task=get_name_program(id_task), cursor=themes(id_task))


@app.route('/program-detail/<int:id_task>/load-file', methods=['GET', 'POST'])
def upload_file(id_task):
    if request.method == "POST":
        upl_file_theme = request.files['file-theme']
        upl_file_persons = request.files['file-persons']
        if upl_file_theme.filename:
            print('+++ Идем на обработку THEME файла: ' + upl_file_theme.filename)
            upl_file_theme.save(cfg.REPORTS_PATH + '/' + upl_file_theme.filename)
            return redirect(url_for('upload_file_theme', id_task=id_task, upl_file=upl_file_theme.filename))
        if upl_file_persons.filename:
            print('+++ Идем на обработку  PERSONS файл: ' + upl_file_persons.filename)
            upl_file_persons.save(cfg.REPORTS_PATH + '/' + upl_file_persons.filename)
            return redirect(url_for('upload_file_persons', id_task=id_task, upl_file=upl_file_persons.filename))
    return render_template("program-detail.html", id_task=id_task, name_task=get_name_program(id_task),
                           cursor=themes(id_task), file_theme=upl_file_theme, file_person=upl_file_persons)


# @app.route('/load-theme/<int:id_task>')
# def upload_theme(id_task):
#     return render_template("load-theme.html", id_task=id_task, name_task=get_name_program(id_task))


@app.route('/load-theme/<int:id_task>/<string:upl_file>', methods=['GET', 'POST'])
def upload_file_theme(id_task, upl_file):
    print("+++ upload_file_theme: " + upl_file)
    if request.method == "POST" and upl_file:
        load_theme(id_task, upl_file)
        return redirect(url_for('view_program_detail', id_task=id_task))
    return render_template("load-theme.html", id_task=id_task, name_task=get_name_program(id_task), upl_file=upl_file)


# @app.route('/load-persons/<int:id_task>')
# def upload_person(id_task):
#     return render_template("load-persons.html", id_task=id_task, name_task=get_name_program(id_task))


@app.route('/load-persons/<int:id_task>/<string:upl_file>', methods=['GET', 'POST'])
def upload_file_persons(id_task, upl_file):
    if request.method == "POST" and upl_file:
        load_persons(id_task, upl_file)
        return redirect(url_for('view_program_detail', id_task=id_task))
    return render_template("load-persons.html", id_task=id_task, name_task=get_name_program(id_task), upl_file=upl_file)


@app.route('/theme/<int:id_task>/<int:id_theme>', methods=['POST', 'GET'])
def view_theme(id_task, id_theme):
    print('VIEW THEME...')
    if request.method == "POST":
        theme_name = request.form['theme_name']
        theme_number = request.form['theme_number']
        count_question = request.form['count_question']
        count_success = request.form['count_success']
        theme_update(id_task, id_theme, theme_name, theme_number, count_question, count_success)
        return redirect(url_for('view_program_detail', id_task=id_task))
    return render_template("theme.html", id_task=id_task, id_theme=id_theme, cursor=theme(id_task, id_theme))


@app.route('/theme/<int:id_task>/<int:id_theme>/del')
def view_theme_delete(id_task, id_theme):
    theme_delete(id_theme)
    return redirect(url_for('view_program_detail', id_task=id_task))


@app.route('/user/<string:name>/<int:id_user>')
def user_page(name, id_user):
    return "User: " + name + " : " + str(id_user)


@app.route('/results', methods=['POST', 'GET'])
def view_results():
    file_name = ''
    if request.method == "POST":
        id_reg = request.form['id_reg']
        if id_reg:
            print('Получен ID_REG: ' + id_reg)
            file_name = print_result_test(id_reg)
            app.logger.debug('++++ DEBUG. We are in RESULTS ...')
        else:
            iin = request.form['iin']
            print('view_results by iin: ' + str(iin))
            iin2 = request.form['iin2']
            print('view_results by iin: ' + str(iin) + str(iin2))
            if iin:
                if cfg.debug_level > 2:
                    print('view_results by iin: ' + str(iin))
                file_name = print_result_test_by_iin(iin)
            else:
                form_dat = request.form['dat']
                dat = form_dat.split('-')[2] + '.' + form_dat.split('-')[1] + '.' + form_dat.split('-')[0]
                print('view_results: ' + str(dat))
                if dat:
                    file_name = print_result_by_date(dat)
        if file_name:
            return redirect(url_for('uploaded_file', filename=file_name))
    return render_template("results.html")


@app.route('/result-full', methods=['POST', 'GET'])
def view_results_full():
    file_name = ''
    if request.method == "POST":
        iin = request.form['iin']
        print('view_results by iin: ' + str(iin))
        iin2 = request.form['iin2']
        print('view_results by iin: ' + str(iin) + str(iin2))
        if iin:
            if cfg.debug_level > 2:
                print('view_results by iin: ' + str(iin))
            file_name = print_full_result_test_by_iin(iin)
        if file_name:
            return redirect(url_for('uploaded_file', filename=file_name))
    return render_template("result-full.html")
