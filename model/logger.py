import logging
from logging.handlers import RotatingFileHandler
import app_config as cfg
# import sys


def init_logger():
    logger = logging.getLogger('PDD-ADMIN')
    # logging.getLogger('PDD').addHandler(logging.StreamHandler(sys.stdout))
    # Console
    logging.getLogger('PDD-ADMIN').addHandler(logging.StreamHandler())
    if cfg.debug:
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)
    fh = logging.FileHandler(cfg.LOG_FILE, encoding="UTF-8")
    # fh = RotatingFileHandler(cfg.LOG_FILE, encoding="UTF-8", maxBytes=10000000, backupCount=5)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)

    logger.addHandler(fh)
    logger.info('=====> Logging started')
    return logger


log = init_logger()
