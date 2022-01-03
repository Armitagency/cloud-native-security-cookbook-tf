import sys

from azure.mgmt.automation import AutomationClient
from azure.identity import AzureCliCredential


def run(account_name, subscription_id):
    credential = AzureCliCredential()
    automation_client = AutomationClient(
        credential=credential, subscription_id=subscription_id
    )
    automation_account = automation_client.automation_account.update(
        "example-resources",
        account_name,
        {"location": "westeurope", "name": account_name, "sku": {"name": "Basic"}},
        identity={"type": "SystemAssigned"},
    )
    print("Get automation account:\n{}".format(automation_account))
    raise Exception()


if __name__ == "__main__":
    run(sys.argv[1], sys.argv[2])
