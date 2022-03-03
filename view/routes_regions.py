from flask import render_template, flash, request,  Response, redirect, g, make_response, url_for, session
from main_app import app, log
from main_config import cfg
from flask_login import login_required, current_user, logout_user
from model.model_regions import *


@app.route('/', methods=['GET', 'POST'])
@app.route('/home', methods=['GET', 'POST'])
@app.route('/main', methods=['GET', 'POST'])
@app.route('/regions')
@login_required
def view_regions():
    return render_template("regions.html", cursor=regions())


@app.route('/region-add/', methods=['GET', 'POST'])
@login_required
def view_region_add():
    if request.method == "POST":
        name_ru = request.form['name_ru']
        name_kz = request.form['name_kz']
        region_add(name_ru, name_kz)
        return redirect(url_for('view_regions'))
    return render_template("region-add.html")


@app.route('/region-upd/<int:id_region>', methods=['GET', 'POST'])
@login_required
def view_region_upd(id_region):
    if request.method == "POST":
        name_ru = request.form['name_ru']
        name_kz = request.form['name_kz']
        region_upd(id_region, name_ru, name_kz)
        return redirect(url_for('view_regions'))
    name_ru, name_kz = region(id_region)
    print(f'--------> name_ru: {name_ru}, name_kz: {name_kz}')
    return render_template("region-upd.html", id_region=id_region, name_ru=name_ru, name_kz=name_kz)


@app.route('/region-del/<int:id_region>')
@login_required
def view_region_del(id_region):
    region_del(id_region)
    return redirect(url_for('view_regions'))


@app.route('/centers/<int:id_region>')
@login_required
def view_centers(id_region):
    name_ru, name_kz = region(id_region)
    name_region = name_ru
    if 'kz' in session['language']:
        name_region = name_kz
    return render_template("centers.html", id_region=id_region, name_region=name_region, cursor=centers(id_region))


@app.route('/center-add/<int:id_region>', methods=['GET', 'POST'])
@login_required
def view_center_add(id_region):
    if request.method == "POST":
        code_center = request.form['code_center']
        name_short_ru = request.form['name_short_ru']
        name_short_kz = request.form['name_short_kz']
        name_ru = request.form['name_ru']
        name_kz = request.form['name_kz']
        center_add(id_region, code_center, name_short_ru, name_short_kz, name_ru, name_kz)
        return redirect(url_for('view_centers', id_region=id_region))
    return render_template("center-add.html", id_region=id_region)


@app.route('/center-upd/<int:id_region>/<int:id_center>', methods=['GET', 'POST'])
@login_required
def view_center_upd(id_region, id_center):
    if request.method == "POST":
        code_center = request.form['code_center']
        name_short_ru = request.form['name_short_ru']
        name_short_kz = request.form['name_short_kz']
        name_ru = request.form['name_ru']
        name_kz = request.form['name_kz']
        center_upd(id_center, code_center, name_short_ru, name_short_kz, name_ru, name_kz)
        return redirect(url_for('view_centers', id_region=id_region))
    region_name, code_center, name_short_ru, name_short_kz, name_ru, name_kz = center(id_center)
    return render_template("center-upd.html", id_center=id_center, region_name=region_name, code_center=code_center,
                           name_ru=name_ru, name_kz=name_kz, name_short_ru=name_short_ru, name_short_kz=name_short_kz)


@app.route('/center-del/<int:id_region>/<int:id_center>')
@login_required
def view_center_del(id_region, id_center):
    center_del(id_center)
    return redirect(url_for('view_centers', id_region=id_region))


@app.route('/workstations/<string:code_center>')
@login_required
def view_workstations(code_center):
    print('===> Code Center: ' + code_center)
    return render_template("workstations.html", code_center=code_center, cursor=list_workstations(code_center))


@app.route('/workstation-upd/<string:code_center>/<int:id_pc>', methods=['GET', 'POST'])
@login_required
def view_workstation_upd(code_center, id_pc):
    if request.method == "POST":
        ip_addr = request.form['ip_addr']
        mac = request.form['mac']
        workstation_upd(id_pc, ip_addr, mac)
        return redirect(url_for('view_workstations', code_center=code_center))
    return render_template("workstation-upd.html", code_center=code_center, cursor=workstation(id_pc))


@app.route('/workstation-add/<string:code_center>', methods=['GET', 'POST'])
@login_required
def view_workstation_add(code_center):
    if request.method == "POST":
        ip_addr = request.form['ip_addr']
        mac = request.form['mac']
        workstation_add(code_center, ip_addr, mac)
        return redirect(url_for('view_workstations', code_center=code_center))
    return render_template("workstation-add.html", code_center=code_center)


@app.route('/workstation-del/<string:code_center>/<int:id_pc>')
@login_required
def view_workstation_del(code_center, id_pc):
    workstation_del(id_pc)
    return redirect(url_for('view_workstations', code_center=code_center))


@app.route('/workstation-stat/<string:code_center>/<int:id_pc>')
@login_required
def view_workstation_stat(code_center, id_pc):
    workstation_stat(id_pc)
    return redirect(url_for('view_workstations', code_center=code_center))
