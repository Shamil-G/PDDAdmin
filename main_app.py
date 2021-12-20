from __init__ import app, cfg, log


#
# Don't remove next lines 
from view import routes

if __name__ == "__main__":
    app.run(host=cfg.host, port=cfg.port, debug=False)
    log.info("===> Main Application started")

