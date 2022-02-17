from flask import Flask
import db_config as db_cfg
from model.logger import log


app = Flask(__name__, template_folder='templates', static_folder='static')
# app = Flask(__name__)
app.secret_key = 'this is secret key qer;ekjf;keriutype2t0287'
app.config['SQLALCHEMY_DATABASE_URI'] = f'oracle+cx_oracle://{db_cfg.username}:{db_cfg.password}@{db_cfg.dsn}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
log.info(f'APP Admin configured')
