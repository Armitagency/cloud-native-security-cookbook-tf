import base64
import subprocess
import sys

import boto3

filename = sys.argv[1]

with open("key", "r") as file:
    key = base64.b64decode(file.read())

s3 = boto3.client("s3")
bucket_name = (
    subprocess.run(
        "terraform output bucket_name",
        shell=True,
        check=True,
        capture_output=True,
    )
    .stdout.decode("utf-8")
    .split('"')[1]
)
print(
    s3.get_object(
        Bucket=bucket_name,
        Key=filename,
        SSECustomerAlgorithm="AES256",
        SSECustomerKey=key,
    )["Body"]
    .read()
    .decode()
)
