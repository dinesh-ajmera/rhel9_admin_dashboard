"""RHEL 9 admin dashboard: a thin web page on top of the Bash scripts in bash_scripts/.

The scripts do the real work. This file only does four things:
  1. log the admin in,
  2. call a script,
  3. turn the script's JSON output into a page,
  4. show the script's success/error message.
"""
import json
import os
import secrets
import subprocess
from functools import wraps
from pathlib import Path

from flask import Flask, abort, flash, redirect, render_template, request, session, url_for
from werkzeug.security import check_password_hash

SCRIPTS = Path(__file__).resolve().parent / "bash_scripts"

app = Flask(__name__)
# Settings come from environment variables, so no secret is stored in the code.
app.secret_key = os.environ.get("DASHBOARD_SECRET_KEY") or secrets.token_hex(32)
app.config["SESSION_COOKIE_HTTPONLY"] = True
app.config["SESSION_COOKIE_SAMESITE"] = "Lax"
ADMIN_USER = os.environ.get("DASHBOARD_USER", "admin")
ADMIN_PASSWORD_HASH = os.environ.get("DASHBOARD_PASSWORD_HASH", "")


def run_script(name, *args, stdin=None):
    """Run bash_scripts/NAME and return (ok, text).

    The command is a LIST, so no shell ever parses the arguments: a user name like
    "bob; rm -rf /" is just a (rejected) name, never a command.
    """
    result = subprocess.run(
        ["bash", str(SCRIPTS / name), *args],
        input=stdin, capture_output=True, text=True, timeout=20, check=False,
    )
    if result.returncode == 0:
        return True, result.stdout.strip()
    return False, (result.stderr.strip() or "the script failed")


def read_list(script):
    """Run a script that prints JSON and return it as a Python list."""
    ok, text = run_script(script)
    if ok:
        try:
            return json.loads(text)
        except ValueError:
            text = "the script printed something that is not JSON"
    flash(text, "error")
    return []


def show_result(ok_and_text):
    ok, text = ok_and_text
    flash(text, "ok" if ok else "error")


# ---------------------------------------------------------------- login and safety
def login_required(view):
    @wraps(view)
    def wrapper(*args, **kwargs):
        if not session.get("logged_in"):
            return redirect(url_for("login"))
        return view(*args, **kwargs)
    return wrapper


@app.before_request
def check_csrf_token():
    """Every form carries a secret token; a form from another website cannot know it."""
    session.setdefault("csrf", secrets.token_hex(16))
    if request.method == "POST" and request.form.get("csrf") != session["csrf"]:
        abort(400)


@app.context_processor
def inject_csrf():
    return {"csrf": session.get("csrf", "")}


@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        name_ok = request.form.get("username") == ADMIN_USER
        pass_ok = bool(ADMIN_PASSWORD_HASH) and check_password_hash(ADMIN_PASSWORD_HASH, request.form.get("password", ""))
        if name_ok and pass_ok:
            session.clear()
            session["logged_in"] = True
            return redirect(url_for("home"))
        flash("Wrong username or password.", "error")
    return render_template("login.html", configured=bool(ADMIN_PASSWORD_HASH))


@app.route("/logout", methods=["POST"])
def logout():
    session.clear()
    return redirect(url_for("login"))


# ------------------------------------------------------------------------- pages
@app.route("/")
@login_required
def home():
    users_ok, users = run_script("user_count.sh")
    groups_ok, groups = run_script("groups_count.sh")
    return render_template("index.html", user_count=users if users_ok else "?", group_count=groups if groups_ok else "?")


@app.route("/users", methods=["GET", "POST"])
@login_required
def users():
    if request.method == "POST":
        form = request.form
        if form.get("action") == "add":
            # The password goes in through STDIN, never as an argument (arguments are visible in `ps`).
            show_result(run_script("user_add.sh", form.get("username", ""), form.get("comment", ""),
                                   stdin=form.get("password", "") + "\n"))
        else:
            show_result(run_script("change_user_details.sh", form.get("username", ""),
                                   form.get("field", ""), form.get("value", "")))
        return redirect(url_for("users"))
    return render_template("users.html", users=read_list("users.sh"))


@app.route("/groups", methods=["GET", "POST"])
@login_required
def groups():
    if request.method == "POST":
        form = request.form
        if form.get("action") == "add":
            show_result(run_script("group_add.sh", form.get("name", "")))
        else:
            show_result(run_script("change_group_details.sh", form.get("name", ""),
                                   form.get("field", ""), form.get("value", "")))
        return redirect(url_for("groups"))
    return render_template("groups.html", groups=read_list("groups.sh"))


if __name__ == "__main__":
    # Local only, debug OFF. (debug=True would let anyone who reaches the page run Python code.)
    app.run(host="127.0.0.1", port=5000)
