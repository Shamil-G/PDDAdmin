from typing import Dict, List, Any
from werkzeug.security import generate_password_hash, check_password_hash
from flask import redirect, g, request, session, url_for
from flask_login import login_user
from db_oracle.UserLogin import User
from db_oracle.connect import get_connection, plsql_proc, plsql_proc_s
import requests
import cx_Oracle
import os
from main_app import log
import app_config as cfg
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
    my_var = cursor.var(cx_Oracle.CURSOR)
    roles = []
    try:
        cursor.callproc('cop.cop.all_roles', [my_var])
        rows = my_var.getvalue().fetchall()
        for row in rows:
            role = {'id_role': row[0], 'active': row[1], 'name': row[2], 'full_name': row[3]}
            log.info(f'id_role: {row[0]}, active: {row[1]}, name: {row[2]}, full_name: {row[3]}')
            roles.append(role)
        rows.clear()
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error('ERROR. ALL ROLES')
        log.error(f'Error Code: {error.code}, Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()
    return roles


def all_users():
    con = get_connection()
    cursor = con.cursor()
    my_var = cursor.var(cx_Oracle.CURSOR)
    users = []
    try:
        cursor.callproc('cop.cop.all_users', [my_var])
        rows = my_var.getvalue().fetchall()
        for row in rows:
            user = {'id_user': row[0], 'username': row[1], 'fio': row[2], 'descr': row[3]}
            users.append(user)
        rows.clear()
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ALL USERS')
        log.error(f'Error Code: {error.code}, Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()
    return users


def list_users():
    con = get_connection()
    cursor = con.cursor()
    my_var = cursor.var(cx_Oracle.CURSOR)
    users = []
    try:
        cursor.callproc('cop.cop.list_users', [my_var])
        rows = my_var.getvalue().fetchall()
        for row in rows:
            user = {'id_user': row[0], 'oper': row[1], 'oper_center': row[2], 'admin': row[3], 'secure': row[4],
                    'username': row[5], 'fio': row[6], 'descr': row[7]}
            users.append(user)
        rows.clear()
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ALL USERS')
        log.error(f'Error Code: {error.code}, Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()
    return users


def get_role_name(id_role):
    with get_connection().cursor() as cursor:
        role_name = cursor.var(cx_Oracle.DB_TYPE_VARCHAR)
        plsql_proc(cursor, 'GET ROLE NAME', 'cop.cop.get_role_name', [id_role, role_name])
        return role_name.getvalue()


def alter_role(id_user, role_name):
    plsql_proc_s('ALTER_ROLE', 'cop.cop.alter_user_role', [id_user, role_name])
    log.info(f'ALTER ROLE. id_role: {id_user}, role_name: {role_name}')


def role_users(id_role):
    con = get_connection()
    cursor = con.cursor()
    my_var = cursor.var(cx_Oracle.CURSOR)
    roles = []
    try:
        cursor.callproc('cop.cop.role_users', [id_role, my_var])
        rows = my_var.getvalue().fetchall()
        for row in rows:
            role = {'id_user': row[0], 'username': row[1], 'fio': row[2], 'descr': row[3]}
            roles.append(role)
        rows.clear()
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE USERS. id_role: {id_role}')
        log.error(f'Error Code: {error.code}, Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()
    return roles


def role_delete(id_role):
    con = get_connection()
    cursor = con.cursor()
    try:
        cursor.callproc('cop.admin.role_delete', [id_role])
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE DEL. id_role: {id_role}')
        log.error(f'Error Code: {error.code}, Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()


def role_add(name, full_name):
    con = get_connection()
    cursor = con.cursor()
    try:
        cursor.callproc('cop.admin.role_add', [name, full_name])
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE ADD. name: {name}, full_name: {full_name}')
        log.error(f'Error Code: {error.code}, Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()


def role_upd(id_role, name, full_name):
    con = get_connection()
    cursor = con.cursor()
    try:
        cursor.callproc('cop.admin.role_upd', [id_role, name, full_name])
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE UPD. id_role: {id_role}, name: {name} ')
        log.error(f'Error Code: {error.code}, Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()


def role_user_add(id_role, id_user):
    con = get_connection()
    cursor = con.cursor()
    try:
        cursor.callproc('cop.admin.role_assign', [id_role, id_user])
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE USER ADD. id_role: {id_role}, id_user: {id_user} ')
        log.error(f'Error Code: {error.code}, Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()


def role_user_del(id_role, id_user):
    con = get_connection()
    cursor = con.cursor()
    try:
        cursor.callproc('cop.admin.role_remove', [id_role, id_user])
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        log.error(f'ERROR. ROLE USER DEL. id_role: {id_role}, id_user: {id_user} ')
        log.error(f'Error Code: {error.code}, Error Message: {error.message}')
    finally:
        cursor.close()
        con.close()


def get_user_info(id_user: int):
    with get_connection().cursor() as cursor:
        username = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        iin = cursor.var(cx_Oracle.DB_TYPE_VARCHAR)
        phone = cursor.var(cx_Oracle.DB_TYPE_VARCHAR)
        first_name = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        last_name = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        middle_name = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        descr = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        plsql_proc(cursor, 'GET USER INFO', 'cop.cop.get_user_info',
                   [id_user, username, iin, phone, last_name, first_name, middle_name, descr])
        log.info(f'GET USER INFO.  ID_USER: {id_user}, username: {username.getvalue()}, iin; {iin.getvalue()}')
        return username.getvalue(), iin.getvalue(), phone.getvalue(), last_name.getvalue(), first_name.getvalue(), \
               middle_name.getvalue(), descr.getvalue()


def set_user_info(id_user: int, username, password, iin, phone, last_name, first_name, middle_name, descr):
    log.info(f'SET USER INFO.  ID_USER: {id_user}, username: {username}, iin; {iin}')
    plsql_proc_s('SET USER INFO', 'cop.cop.set_user_info',
                 [id_user, username, password, iin, phone, last_name, first_name, middle_name, descr])
