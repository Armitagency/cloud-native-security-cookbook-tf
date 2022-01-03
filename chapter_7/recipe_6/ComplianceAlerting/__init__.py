import json
import logging
import os

import azure.functions as func
import requests
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient


def main(event: func.EventGridEvent):

    result = json.dumps(
        {
            "id": event.id,
            "data": event.get_json(),
            "topic": event.topic,
            "subject": event.subject,
            "event_type": event.event_type,
        }
    )

    logging.info(result)

    credential = DefaultAzureCredential()

    secret_client = SecretClient(
        vault_url=os.environ["KEY_VAULT_URI"], credential=credential
    )
    token = secret_client.get_secret("token")
    requests.post(
        "https://slack.com/api/chat.postMessage",
        data={
            "token": token,
            "channel": f"#{os.environ['CHANNEL']}",
            "text": f"{result['data']}",
        },
    )
