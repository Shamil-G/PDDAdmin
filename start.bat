set echo on
#python -m install virtualenv
python -m venv venv
C:\Shamil\PDDAdmin\venv\Scripts\activate.bat
C:\Shamil\PDDAdmin\venv\Scripts\python.exe -m pip install --upgrade pip
C:\Shamil\PDDAdmin\venv\Scripts\pip install flask
pip install flask_login
pip install flask_sqlalchemy
pip install cx_Oracle
pip install xlsxwriter
pip install openpyxl
pip install scikit-build
pip install requests
python main_app.py
