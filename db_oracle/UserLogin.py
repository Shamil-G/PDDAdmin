from typing import List, Any
from flask import render_template, request, redirect, flash, url_for, g
from flask_login import LoginManager, login_required, logout_user, login_user, current_user
import cx_Oracle
from werkzeug.security import check_password_hash, generate_password_hash
from db_oracle.connect import get_connection
from main_app import app, log
import config as cfg


login_manager = LoginManager(app)
login_manager.login_view = 'login_page'
if cfg.debug_level > 0:
    print("UserLogin стартовал...")


class User:
    id_user = 0
    id_center = 0
    username = ''
    password = ''
    active = ''
    ip_addr = ''
    roles: List[Any] = []
    debug = False

    def get_user_by_name(self, username):
        log.info('LM. Get User By Name: ' + str(username))
        conn = get_connection()
        cursor = conn.cursor()
        password = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        id_user = cursor.var(cx_Oracle.DB_TYPE_NUMBER)
        id_center = cursor.var(cx_Oracle.DB_TYPE_NUMBER)
        self.ip_addr = request.remote_addr
        self.username = username
        try:
            cursor.callproc('cop.login_admin', (username, password, self.ip_addr, id_user, id_center))
            self.id_user = int(id_user.getvalue())
            if self.id_user > 0:
                self.get_roles(cursor)
                if self.have_role('admin'):
                    self.password = password.getvalue()
                    self.id_center = int(id_center.getvalue())
                    log.info(f'LM. Get User By Name. username: {self.username}, id_center: {self.id_center}, '
                             f'password {self.password}, ip: {self.ip_addr}')
                else:
                    log.warning(f'LM. Get User By Name. {self.username} is not ADMINISTRATOR')
        finally:
            cursor.close()
            conn.close()
        if not self.password:
            return None
        else:
            return self

    def new_user(i_username, i_password, iin, first_name, last_name, middle_name, description):
        hash_pwd = generate_password_hash(i_password)
        con = get_connection()
        cursor = con.cursor()
        message = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        print(f'LM. NEW USER. {i_username} {i_password} {iin} {first_name} {description}')
        try:
            cursor.callproc('cop.new_user2', [i_username, hash_pwd, int(g.user.id_user), iin,
                            first_name, last_name, middle_name, description, message])
        except cx_Oracle.DatabaseError as e:
            error, = e.args
            log.error('ERROR. ALL ROLES')
            log.error(f'Error Code: {error.code}')
            log.error(f'Error Message: {error.message}')
        finally:
            cursor.close()
            con.close()
        return message.getvalue()

    def get_roles(self, cursor):
        if cfg.debug_level > 1:
            print("LM. Get Roles for: " + str(self.username) + ', id_user: ' + str(self.id_user))
        cursor.execute("select r.name from roles r, users u, users_roles us " +
                       "where u.id_user=us.id_user " +
                       "and   r.id_role=us.id_role " +
                       "and u.id_user=:uid_user", uid_user=self.id_user)
        self.roles.clear()
        for record in cursor:
            for list_val in record:
                self.roles.extend([list_val])

    def have_role(self, role_name):
        return role_name in self.roles

    def is_authenticated(self):
        if self.id_user < 0:
            return False
        else:
            return True

    def is_active(self):
        if self.active is None:
            return True
        else:
            return False

    def is_anonymous(self):
        if self.id_user < 0:
            return True
        else:
            return False

    def get_id(self):
        return self.username


@login_manager.user_loader
def loader_user(username):
    if cfg.debug_level > 0:
        print(f"LM. LOADER USER: {username}")
    return User().get_user_by_name(username)


@app.route('/logout', methods=['GET', 'POST'])
@login_required
def logout():
    logout_user()
    return redirect(url_for('view_programs'))


@app.after_request
def redirect_to_signin(response):
    if response.status_code == 401:
        return redirect(url_for('login_page') + '?next=' + request.url)
    return response


@app.before_request
def before_request():
    g.user = current_user


@app.route('/login', methods=['GET', 'POST'])
def login_page():
    if cfg.debug_level > 0:
        print("Login Page")
    if request.method == "POST":
        username = request.form.get('username')
        user_password = request.form.get('password')
        if cfg.debug_level > 0:
            print("1. Login Page. username: "+str(username)+" : "+str(user_password))
        if username and user_password:
            user = User().get_user_by_name(username)
            # if user is not None and check_password_hash(user.password, user_password):
            if not user.is_anonymous():
                # Принудительно обновляем базовый шаблон
                render_template("base.html")
                login_user(user)
                next_page = request.args.get('next')
                if next_page is not None:
                    return redirect(next_page)
                else:
                    return redirect(url_for('view_programs'))
            else:
                flash("2. Имя пользователя или пароль неверны " + username)
                return redirect(url_for('login_page'))

    flash('Введите имя и пароль')
    return render_template('login.html')


@app.route('/register', methods=['GET', 'POST'])
def register():
    if 'admin' in g.user.roles:
        if request.method == 'POST':
            username = request.form.get('username')
            password = request.form.get('password')
            password2 = request.form.get('password2')
            iin = request.form.get('iin')
            first_name = request.form.get('first_name')
            last_name = request.form.get('last_name')
            middle_name = request.form.get('middle_name')
            description = request.form.get('description')

            if cfg.debug_level > 0:
                print("/register. username: " + str(username))
            if not (username and password and password2):
                flash('Требуется заполнение всех полей')
                return redirect(url_for('register'))
            elif password != password2:
                flash('Пароли не совпадают')
                return redirect(url_for('register'))
            log.info(f'REGISTER. {username} {password} {iin} {first_name} {description}')
            print(f'REGISTER. {username} {password} {iin} {first_name} {description}')
            message = User.new_user(username, password, iin, first_name, last_name, middle_name, description)
            if message:
                flash(message)
                return render_template('register.html')
            else:
                return redirect(url_for('view_programs'))

        flash("Введите имя и пароль два раза")
    return render_template('register.html')


# @app.context_processor
# def get_current_user():
    # if g.user.id_user:
    # if g.user.is_anonymous:
    #     print('Anonymous current_user!')
    # if g.user.is_authenticated:
    #     print('Authenticated current_user: '+str(g.user.username))
    # return{"current_user": 'admin_user'}
