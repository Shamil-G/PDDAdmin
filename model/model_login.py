from typing import Dict, List, Any

from flask import redirect, g, Response, session, url_for
from flask_login import login_user
from db_oracle.UserLogin import User
from db_oracle.connect import get_connection
import requests
import cx_Oracle
import os
from main_app import log, cfg
import base64


class RolesF(object):
    def __init__(self, id_role, active, name, full_name):
        self.id_role = id_role
        self.active = active
        self.name = name
        self.full_name = full_name


class UsersF(object):
    def __init__(self, id_user, username, fio, descr):
        self.id_user = id_user
        self.username = username
        self.fio = fio
        self.descr = descr


def all_roles():
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_role, active, name, full_name from roles order by id_role'
    roles = []
    try:
        cursor.execute(cmd)
        cursor.rowfactory = RolesF
        rows = cursor.fetchall()
        for row in rows:
            role = {'id_role': row.id_role, 'active': row.active, 'name': row.name, 'full_name': row.full_name}
            roles.append(role)
        rows.clear()
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error('ERROR. ALL ROLES')
        log.error(f'Error Code: {error.code}')
        log.error(f'Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()
    return roles


def role_users(id_role):
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select u.id_user, u.username, u.name||\' \'||u.lastname||\' \'||u.lastname as fio, u.descr ' \
          'from roles r, users_roles ur, users u ' \
          'where r.id_role=ur.id_role ' \
          'and   ur.id_user = u.id_user ' \
          'and   r.id_role = :id_role'
    roles = []
    try:
        cursor.execute(cmd, [id_role])
        cursor.rowfactory = UsersF
        rows = cursor.fetchall()
        for row in rows:
            role = {'id_user': row.id_user, 'username': row.username, 'fio': row.fio, 'descr': row.descr}
            log.debug('REC: ' + str(role))
            roles.append(role)
        rows.clear()
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE USERS. id_role: {id_role}')
        log.error(f'Error Code: {error.code}')
        log.error(f'Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()
    return roles


def all_users():
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select u.id_user, u.username, u.name||\' \'||u.lastname||\' \'||u.lastname as fio, u.descr ' \
          'from users u '
    users = []
    try:
        cursor.execute(cmd)
        cursor.rowfactory = UsersF
        rows = cursor.fetchall()
        for row in rows:
            user = {'id_user': row.id_user, 'username': row.username, 'fio': row.fio, 'descr': row.descr}
            users.append(user)
        rows.clear()
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ALL USERS')
        log.error(f'Error Code: {error.code}')
        log.error(f'Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()
    return users


def role_delete(id_role):
    con = get_connection()
    cursor = con.cursor()
    try:
        cursor.callproc('pdd_testing.admin.role_delete', [id_role])
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE DEL. id_role: {id_role}')
        log.error(f'Error Code: {error.code}')
        log.error(f'Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()


def role_add(name, full_name):
    con = get_connection()
    cursor = con.cursor()
    try:
        cursor.callproc('pdd_testing.admin.role_add', [name, full_name])
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE ADD. name: {name}, full_name: {full_name}')
        log.error(f'Error Code: {error.code}')
        log.error(f'Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()


def role_upd(id_role, name, full_name):
    con = get_connection()
    cursor = con.cursor()
    try:
        cursor.callproc('pdd_testing.admin.role_upd', [id_role, name, full_name])
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE UPD. id_role: {id_role}, name: {name} ')
        log.error(f'Error Code: {error.code}')
        log.error(f'Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()


def role_user_add(id_role, id_user):
    con = get_connection()
    cursor = con.cursor()
    try:
        cursor.callproc('pdd_testing.admin.role_assign', [id_role, id_user])
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE USER ADD. id_role: {id_role}, id_user: {id_user} ')
        log.error(f'Error Code: {error.code}')
        log.error(f'Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()


def role_user_del(id_role, id_user):
    con = get_connection()
    cursor = con.cursor()
    try:
        cursor.callproc('pdd_testing.admin.role_remove', [id_role, id_user])
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE USER DEL. id_role: {id_role}, id_user: {id_user} ')
        log.error(f'Error Code: {error.code}')
        log.error(f'Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()

#
# def authority():
#     log.debug('===> Start Authority. for ' + str(session['iin']))
#     username = session['username']
#     try:
#         if username:
#             # Создаем объект регистрации
#             user = User().get_user_by_name(username)
#             if user.password ==
#             if user.is_authenticated():
#                 login_user(user)
#     except Exception as e:
#         error, = e.args
#         log.debug(f"Error Authority: {session['username']}")
#         log.debug(f"Error Code: {error.code}")
#         log.debug(f"Error Message: {error.message}")
#         return redirect("/")
#     return redirect(url_for('login_page_fc'))
