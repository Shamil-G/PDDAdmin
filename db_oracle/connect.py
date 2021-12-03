import db_config as cfg
from main_app import log
# import cx_Oracle
# from cx_Oracle import SessionPool
# con = cx_Oracle.connect(cfg.username, cfg.password, cfg.dsn, encoding=cfg.encoding)


pool_min = cfg.pool_min
pool_max = cfg.pool_max
pool_inc = cfg.pool_inc


try:
    import cx_Oracle
except ImportError:
    log.debug("Error import cx_Oracle :", cx_Oracle.DataError)


def init_session(connection, requestedTag_ignored):
    cursor = connection.cursor()
    if cfg.Debug > 3:
        log.debug("Cursor init_session created!")
    cursor.close()


_pool = cx_Oracle.SessionPool(cfg.username, cfg.password, cfg.dsn,
                              timeout=cfg.timeout, wait_timeout=cfg.wait_timeout,
                              max_lifetime_session=cfg.max_lifetime_session,
                              encoding=cfg.encoding, min=pool_min, max=pool_max, increment=pool_inc,
                              threaded=True, sessionCallback=init_session)
log.debug('Пул соединенй БД Oracle создан. timeout: ' + str(_pool.timeout) +
          ', wait_timeout: ' + str(_pool.wait_timeout) + ', max_lifetime_session: ' + str(_pool.max_lifetime_session))


def get_connection():
    if cfg.Debug > 3:
        log.debug("Получаем курсор!")
    return _pool.acquire()


if __name__ == "__main__":
    log.debug("Тестируем CONNECT блок!")
    con = get_connection()
    log.debug("Версия: " + con.version)
    val = "Hello from main"
    con.close()
    _pool.close()

