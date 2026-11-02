#!/bin/bash
set -e

python manage.py migrate --noinput
python manage.py collectstatic --noinput

python manage.py shell <<'PY'
import os

from django.contrib.auth import get_user_model

User = get_user_model()
username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'admin')
email = os.environ.get('DJANGO_SUPERUSER_EMAIL', '')
password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', '')

if not password:
    raise RuntimeError('DJANGO_SUPERUSER_PASSWORD is not set')

user = User.objects.filter(username=username).first()
if user is None:
    user = User(username=username)

user.email = email
user.is_staff = True
user.is_superuser = True
user.is_active = True
user.set_password(password)
user.save()
print(f'Admin user ready: {username}')
PY

exec gunicorn --chdir /var/app/current --bind 0.0.0.0:8000 --workers 3 --timeout 120 Attendance_System.wsgi:application
