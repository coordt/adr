workers = 4
worker_class = "uvicorn.workers.UvicornWorker"
preload_app = True  # Load application code before the worker processes are forked.
daemon = True
enable_stdio_inheritance = True
pidfile = "/var/run/gunicorn.pid"
bind = "0.0.0.0:3000"
user = "www-data"
group = "www-data"
accesslog = None
errorlog = "-"
logconfig_dict = {
    "version": 1,
    "disable_existing_loggers": True,
    "formatters": {
        "generic": {
            "format": "%(asctime)s [%(process)d] [%(levelname)s] %(message)s",
            "datefmt": "%Y-%m-%d %H:%M:%S",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "generic",
            "stream": "ext://sys.stdout",
        },
    },
    "loggers": {
        "": {"handlers": ["console"], "propagate": False, "level": "INFO"},
        "gunicorn.error": {
            "handlers": ["console"],
            "level": "INFO",
            "propagate": True,
        },
    },
}
