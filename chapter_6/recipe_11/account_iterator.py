import subprocess
import sys

import boto3

def init():
  subprocess.run(f"terraform init", check=True, shell=True)

def get_accounts():
  organizations = boto3.client('organizations')
  paginator = organizations.get_paginator("list_accounts")

  return [
        account["Id"]
        for page in paginator.paginate()
        for account in page["Accounts"]
        if account["Status"] != "SUSPENDED"
  ]

def workspace_exists(account):
  returncode = subprocess.run(f"terraform workspace list | grep {account}", shell=True).returncode
  return returncode == 0

def create_workspace(account):
  subprocess.run(f"terraform workspace new {account}", check=True, shell=True)

def switch_to_workspace(account):
  subprocess.run(f"terraform workspace select {account}", check=True, shell=True)

def plan(account):
  subprocess.run(f"terraform plan -var target_account_id={account}", check=True, shell=True)

def apply(account):
  subprocess.run(f"terraform apply -var target_account_id={account} -auto-approve", check=True, shell=True)

def run(is_apply=False):
  init()
  for account in get_accounts():
    if not workspace_exists(account):
      create_workspace(account)
    switch_to_workspace(account)
    plan(account)
    if is_apply:
      apply(account)

if __name__ == "__main__":
  if len(sys.argv) == 2 and sys.argv[1] == "apply":
    run(True)
  else:
    run()
