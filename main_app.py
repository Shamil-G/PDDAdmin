from __init__ import app, log
from view import routes
from main_config import cfg
#
# Don't remove next lines 

if __name__ == "__main__":
    app.run(host=cfg.host, port=cfg.port, debug=False)
    log.info("===> Main Application started")

