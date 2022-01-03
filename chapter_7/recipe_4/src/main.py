import base64
import json
import os

import requests
from google.cloud import secretmanager

client = secretmanager.SecretManagerServiceClient()


def run(asset):
    response = client.access_secret_version(
        request={"name": f"{os.environ['SECRET_ID']}/versions/latest"}
    )
    token = response.payload.data.decode("utf-8")
    if asset["resource"]["data"]["autoCreateSubnetworks"]:
        requests.post(
            "https://slack.com/api/chat.postMessage",
            data={
                "token": token,
                "channel": f"#{os.environ['CHANNEL']}",
                "text": "".join(
                    [
                        "The following resource ",
                        asset["name"],
                        " is non-compliant, expected no automatic subnetworks",
                    ]
                ),
            },
        )


def handle(event, _):
    if "data" in event:
        run(json.loads(base64.b64decode(event["data"]).decode("utf-8"))["asset"])
