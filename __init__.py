from flask import Flask
import db_config as db_cfg
import main_config as adm_cfg
from model.logger import log


if adm_cfg.using == 'PROD':
    import config_prod as cfg
if adm_cfg.using == 'DEV_UNIX':
    import config_dev_unix as cfg
if adm_cfg.using == 'DEV_WIN':
    import config_dev_win as cfg


app = Flask(__name__, template_folder='templates', static_folder='static')
# app = Flask(__name__)
app.secret_key = 'this is secret key qer;ekjf;keriutype2t0287'
app.config['SQLALCHEMY_DATABASE_URI'] = f'oracle+cx_oracle://{db_cfg.username}:{db_cfg.password}@{db_cfg.dsn}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
