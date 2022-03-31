from pdd_parameter import using
from model.logger import log
#from redis import Redis
import redis

if using[0:7] != 'DEV_WIN':
    LIB_DIR = r'/home/pdd/instantclient_21_4'
elif using == 'DEV_WIN_HOME':
    LIB_DIR = r'd:/install/oracle/instantclient_19_13'
else:
    LIB_DIR = r'C:\Shamil\instantclient_21_3'

log.info(f"=====> DB CONFIG. using: {using}, LIB_DIR: {LIB_DIR}")

username = 'pdd_testing'
password = 'pdd_01235'
host = 'dbpdd'
port = 1521
service = 'pdd'
encoding = 'UTF-8'
dsn = '10.51.203.168:1521/pdd'
timeout = 60       # В секундах. Время простоя, после которого курсор освобождается
wait_timeout = 15000  # Время (в миллисекундах) ожидания доступного сеанса в пуле, перед тем как выдать ошибку
max_lifetime_session = 2800  # Время в секундах, в течении которого может существоват сеанс
pool_min = 4
pool_max = 20
pool_inc = 4
Debug = True


class SessionConfig:
    # secret_key = 'this is secret key qer:ekjf;keriutype2tO287'
    SECRET_KEY = 'this is secret key qer:ekjf;keriutype2tO287'
    SESSION_TYPE = 'redis'
    # SESSION_TYPE = "filesystem"
    SESSION_REDIS = redis.from_url('redis://@10.51.203.144:6379')
    SESSION_USE_SIGNER = True
    # SESSION_REDIS = Redis(host='10.51.203.144', port='6379')
    # SESSION_PERMANENT = False
    PERMANENT_SESSION_LIFETIME = 36000
    # SQLALCHEMY_DATABASE_URI = f'oracle+cx_oracle://{username}:{password}@{dsn}'
    # SQLALCHEMY_TRACK_MODIFICATIONS = False
    print(f"----------> SESSION_REDIS: {SESSION_REDIS}")


