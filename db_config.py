from pdd_parameter import using
from model.logger import log
import redis

if using[0:7] != 'DEV_WIN':
    LIB_DIR = r'/home/pdd/instantclient_21_4'
elif using == 'DEV_WIN_HOME':
    LIB_DIR = r'd:/install/oracle/instantclient_19_13'
else:
    LIB_DIR = r'C:\Shamil\instantclient_21_3'

if using == 'PROD':
    dsn = '10.51.203.168:1521/pdd'
else:
    dsn = '10.51.203.168:1521/pdd'

if using[0:7] != 'DEV_WIN':
    pool_min = 20
    pool_max = 200
    pool_inc = 20
    Debug = True
else:
    pool_min = 4
    pool_max = 10
    pool_inc = 4
    Debug = True

username = 'pdd_testing'
password = 'pdd_01235'
host = 'dbpdd'
port = 1521
service = 'pdd'
encoding = 'UTF-8'
timeout = 60       # В секундах. Время простоя, после которого курсор освобождается
wait_timeout = 15000  # Время (в миллисекундах) ожидания доступного сеанса в пуле, перед тем как выдать ошибку
max_lifetime_session = 2800  # Время в секундах, в течении которого может существоват сеанс

print(f"=====> DB CONFIG. using: {using}, LIB_DIR: {LIB_DIR}, DSN: {dsn}")
log.info(f"=====> DB CONFIG. using: {using}, LIB_DIR: {LIB_DIR}, DSN: {dsn}")


class SessionConfig:
    # secret_key = 'this is secret key qer:ekjf;keriutype2tO287'
    SECRET_KEY = 'this is secret key qer:ekjf;keriutype2tO287'
    if using == 'DEV_WIN_HOME':
        SESSION_TYPE = "filesystem"
    else:
        SESSION_TYPE = 'redis'
        SESSION_REDIS = redis.from_url('redis://@10.51.203.144:6379')
    SESSION_USE_SIGNER = True
    # SESSION_REDIS = Redis(host='10.51.203.144', port='6379')
    # SESSION_PERMANENT = False
    PERMANENT_SESSION_LIFETIME = 3000
    # SQLALCHEMY_DATABASE_URI = f'oracle+cx_oracle://{username}:{password}@{dsn}'
    # SQLALCHEMY_TRACK_MODIFICATIONS = False
    print(f"----------> TYPE SESSION: {SESSION_TYPE}")


