import base64
import sys
from subprocess import run

from google.cloud import storage


def download(file_key, file_name):
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
        blob = bucket.blob(file_key, encryption_key=encryption_key)

        blob.download_to_filename(file_name)


if __name__ == "__main__":
    download(sys.argv[1], sys.argv[2])
