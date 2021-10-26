from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import Column

# from main_app import app


# db = SQLAlchemy(app)
print("Модель стартовала...")


class TaskF:
    def __init__(self, id_task, period_for_testing, name_task):
        self.id_task = id_task
        self.period_for_testing = period_for_testing
        self.name_task = name_task


class ThemesF:
    def __init__(self, id_task, id_theme, theme_number, count_question, count_success, theme_name):
        self.id_task = id_task
        self.id_theme = id_theme
        self.theme_number = theme_number
        self.count_question = count_question
        self.count_success = count_success
        self.theme_name = theme_name


class ResultF(object):
    def __init__(self, theme_number, theme_name, count_question,
                 # count_success,
                 true_score, false_score):
        self.theme_number = theme_number
        self.theme_name = theme_name
        self.count_question = count_question
        # self.count_success = count_success
        self.true_score = true_score
        self.false_score = false_score


class ResultFullF(object):
    def __init__(self, theme_name, id_question, order_num_question, question, correctly, answer):
        self.theme_name = theme_name
        self.id_question = id_question
        self.order_num_question = order_num_question
        self.question = question
        self.correctly = correctly
        self.answer = answer


class ResultList(object):
    def __init__(self, fio, depart, beg_time, end_time, true_score):
        self.fio = fio
        self.depart = depart
        self.beg_time = beg_time
        self.end_time = end_time
        self.true_score = true_score
