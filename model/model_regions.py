from db_oracle.connect import cx_Oracle, get_connection, plsql_proc_s, plsql_proc
from main_app import log
from main_config import cfg


class RegionF(object):
    def __init__(self, id_region, active, date_op, name_ru, name_kz):
        self.id_region = id_region
        self.active = active
        self.date_op = date_op
        self.name_ru = name_ru
        self.name_kz = name_kz


class CenterF(object):
    def __init__(self, id_center, id_region, active, date_op, code_center,
                 name_short_ru, name_short_kz, name_ru, name_kz):
        self.id_center = id_center
        self.id_region = id_region
        self.active = active
        self.date_op = date_op
        self.code_center = code_center
        self.name_short_ru = name_short_ru
        self.name_short_kz = name_short_kz
        self.name_ru = name_ru
        self.name_kz = name_kz


class WorkstationF(object):
    def __init__(self, id_pc, code_center, active, date_op, ip_addr, mac, status):
        self.id_pc = id_pc
        self.code_center = code_center
        self.active = active
        self.date_op = date_op
        self.ip_addr = ip_addr
        self.mac = mac
        self.status = status


def regions():
    if cfg.debug_level > 3:
        print('Regions List ...')
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_region, active, date_op, region_name_ru name_ru, region_name_kz name_kz ' \
          'from cop.regions t ' \
          'order by 1'
    cursor.execute(cmd)
    cursor.rowfactory = RegionF
    results = []
    rows = cursor.fetchall()
    for row in rows:
        rec = {'id_region': row.id_region, 'active': row.active, 'date_op': row.date_op,
               'name_ru': row.name_ru, 'name_kz': row.name_kz}
        results.append(rec)
    cursor.close()
    con.close()
    return results


def centers(id_region):
    if cfg.debug_level > 3:
        print(f'Centers List. id_region: {id_region}')
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_center, id_region, active, date_op, code_center, name_short_ru, name_short_kz, name_ru, name_kz ' \
          'from cop.centers c ' \
          'where c.id_region = :p1 ' \
          'order by 1'
    cursor.execute(cmd, [id_region])
    cursor.rowfactory = CenterF
    results = []
    rows = cursor.fetchall()
    for row in rows:
        rec = {'id_center': row.id_center, 'id_region': row.id_region, 'active': row.active,
               'date_op': row.date_op,'code_center': row.code_center,
               'name_short_ru': row.name_short_ru, 'name_short_kz': row.name_short_kz,
               'name_ru': row.name_ru, 'name_kz': row.name_kz}
        results.append(rec)
    cursor.close()
    con.close()
    return results


def region(id_region):
    with get_connection().cursor() as cursor:
        name_ru = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        name_kz = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        plsql_proc(cursor, 'REGION NAME', 'cop.admin.region_name', [id_region, name_ru, name_kz])
    return name_ru.getvalue(), name_kz.getvalue()


def center(id_center):
    with get_connection().cursor() as cursor:
        region_name = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        code_center = cursor.var(cx_Oracle.DB_TYPE_VARCHAR)
        name_ru = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        name_kz = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        name_short_ru = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        name_short_kz = cursor.var(cx_Oracle.DB_TYPE_NVARCHAR)
        plsql_proc(cursor, 'CENTER NAME', 'cop.admin.center_name',
                   [id_center, region_name, code_center, name_short_ru, name_short_kz, name_ru, name_kz ])
        return region_name.getvalue(), code_center.getvalue(), name_short_ru.getvalue(), name_short_kz.getvalue(), \
               name_ru.getvalue(), name_kz.getvalue()



def list_workstations(code_center):
    if cfg.debug_level > 3:
        print(f'Workstations List. code+center: {code_center}')
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_pc, code_center, active, date_op, ip_addr, mac, status ' \
          'from cop.list_workstation c ' \
          'where c.code_center = :p1 ' \
          'order by ip_addr'
    cursor.execute(cmd, [code_center])
    cursor.rowfactory = WorkstationF
    results = []
    rows = cursor.fetchall()
    for row in rows:
        rec = {'id_pc': row.id_pc, 'code_center': row.code_center, 'active': row.active,
               'date_op': row.date_op, 'ip_addr': row.ip_addr, 'mac': row.mac, 'status': row.status}
        results.append(rec)
    cursor.close()
    con.close()
    return results


def workstation(id_pc):
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_pc, code_center, active, date_op, ip_addr, mac, status ' \
          'from cop.list_workstation c ' \
          'where c.id_pc = :p1 ' \
          'order by ip_addr'
    cursor.execute(cmd, [id_pc])
    cursor.rowfactory = WorkstationF
    results = []
    rows = cursor.fetchall()
    for row in rows:
        rec = {'id_pc': row.id_pc, 'code_center': row.code_center, 'active': row.active,
               'date_op': row.date_op, 'ip_addr': row.ip_addr, 'mac': row.mac, 'status': row.status}
        results.append(rec)
    cursor.close()
    con.close()
    return results


def region_add(name_ru, name_kz):
    if cfg.debug_level > 3:
        print(f'Region Add. name: {name_ru}')
    plsql_proc_s("REGION ADD", 'cop.admin.region_add', [name_ru, name_kz])


def region_upd(id_region, name_ru, name_kz):
    if cfg.debug_level > 2:
        print(f'Region UPD. id_region: {id_region}, name_ru: {name_ru}, name_kz: {name_kz}')
    plsql_proc_s("REGION UPD", 'cop.admin.region_upd', [int(id_region), name_ru, name_kz])


def region_del(id_region):
    plsql_proc_s("REGION DEL", 'cop.admin.region_del', [id_region])


def center_add(id_region, code_center, name_short_ru, name_short_kz, name_ru, name_kz):
    if cfg.debug_level > 3:
        print(f'CENTER ADD. {code_center}')
    plsql_proc_s("CENTER ADD", 'cop.admin.center_add', [id_region, code_center, name_short_ru, name_short_kz, name_ru, name_kz])


def center_upd(id_center, code_center, name_short_ru, name_short_kz, name_ru, name_kz):
    plsql_proc_s("CENTER UPD", 'cop.admin.center_upd', [id_center, code_center, name_short_ru, name_short_kz, name_ru, name_kz])


def center_del(id_center):
    if cfg.debug_level > 3:
        print(f'CENTER DEL. id_center: {id_center}')
    plsql_proc_s("CENTER DEL", 'cop.admin.center_del', [id_center])


def workstation_add(code_center, ip_addr, mac):
    if cfg.debug_level > 2:
        print(f'Workstation ADD. code_center: {code_center}')
    plsql_proc_s("Workstation ADD", 'cop.admin.workstation_add', [code_center, ip_addr, mac])


def workstation_upd(id_pc, ip_addr, mac):
    if cfg.debug_level > 3:
        print(f'Workstation UPD. id_pc: {id_pc}')
    plsql_proc_s("Workstation UPD", 'cop.admin.workstation_upd', [id_pc, ip_addr, mac])


def workstation_del(id_pc):
    if cfg.debug_level > 3:
        print(f'Workstation Del. id_pc: {id_pc}')
    plsql_proc_s("Workstation DEL", 'cop.admin.workstation_del', [id_pc])


def workstation_stat(id_pc):
    if cfg.debug_level > 3:
        print(f'Workstation Status. id_pc: {id_pc}')
    plsql_proc_s("Workstation Status", 'cop.admin.workstation_stat', [id_pc])
