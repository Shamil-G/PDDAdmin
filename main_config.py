LOG_FILE = 'pdd-admin.log'
using = 'PROD'
debug = True


if using == 'PROD':
    import config_prod as cfg
if using == 'DEV_UNIX':
    import config_dev_unix as cfg
if using == 'DEV_WIN':
    import config_dev_win as cfg
