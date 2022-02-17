#LIB_DIR = r'/home/pdd/instantclient_21_4'
#LIB_DIR = r'd:/install/oracle/instantclient_19_13'
LIB_DIR = r'C:\Shamil\instantclient_21_3'

username = 'pdd_testing'
password = 'pdd_01235'
host = 'db_pdd'
port = 1521
service = 'pdd'
encoding = 'UTF-8'
dsn = '10.51.203.168:1521/pdd'
timeout = 300       # В секундах. Время простоя, после которого курсор освобождается
wait_timeout = 5000
max_lifetime_session = 2800
pool_min = 4
pool_max = 8
pool_inc = 4
Debug = True
