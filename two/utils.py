import os
from datetime import datetime


def get_env_variable(key, default=None):
    return os.environ.get(key, default)


def get_timestamp():
    return datetime.now().isoformat()


def format_log(level, message):
    return f"[{get_timestamp()}] [{level.upper()}] {message}"
