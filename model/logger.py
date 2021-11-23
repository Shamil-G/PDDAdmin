import logging
import logging.config
import config as cfg


def init_logger():
    logger = logging.getLogger('PDD')
    if cfg.debug:
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.DEBUG)
    fh = logging.FileHandler(cfg.LOG_FILE, encoding="UTF-8")
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)

    logger.addHandler(fh)
    logger.info('Logging started')
    return logger


log = init_logger()
