"""Create the Redpanda topic configured in producer/.env."""

from kafka import KafkaAdminClient
from kafka.admin import NewTopic
from kafka.errors import TopicAlreadyExistsError

from config import load_redpanda_config


def main():
    config = load_redpanda_config()

    admin = KafkaAdminClient(
        bootstrap_servers=config["bootstrap_servers"],
        security_protocol=config["security_protocol"],
        sasl_mechanism=config["sasl_mechanism"],
        sasl_plain_username=config["username"],
        sasl_plain_password=config["password"],
        client_id="peru-flight-topic-admin",
    )

    try:
        topic = NewTopic(
            name=config["topic"],
            num_partitions=config["topic_partitions"],
            replication_factor=-1,
        )
        admin.create_topics([topic])
        print(f'Topic created: {config["topic"]}')
    except TopicAlreadyExistsError:
        print(f'Topic already exists: {config["topic"]}')
    finally:
        admin.close()


if __name__ == "__main__":
    main()
