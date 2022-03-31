from pdd_parameter import using


if using == 'DEV_WIN_HOME':
    BASE = 'D:/Shamil/PDD'
    import config_dev_win as cfg
elif using == 'DEV_WIN':
    BASE = 'C:/Shamil/PDD'
    import config_dev_win as cfg
else:
    BASE = '/home/pdd/PDD'
    if using == 'PROD':
        import config_prod as cfg
    if using == 'DEV_UNIX':
        import config_dev_unix as cfg


LOG_FILE = 'pdd-admin.log'
debug = True
print(f"LOAD MAIN CONFIG. USING: {using}, {cfg.os}")

