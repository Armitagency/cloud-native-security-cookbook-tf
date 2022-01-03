import logging

import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.policyinsights import PolicyInsightsClient
from azure.mgmt.policyinsights.models import Remediation
from azure.mgmt.resource.policy import PolicyClient


credential = DefaultAzureCredential()

def main(event: func.EventGridEvent):
    logging.info(event)

    compliance_state = event.get_json()["complianceState"]

    if compliance_state == "NonCompliant":
        policyAssignmentId = event.get_json()["policyAssignmentId"]
        policyDefinitionId = event.get_json()["policyDefinitionId"]

        policy_insights = PolicyInsightsClient(credential=credential)
        policy = PolicyClient(credential=credential)

        definition = policy.policy_definitions.get(
            policy_definition_name=policyDefinitionId
        )
        if definition.policy_rule:
            effect = definition.policy_rule["then"]["effect"]
            if (
                "append" == effect or
                "modify" == effect
            ):

                parameters = Remediation(policy_assignment_id=policyAssignmentId)
                result = policy_insights.remediations.create_or_update_at_subscription(
                    remediation_name="AutomatedRemediation", parameters=parameters
                )

            logging.info(result)
        else:
            logging.info("Policy definition had no remediation action available")
    else:
        logging.info("Resource is compliant, taking no action")
