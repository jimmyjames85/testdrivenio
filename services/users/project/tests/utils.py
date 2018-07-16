import json
from project import db
from project.api.models import User


def add_admin(username, email, password):
    user = User(username=username, email=email, password=password, admin=True)
    db.session.add(user)
    db.session.commit()
    return user


def add_user(username, email, password):
    user = User(username=username, email=email, password=password)
    db.session.add(user)
    db.session.commit()
    return user


def login_user(client, email, password):
    resp_login = client.post(
        '/auth/login',
        data=json.dumps({
            'email': 'test@test.com',
            'password': 'test'
        }),
        content_type='application/json'
    )
    token = json.loads(resp_login.data.decode())['auth_token']
    return token
