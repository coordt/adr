"""Main module."""
import logging
from .settings import Settings

logger = logging.getLogger(__name__)


def main(settings: Settings):
    """
    Do the main thing here

    Args:
        settings:

    Returns:
        ???
    """
    from dataclasses import asdict

    logger.debug("Hello World")
    logger.info("Here are my settings:")
    for k, v in asdict(settings).items():
        logger.info(f"{k}: {v}")
    logger.error("I've fallen and I can't get up!")
