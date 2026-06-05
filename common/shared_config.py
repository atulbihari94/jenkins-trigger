APP_VERSION = "1.0.0"
DEFAULT_REGION = "eu-west-1"
LOG_LEVEL = "INFO"


def get_config():
    return {
        "version": APP_VERSION,
        "region": DEFAULT_REGION,
        "log_level": LOG_LEVEL,
    }
