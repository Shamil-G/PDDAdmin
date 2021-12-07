from flask import render_template, flash, request,  Response, redirect, g, make_response
from flask_login import login_required, current_user, logout_user
from datetime import date
from model.utils import *
# from model.testing import *
from model.dml_models import *
from model.model_login import *
from main_app import app, log, cfg
from reports.print_personal_report import print_result_test
from view.routes_regions import *
from loading.load_pdd import load_task

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
        log.debug("Добавляем программу !")
    if request.method == "POST":
        language = request.form['language']
        name_task = request.form['name_task']
        try:
            program_upd(id_task, language, name_task)
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
            file_path = cfg.UPLOAD_PATH + '/' + upl_file_theme.filename
            if os.path.exists("file_path"):
                os.remove("file_path")
            upl_file_theme.save(file_path)
            return redirect(url_for('upload_file_theme', id_task=id_task, upl_file=upl_file_theme.filename))
        if upl_file_persons.filename:
            print('+++ Идем на обработку  PERSONS файл: ' + upl_file_persons.filename)
            upl_file_persons.save(cfg.UPLOAD_PATH + '/' + upl_file_persons.filename)
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
        load_task(id_task, upl_file)
        return redirect(url_for('view_program_detail', id_task=id_task))
    return render_template("load-theme.html", id_task=id_task, name_task=get_name_program(id_task), upl_file=upl_file)


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


@app.route('/roles')
def view_roles():
    return render_template("roles.html", cursor=all_roles())


@app.route('/role-delete/<int:id_role>')
def view_role_delete(id_role):
    role_delete(id_role)
    return render_template("roles.html", cursor=all_roles())


@app.route('/role-add', methods=['POST', 'GET'])
def view_role_add():
    if cfg.debug_level > 1:
        print("Добавляем  Роль !")
    if request.method == "POST":
        try:
            name = request.form['name_role']
            full_name = request.form['full_name_role']
            role_add(name, full_name)
        finally:
            if cfg.debug_level > 0:
                print("ROLE_ADD. Вход по GET")
            return redirect("/roles")
    return render_template("role-add.html")


@app.route('/role-detail/<int:id_role>', methods=['POST', 'GET'])
def view_role_upd(id_role):
    if cfg.debug_level > 1:
        print("Обновляем роль!")
    if request.method == "POST":
        try:
            name = request.form['name_role']
            full_name = request.form['full_name_role']
            role_upd(id_role, name, full_name)
        finally:
            if cfg.debug_level > 0:
                print("ROLE_UPD. Вход по GET")
            return redirect("/roles")
    return render_template("role-upd.html")


@app.route('/role-detail/<int:id_role>')
def view_role_detail(id_role):
    return render_template("roles.html", cursor=all_roles())


@app.route('/role-users/<int:id_role>')
def view_role_users(id_role):
    _all_users = all_users()
    _role_users = role_users(id_role)
    for user in _role_users:
        _all_users.remove(user)
    return render_template("role-users.html", id_role=id_role, all_users=_all_users, role_users=_role_users)


@app.route('/role-users-add/<int:id_role>/<int:id_user>')
def view_role_users_add(id_role, id_user):
    role_user_add(id_role, id_user)
    return redirect(url_for('view_role_users', id_role=id_role))


@app.route('/role-users-del/<int:id_role>/<int:id_user>')
def view_role_users_del(id_role, id_user):
    role_user_del(id_role, id_user)
    return redirect(url_for('view_role_users', id_role=id_role))


@app.route('/user/<string:name>/<int:id_user>')
def user_page(name, id_user):
    return "User: " + name + " : " + str(id_user)

