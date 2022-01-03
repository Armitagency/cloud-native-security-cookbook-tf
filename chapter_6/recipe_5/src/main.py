from logging import getLogger, INFO

logger = getLogger()
logger.setLevel(INFO)

def handle(event, _):
    try:
        logger.info(event)
    except Exception as e:
        logger.error(e)
        raise e
