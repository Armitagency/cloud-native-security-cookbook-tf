import sys

from google.cloud import securitycenter

client = securitycenter.SecurityCenterClient.from_service_account_json(
    "auth/scc_admin.json"
)


def run(org_id, project_id, topic_id):
    org_name = f"organizations/{org_id}"

    created_notification_config = client.create_notification_config(
        request={
            "parent": org_name,
            "config_id": f"{project_id}-scc",
            "notification_config": {
                "description": "Notification for active findings",
                "pubsub_topic": topic_id,
                "streaming_config": {"filter": 'state = "ACTIVE"'},
            },
        }
    )

    print(created_notification_config)


if __name__ == "__main__":
    run(sys.argv[1], sys.argv[2], sys.argv[3])
