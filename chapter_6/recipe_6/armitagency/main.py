import logging

import azure.functions as func

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

def main(daily: func.TimerRequest):
    logger.info(daily)
