import base64
import sys
from hashlib import sha256
from subprocess import run

from azure.identity import AzureCliCredential
from azure.storage.blob import BlobClient, CustomerProvidedEncryptionKey

conn_str = (
    run(
        "terraform output connection_string",
        shell=True,
        check=True,
        capture_output=True,
    )
    .stdout.decode("utf-8")
    .split('"')[1]
)

container_name = (
    run(
        "terraform output container_name",
        shell=True,
        check=True,
        capture_output=True,
    )
    .stdout.decode("utf-8")
    .split('"')[1]
)

credential = AzureCliCredential()
blob = BlobClient.from_connection_string(
    conn_str=conn_str, container_name=container_name, blob_name=sys.argv[1]
)

with open("key", "r") as file:
    key = file.read()
    hash = sha256(base64.b64decode(key))

with open(f"{sys.argv[1]}_copy", "wb") as file:
    data = blob.download_blob(
        cpk=CustomerProvidedEncryptionKey(
            key, str(base64.b64encode(hash.digest()), "utf-8")
        )
    )
    data.readinto(file)
