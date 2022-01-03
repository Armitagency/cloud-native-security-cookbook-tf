import base64
import sys
from subprocess import run

from google.cloud import storage


def upload(file_name):
    storage_client = storage.Client()
    bucket_name = (
        run(
            "terraform output storage_bucket_name",
            capture_output=True,
            check=True,
            shell=True,
        )
        .stdout.decode("utf-8")
        .split('"')[1]
    )
    bucket = storage_client.bucket(bucket_name)

    with open("key", "r") as file:
        encryption_key = base64.b64decode(file.read())
        blob = bucket.blob(file_name, encryption_key=encryption_key)

        blob.upload_from_filename(file_name)


if __name__ == "__main__":
    upload(sys.argv[1])
