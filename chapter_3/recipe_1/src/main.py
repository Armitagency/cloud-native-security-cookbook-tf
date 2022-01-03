import base64


def handle(event, _):
    print(event)

    if "data" in event:
        print(base64.b64decode(event["data"]).decode("utf-8"))
