import sys

import boto3


delegated_admin_account = sys.argv[1]
role_name = sys.argv[2]

organizations = boto3.client("organizations")
credentials = boto3.client("sts").assume_role(
    RoleArn=f"arn:aws:iam::{delegated_admin_account}:role/{role_name}",
    RoleSessionName="SecurityHubDelegatedAdmin",
)["Credentials"]
securityhub = boto3.Session(
    aws_access_key_id=credentials["AccessKeyId"],
    aws_secret_access_key=credentials["SecretAccessKey"],
    aws_session_token=credentials["SessionToken"],
).client("securityhub")


account_paginator = organizations.get_paginator("list_accounts")
for page in account_paginator.paginate(PaginationConfig={"MaxItems": 50}):
    accounts = page["Accounts"]
    securityhub.create_members(
        AccountDetails=[
            {"AccountId": account["Id"], "Email": account["Email"]}
            for account in accounts
        ],
    )
