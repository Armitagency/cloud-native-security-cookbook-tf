import subprocess
import sys

from azure.identity import AzureCliCredential
from azure.mgmt.resource import SubscriptionClient


def init():
    subprocess.run(f"terraform init", check=True, shell=True)


def get_subscriptions():
    credential = AzureCliCredential()
    client = SubscriptionClient(credential)

    return [
        subscription.subscription_id for 
        subscription in client.subscriptions.list()
    ]


def workspace_exists(subscription):
    completed_process = subprocess.run(
        f"terraform workspace list | grep {subscription}", shell=True
    )
    return completed_process.returncode == 0


def create_workspace(subscription):
    subprocess.run(f"terraform workspace new {subscription}", check=True, shell=True)


def switch_to_workspace(subscription):
    subprocess.run(f"terraform workspace select {subscription}", check=True, shell=True)


def plan(subscription):
    subprocess.run(
        f"terraform plan -var subscription_id={subscription}",
        check=True,
        shell=True,
    )


def apply(subscription):
    subprocess.run(
        f"terraform apply -var subscription_id={subscription} -auto-approve",
        check=True,
        shell=True,
    )


def run(run_plan=True):
    init()
    for subscription in get_subscriptions():
        if not workspace_exists(subscription):
            create_workspace(subscription)
        switch_to_workspace(subscription)
        if run_plan:
            plan(subscription)
        else:
            apply(subscription)


if __name__ == "__main__":
    if len(sys.argv) == 2:
        run(sys.argv[1] != "apply")
    else:
        run()
