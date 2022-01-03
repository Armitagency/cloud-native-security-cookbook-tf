import base64

from Cryptodome.Random import get_random_bytes

key = get_random_bytes(32)
with open("key", "w") as file:
    file.write(str(base64.b64encode(key), "utf-8"))
