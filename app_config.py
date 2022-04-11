from pdd_parameter import using, app_name

if using == 'DEV_WIN_HOME':
    BASE = f'D:/Shamil/{app_name}'
elif using == 'DEV_WIN':
    BASE = f'C:/Shamil/{app_name}'
else:
    BASE = f'/home/pdd/{app_name}'

if using[0:7] != 'DEV_WIN':
    host = 'pdd_1'
    os = 'unix'
    debug_level = 2
    FACE_CONTROL_ENABLE = True
    port = 5000
else:
    os = '!unix'
    debug_level = 4
    FACE_CONTROL_ENABLE = True
    host = 'localhost'
    port = 82

PHOTO = f'{BASE}/static/photo'
LIVE_PHOTO = f'{BASE}/live-photo'
PICTURES = '/static/pictures'
LOG_FILE = f'{BASE}/app-admin.log'
UPLOAD_PATH = f'{BASE}/reports'
debug = True
language = 'ru'
src_lang = 'file'
trace_malloc = False
move_at_once = False

print(f"=====> CONFIG. using: {using}, BASE: {BASE}, app_name: {app_name}")


