"""Tests for app.py. Run:  python3 -m unittest discover -s tests -v   (from the project folder)"""
import os
import sys
import unittest
from pathlib import Path
from unittest import mock

from werkzeug.security import generate_password_hash

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
# The Bash scripts read these files instead of the real /etc/passwd and /etc/group.
os.environ["PASSWD_FILE"] = str(ROOT / "tests" / "fixtures" / "passwd")
os.environ["GROUP_FILE"] = str(ROOT / "tests" / "fixtures" / "group")

import app as dashboard  # noqa: E402  (must come after the environment is set)

PASSWORD = "Correct-Horse-9!"


class DashboardTests(unittest.TestCase):
    def setUp(self):
        dashboard.ADMIN_PASSWORD_HASH = generate_password_hash(PASSWORD)
        dashboard.app.config["TESTING"] = True
        self.client = dashboard.app.test_client()

    def token(self):
        self.client.get("/login")
        with self.client.session_transaction() as sess:
            return sess["csrf"]

    def login(self):
        return self.client.post("/login", data={"username": "admin", "password": PASSWORD, "csrf": self.token()})

    def post(self, url, **data):
        self.client.get("/login")  # any request makes the app create a fresh CSRF token
        with self.client.session_transaction() as sess:
            data["csrf"] = sess["csrf"]
        return self.client.post(url, data=data)

    def test_pages_need_login(self):
        for url in ("/", "/users", "/groups"):
            response = self.client.get(url)
            self.assertEqual(response.status_code, 302, url)
            self.assertIn("/login", response.headers["Location"])

    def test_wrong_password_is_rejected(self):
        response = self.client.post("/login", data={"username": "admin", "password": "nope", "csrf": self.token()})
        self.assertIn("Wrong username or password", response.get_data(as_text=True))
        self.assertEqual(self.client.get("/users").status_code, 302)

    def test_login_works_and_pages_show_script_output(self):
        self.assertEqual(self.login().status_code, 302)
        home = self.client.get("/").get_data(as_text=True)
        self.assertIn(">3</div>", home)  # 3 regular users in the fixture
        users = self.client.get("/users").get_data(as_text=True)
        self.assertIn("alice", users)
        self.assertNotIn(">root<", users)
        self.assertIn("developers", self.client.get("/groups").get_data(as_text=True))

    def test_quotes_in_a_comment_are_shown_safely(self):
        self.login()
        self.assertIn("The Builder", self.client.get("/users").get_data(as_text=True))

    def test_form_without_csrf_token_is_refused(self):
        self.login()
        self.assertEqual(self.client.post("/users", data={"action": "add", "username": "x"}).status_code, 400)

    def test_password_goes_through_stdin_not_arguments(self):
        self.login()
        with mock.patch.object(dashboard, "run_script", return_value=(True, "created user bob")) as fake:
            self.post("/users", action="add", username="bob", comment="Bob", password=PASSWORD)
        args, kwargs = fake.call_args
        self.assertEqual(args[0], "user_add.sh")
        self.assertNotIn(PASSWORD, args)
        self.assertEqual(kwargs["stdin"], PASSWORD + "\n")

    def test_shell_injection_attempt_does_nothing(self):
        self.login()
        marker = Path("/tmp/dashboard_pwned_marker")
        marker.unlink(missing_ok=True)
        response = self.post("/users", action="add", username="x; touch " + str(marker), comment="", password=PASSWORD)
        self.assertEqual(response.status_code, 302)
        self.assertIn("invalid name", self.client.get("/users").get_data(as_text=True))
        self.assertFalse(marker.exists())

    def test_logout_ends_the_session(self):
        self.login()
        self.post("/logout")
        self.assertEqual(self.client.get("/users").status_code, 302)

    def test_no_password_configured_means_nobody_can_log_in(self):
        dashboard.ADMIN_PASSWORD_HASH = ""
        response = self.client.post("/login", data={"username": "admin", "password": "", "csrf": self.token()})
        self.assertIn("Wrong username or password", response.get_data(as_text=True))


if __name__ == "__main__":
    unittest.main()
