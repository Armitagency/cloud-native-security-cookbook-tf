import sys

import boto3


delegated_admin_account = sys.argv[1]

organizations = boto3.client("organizations")

for principal in [
    "config-multiaccountsetup.amazonaws.com",
    "config.amazonaws.com",
]:
    delegated_admins = organizations.list_delegated_administrators(
        ServicePrincipal=principal,
    )["DelegatedAdministrators"]

    if len(delegated_admins) == 0:
        organizations.register_delegated_administrator(
            AccountId=delegated_admin_account,
            ServicePrincipal=principal,
        )
