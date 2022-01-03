from sys import argv


from boto3 import client


def update_configuration(configuration):
    config = configuration.copy()
    config["Automatic"] = True
    config["MaximumAutomaticAttempts"] = 1
    config["RetryAttemptSeconds"] = 60
    return config


def run(rule_name):
    config = client("config")

    configurations = config.describe_remediation_configurations(
        ConfigRuleNames=[
            rule_name,
        ]
    )["RemediationConfigurations"]
    auto_configurations = [
        update_configuration(configuration) for configuration in configurations
    ]
    config.put_remediation_configurations(RemediationConfigurations=auto_configurations)


if __name__ == "__main__":
    run(argv[1])
