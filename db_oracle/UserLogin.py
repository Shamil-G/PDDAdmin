from typing import List, Any
from flask import render_template, request, redirect, flash, url_for, g
from flask_login import LoginManager, login_required, logout_user, login_user, current_user
import cx_Oracle
from werkzeug.security import check_password_hash, generate_password_hash
from db_oracle.connect import get_connection
from main_app import app, log
from main_config import cfg


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
        log.info(f'LM. Get User By Name: {username}, ip_addr: {request.remote_addr}')
        conn = get_connection()
        cursor = conn.cursor()
        password = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        id_user = cursor.var(cx_Oracle.DB_TYPE_NUMBER)
        id_center = cursor.var(cx_Oracle.DB_TYPE_NUMBER)
        self.ip_addr = request.remote_addr
        self.username = username
        try:
            cursor.callproc('cop.cop.login_center_admin', (username, password, self.ip_addr, id_user, id_center))
            self.id_user = int(id_user.getvalue())
            if self.id_user > 0:
                self.username = username
                self.get_roles(cursor)
                if self.have_role('admin'):
                    self.password = password.getvalue()
                    self.id_center = int(id_center.getvalue())
                    log.info(f'LM. Get User By Name. username: {self.username}, id_center: {self.id_center}, '
                             f'id_user: {self.id_user}, '
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

    def new_user(i_username, i_password, iin, phone, first_name, last_name, middle_name, description):
        hash_pwd = generate_password_hash(i_password)
        con = get_connection()
        cursor = con.cursor()
        message = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        print(f'LM. NEW USER. {i_username} {i_password} {iin} {first_name} {description}')
        try:
            cursor.callproc('cop.cop.new_user2', [i_username, hash_pwd, int(g.user.id_user), iin, phone,
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
        my_var = cursor.var(cx_Oracle.CURSOR)
        if cfg.debug_level > 2:
            print("LM. Get Roles for: " + str(self.username) + ', id_user: ' + str(self.id_user))
        try:
            cursor.callproc('cop.cop.get_roles', [self.id_user, my_var])
            rows = my_var.getvalue().fetchall()
            self.roles.clear()
            for row in rows:
                # print(f"LM. Role for: {self.username}, id_user: {self.id_user} : role: {row[0]}")
                self.roles.extend([row[0]])
        except cx_Oracle.DatabaseError as e:
            error, = e.args
            log.error('ERROR. GET ALL ROLES')
        finally:
            rows.clear()

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
        password = request.form.get('password')
        user = User().get_user_by_name(username)
        if user and user.is_authenticated() and check_password_hash(user.password, password):
            log.info(f"LOGIN PAGE. username:{username}, user.password: {user.password}, password: {password}, "
                     f"user.is_authenticated: {user.is_authenticated()}")
            render_template("base.html")
            login_user(user)
            next_page = request.args.get('next')
            if next_page is not None:
                return redirect(next_page)
            else:
                return redirect(url_for('view_programs'))
        else:
            flash(f"Имя пользователя или пароль неверны: {username}")
            hash_pwd = generate_password_hash(password)
            log.error(
                f'AUTHORITY.  Error IP_ADDR ({request.remote_addr}) or PASSWORD: {username} : {password} : {hash_pwd}')
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
            if 'phone' in request.form:
                phone = request.form.get('phone')
            else:
                phone = ''
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
            message = User.new_user(username, password, iin, phone, first_name, last_name, middle_name, description)
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
