from db_oracle.connect import get_connection
from main_app import log, cfg


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
        print('Programs List ...')
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_region, active, date_op, region_name_ru name_ru, region_name_kz name_kz ' \
          'from pdd_testing.regions t ' \
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


def region(id_region):
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_region, active, date_op, region_name_ru name_ru, region_name_kz name_kz ' \
          'from pdd_testing.regions t ' \
          'where t.id_region = :p1 ' \
          'order by 1'
    cursor.execute(cmd, [id_region])
    cursor.rowfactory = RegionF
    results = []
    rows = cursor.fetchall()
    for row in rows:
        rec = {'id_region': row.id_region, 'name_ru': row.name_ru, 'name_kz': row.name_kz}
        results.append(rec)
        print('---> rec: ' + str(rec))
        print('-----> 1. rec: ' + rec['name_ru'])
    cursor.close()
    con.close()
    return results


def centers(id_region):
    if cfg.debug_level > 3:
        print('Programs List ...')
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_center, id_region, active, date_op, code_center, name_short_ru, name_short_kz, name_ru, name_kz ' \
          'from pdd_testing.centers c ' \
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


def center(id_center):
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_center, id_region, active, date_op, code_center, name_short_ru, name_short_kz, name_ru, name_kz ' \
          'from pdd_testing.centers c ' \
          'where c.id_center = :p1 ' \
          'order by 1'
    cursor.execute(cmd, [id_center])
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


def list_workstations(code_center):
    if cfg.debug_level > 3:
        print('Programs List ...' + code_center)
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_pc, code_center, active, date_op, ip_addr, mac, status ' \
          'from pdd_testing.list_workstation c ' \
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
    if cfg.debug_level > 3:
        print('Programs List ...' + str(id_pc))
    con = get_connection()
    cursor = con.cursor()
    cmd = 'select id_pc, code_center, active, date_op, ip_addr, mac, status ' \
          'from pdd_testing.list_workstation c ' \
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
        print('Region Add ...' + name_ru)
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc('pdd_testing.admin.region_add', [name_ru, name_kz])
    cursor.close()
    con.close()


def region_upd(id_region, name_ru, name_kz):
    if cfg.debug_level > 2:
        print('Region UPD ... id_region: ' + str(id_region) + ', name_ru: ' + name_ru + ', name_kz: ' + name_kz)
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc('pdd_testing.admin.region_upd', [int(id_region), name_ru, name_kz])
    cursor.close()
    con.close()


def region_del(id_region):
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc('pdd_testing.admin.region_del', [id_region])
    cursor.close()
    con.close()


def center_add(id_region, code_center, name_short_ru, name_short_kz, name_ru, name_kz):
    if cfg.debug_level > 3:
        print('Workstation UPD ...' + code_center)
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc('pdd_testing.admin.center_add',
                    [id_region, code_center, name_short_ru, name_short_kz, name_ru, name_kz])
    cursor.close()
    con.close()


def center_upd(id_center, code_center, name_short_ru, name_short_kz, name_ru, name_kz):
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc('pdd_testing.admin.center_upd',
                    [id_center, code_center, name_short_ru, name_short_kz, name_ru, name_kz])
    cursor.close()
    con.close()


def center_del(id_center):
    if cfg.debug_level > 3:
        print('Workstation Del ...' + str(id_center))
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc('pdd_testing.admin.center_del', [id_center])
    cursor.close()
    con.close()


def workstation_add(code_center, ip_addr, mac):
    if cfg.debug_level > 2:
        print('Workstation UPD ...' + code_center)
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc('pdd_testing.admin.workstation_add', [code_center, ip_addr, mac])
    cursor.close()
    con.close()


def workstation_upd(id_pc, ip_addr, mac):
    if cfg.debug_level > 3:
        print('Workstation UPD ...' + str(id_pc))
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc('pdd_testing.admin.workstation_upd', [id_pc, ip_addr, mac])
    cursor.close()
    con.close()


def workstation_del(id_pc):
    if cfg.debug_level > 3:
        print('Workstation Del ...' + str(id_pc))
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc('pdd_testing.admin.workstation_del', [id_pc])
    cursor.close()
    con.close()


def workstation_stat(id_pc):
    if cfg.debug_level > 3:
        print('Workstation Status ...' + str(id_pc))
    con = get_connection()
    cursor = con.cursor()
    cursor.callproc('pdd_testing.admin.workstation_stat', [id_pc])
    cursor.close()
    con.close()
