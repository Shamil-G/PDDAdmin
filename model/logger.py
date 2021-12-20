import logging
import logging.config
import main_config as adm_cfg
# import sys


def init_logger():
    logger = logging.getLogger('PDD-ADMIN')
    # logging.getLogger('PDD').addHandler(logging.StreamHandler(sys.stdout))
    # Console
    logging.getLogger('PDD-ADMIN').addHandler(logging.StreamHandler())
    if adm_cfg.debug:
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)
    fh = logging.FileHandler(adm_cfg.LOG_FILE, encoding="UTF-8")
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)

    logger.addHandler(fh)
    logger.info('Logging started')
    return logger


log = init_logger()
