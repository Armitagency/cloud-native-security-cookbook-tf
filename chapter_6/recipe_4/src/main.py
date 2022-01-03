import base64
from logging import getLogger, INFO

from google.cloud import error_reporting, logging

logging.Client().setup_logging()
logger = getLogger()
logger.setLevel(INFO)

error_client = error_reporting.Client()

def handle(event, _):
    try:
        logger.info(event)
        data = base64.b64decode(event["data"]).decode("utf-8")
        logger.info(data)
    except Exception as e:
        logger.error(e)
        error_client.report_exception()
