from __init__ import app, cfg, log
from view import routes

#
# Don't remove next lines 

if __name__ == "__main__":
    app.run(host=cfg.host, port=cfg.port, debug=False)
    log.info("===> Main Application started")

