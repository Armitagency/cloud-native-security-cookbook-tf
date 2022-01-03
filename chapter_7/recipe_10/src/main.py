import base64
import json

from google.cloud.storage import Client
from google.cloud.storage.constants import PUBLIC_ACCESS_PREVENTION_ENFORCED

client = Client()


def public_access_allowed(iam_configuration):
    return (
        "publicAccessPrevention" in iam_configuration
        and iam_configuration["publicAccessPrevention"] != "enforced"
    ) or ("publicAccessPrevention" not in iam_configuration)


def run(asset):
    if public_access_allowed(asset["resource"]["data"]["iamConfiguration"]):
        bucket_name = asset["resource"]["data"]["name"]
        bucket = client.get_bucket(bucket_name)

        bucket.iam_configuration.public_access_prevention = (
            PUBLIC_ACCESS_PREVENTION_ENFORCED
        )
        bucket.patch()


def handle(event, _):
    try:
        if "data" in event:
            run(json.loads(base64.b64decode(event["data"]).decode("utf-8"))["asset"])
    except Exception as e:
        print(e)
        raise e
