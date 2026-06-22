from flask import Flask , render_template , request, redirect , url_for , flash
import json
import subprocess

app = Flask(__name__)

app.secret_key="secrete key"
@app.route("/")
def login_page():
    result=subprocess.run([ "bash" , "bash_scripts/user_count.sh"],capture_output=True,text=True)
    user_count=result.stdout
    result=subprocess.run([ "bash" , "bash_scripts/groups_count.sh"],capture_output=True,text=True)
    group_count=result.stdout
    return render_template('index.html',user_count=user_count ,group_count=group_count)

@app.route('/add_user', methods=["POST", 'GET'])
def add_user():
    if request.method =='POST':
        print("post")
        username = request.form.get('name')
        passwd = request.form.get('passwd')
        if not passwd:
            flash(f" user {username} registretion failed!! . Error is : user need a password","unsuccess")
            return redirect(url_for("add_user"))
        if passwd:
            result = subprocess.run(["bash", "bash_scripts/user_add.sh" , username , passwd ],capture_output=True,text=True)
        if result.returncode == 0:
            flash(f"new user {username} is added","success")
            return redirect(url_for("add_user"))
        if result.returncode != 0:
            flash(f" user {username} registretion failed erro is : {result.stderr}","unsuccess")
            return redirect(url_for("add_user"))
        else:
            return redirect(url_for("add_user"))
    else:
        return render_template('add_user.html')

@app.route('/add_group', methods=["POST", 'GET'])
def add_group():
    if request.method =='POST':
        print("post")
        grpname = request.form.get('name')
        passwd = request.form.get('passwd')
        if not passwd:
            flash(f"on group {grpname} you not set any passwd !! .useing passwd is recomanded","unsuccess")
            result = subprocess.run(["groupadd" , grpname ],capture_output=True,text=True)
        if passwd:
            result = subprocess.run(["bash", "bash_scripts/group_aad.sh" , grpname , passwd],capture_output=True,text=True)
        if result.returncode == 0:
            flash(f"new grp {grpname} is added","success")
            return redirect(url_for("add_group"))
        if result.returncode != 0:
            flash(f" grp {grpname} registretion failed erro is : {result.stderr}","unsuccess")
            return redirect(url_for("add_group"))
        else:
            return redirect(url_for("add_group"))
    else:
        return render_template('add_group.html')


@app.route('/users')
def users():
    result=subprocess.run(['bash','bash_scripts/users.sh'], capture_output=True,text=True)
    result_string=result.stdout
    users =json.loads(result_string)
    return render_template('users.html', users=users )


@app.route('/groups')
def groups():
    result=subprocess.run(['bash','bash_scripts/groups.sh'], capture_output=True,text=True)
    result_string=result.stdout
    groups =json.loads(result_string)
    return render_template('groups.html', groups=groups )



@app.route("/user_manipulation" , methods=["POST","GET"])
def manipulation():
    if request.method =="POST":
        print("post s")
        new_username = request.form.get('new_username')
        new_UID=request.form.get("new_UID")
        new_GID=request.form.get("new_GID")
        new_HD=request.form.get("new_HD")
        new_comm=request.form.get("new_comm")
        new_shell=request.form.get("new_shell")
        new_passwd = request.form.get('new_passwd')

        old_username = request.form.get('old_username')
        old_passwd = request.form.get('old_passwd')
        old_UID=request.form.get("old_UID")
        old_GID=request.form.get("old_GID")
        old_HD=request.form.get("old_HD")
        old_comm=request.form.get("old_comm")
        old_shell=request.form.get("old_shell")
        old_detail = f"{old_username}:{old_passwd}:{old_UID}:{old_GID}:{old_comm}:{old_HD}:{old_shell}"
        new_detail = f"{new_username}:{new_passwd}:{new_UID}:{new_GID}:{new_comm}:{new_HD}:{new_shell}"
        print(old_detail)
        print(new_detail)
        if all(x == "" for x in [new_shell,new_comm,new_HD,new_UID,new_GID,new_username]):
            flash("you submit the empty form nothing  change !!!","unsuccess")
            return redirect(url_for("manipulate_users"))

        if not new_username:
            new_username=old_username
        #if not new_passwd:
         #   new_passwdd = old_passwd
        if not new_UID:
            new_UID=old_UID
        if not new_GID:
            new_GID=old_GID
        if not new_HD:
            new_HD=old_HD
        if not new_comm:
            new_comm=old_comm
        if not new_shell:
            new_shell=old_shell

        old_detail = f"{old_username}:{old_passwd}:{old_UID}:{old_GID}:{old_comm}:{old_HD}:{old_shell}"
        new_detail = f"{new_username}:{new_passwd}:{new_UID}:{new_GID}:{new_comm}:{new_HD}:{new_shell}"

        print(old_detail)
        print(new_detail)
       # if all(x is None for x in [new_shell,new_comm,new_HD,new_UID,new_GID,new_username]):
            #flash("you submit the empty form nothing  change !!!","empty form")
           # return redirect(url_for("manipulate_users"))
        print(old_detail)
        print(new_detail)
        result = subprocess.run(["bash" , "bash_scripts/change_user_details.sh", f"{old_detail}" , f"{new_detail}"])
        if result.returncode == 0:
            print("success")
            flash('user data is changed successfully!!' , 'success')
            return redirect(url_for("manipulate_users"))
        elif result.returncode != 0:
            print("unsuccess")
            flash('something is wrong here !!' , 'unsuccess')
            return redirect(url_for("manipulate_users"))
        else:
            return redirect(url_for("manipulate_users"))
    else:
        return redirect(url_for("manipulate_users"))

@app.route('/manipulate_users' , methods=["POST","GET"])
def manipulate_users():
    result=subprocess.run(['bash','bash_scripts/users.sh'], capture_output=True,text=True)
    result_string=result.stdout
    users =json.loads(result_string)
    return render_template('manipulate_users.html', users=users )

@app.route('/manipulate_groups' , methods=["POST","GET"])
def manipulate_groups():
    result=subprocess.run(['bash','bash_scripts/groups.sh'], capture_output=True,text=True)
    result_string=result.stdout
    groups =json.loads(result_string)
    return render_template('manipulate_groups.html', groups=groups )

@app.route("/group_manipulation" , methods=["POST","GET"])
def group_manipulation():
    if request.method =="POST":
        print("post s")
        new_groupname = request.form.get('new_groupname')
        new_GID=request.form.get("new_GID")
        new_users=request.form.get("new_users")
        new_passwd = request.form.get('new_passwd')

        old_groupname = request.form.get('old_groupname')
        old_passwd = request.form.get('old_passwd')
        old_GID=request.form.get("old_GID")
        old_users=request.form.get("old_users")
        old_detail = f"{old_groupname}:{old_passwd}:{old_GID}:{old_users}"
        new_detail = f"{new_groupname}:{new_passwd}:{new_GID}:{new_users}"
        print(old_detail)
        print(new_detail)
        if all(x == "" for x in [new_users,new_GID,new_groupname]):
            flash("you submit the empty form nothing  change !!!","unsuccess")
            return redirect(url_for("manipulate_groups"))

        if not new_groupname:
            new_groupname=old_groupname
        #if not new_passwd:
         #   new_passwdd = old_passwd
        if not new_GID:
            new_GID=old_GID
        if not new_users:
            new_users=old_users

        old_detail = f"{old_groupname}:{old_passwd}:{old_GID}:{old_users}"
        new_detail = f"{new_groupname}:{new_passwd}:{new_GID}:{new_users}"

        print(old_detail)
        print(new_detail)
       # if all(x is None for x in [new_shell,new_comm,new_HD,new_UID,new_GID,new_groupname]):
            #flash("you submit the empty form nothing  change !!!","empty form")
           # return redirect(url_for("manipulate_groups"))
        print(old_detail)
        print(new_detail)
        result = subprocess.run(["bash" , "bash_scripts/change_group_details.sh", f"{old_detail}" , f"{new_detail}"])
        if result.returncode == 0:
            print("success")
            flash('group data is changed successfully!!' , 'success')
            return redirect(url_for("manipulate_groups"))
        elif result.returncode != 0:
            print("unsuccess")
            flash('something is wrong here !!' , 'unsuccess')
            return redirect(url_for("manipulate_groups"))
        else:
            return redirect(url_for("manipulate_groups"))
    else:
        return redirect(url_for("manipulate_groups"))



if __name__ =='__main__':
    app.run(debug=True,host='0.0.0.0' , port=5000)
