import sys

import boto3


delegated_admin_account = sys.argv[1]
role_name = sys.argv[2]

organizations = boto3.client("organizations")
credentials = boto3.client("sts").assume_role(
    RoleArn=f"arn:aws:iam::{delegated_admin_account}:role/{role_name}",
    RoleSessionName="GuardDutyDelegatedAdmin",
)["Credentials"]
guardduty = boto3.Session(
    aws_access_key_id=credentials["AccessKeyId"],
    aws_secret_access_key=credentials["SecretAccessKey"],
    aws_session_token=credentials["SessionToken"],
).client("guardduty")

detector_paginator = guardduty.get_paginator("list_detectors")
detectors = []
for page in detector_paginator.paginate():
    detectors.extend(page["DetectorIds"])
detector_id = detectors[0]

account_paginator = organizations.get_paginator("list_accounts")
for page in account_paginator.paginate(PaginationConfig={"MaxItems": 50}):
    accounts = page["Accounts"]
    guardduty.create_members(
        DetectorId=detector_id,
        AccountDetails=[
            {"AccountId": account["Id"], "Email": account["Email"]}
            for account in accounts
        ],
    )
