from flask import Flask
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'oracle://shamil:shamil@192.168.20.64/gfss'
db = SQLAlchemy(app)


class Users(db.Model):
    id_user = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)
    password = db.Column(db.String(120), unique=True, nullable=False)

    def __repr__(self):
        return '<User %r>' % self.id_user + self.name


if __name__ == "__main__":
    print("Testing CONNECT блок!")
    user = Users()
    print(user.query.all())

