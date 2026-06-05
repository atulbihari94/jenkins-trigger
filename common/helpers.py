import os


def get_env(key, default=None):
    return os.environ.get(key, default)


def is_production():
    return get_env("ENV", "dev") == "production"
