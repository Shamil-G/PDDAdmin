from flask import Flask
from model.logger import log
from flask_session import Session

app = Flask(__name__, template_folder='templates', static_folder='static')
# app.secret_key = 'this is secret key qer:ekjf;keriutype2tO287'
app.config.from_object('db_config.SessionConfig')
server_session = Session(app)
log.info(f'APP Admin configured and started')
print("__INIT MAIN APPAdmin__ started")