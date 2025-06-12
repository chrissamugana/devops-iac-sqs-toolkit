import boto3
import sys
import json
from botocore.exceptions import ClientError
from typing import List, Dict, Optional

def get_queue_message_count(queue_name: str, sqs_client) -> Optional[int]:
    try:
        queue_url = sqs_client.get_queue_url(QueueName=queue_name)['QueueUrl']
        attrs = sqs_client.get_queue_attributes(
            QueueUrl=queue_url,
            AttributeNames=['ApproximateNumberOfMessages']
        )
        return int(attrs['Attributes']['ApproximateNumberOfMessages'])
    except ClientError as e:
        if e.response['Error']['Code'] == 'AWS.SimpleQueueService.NonExistentQueue':
            return None
        print(f"Error fetching queue '{queue_name}': {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Unexpected error for queue '{queue_name}': {e}", file=sys.stderr)
        return None

def get_queues_message_totals(queue_names: List[str]) -> Dict[str, object]:
    sqs = boto3.client('sqs', region_name='eu-west-2')
    results = {}

    for queue_name in queue_names:
        count = get_queue_message_count(queue_name, sqs)
        if count is not None:
            results[queue_name] = count
        else:
            print(f"Warning: Unable to retrieve message count for queue '{queue_name}'", file=sys.stderr)

        dlq_name = f"{queue_name}-dlq"
        dlq_count = get_queue_message_count(dlq_name, sqs)
        results[dlq_name] = dlq_count if dlq_count is not None else "Not found"

    return results

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Retrieve message counts for specified SQS queues and their dead-letter queues."
    )
    parser.add_argument("queues", nargs="+", help="Queue names to check")
    parser.add_argument("--json", action="store_true", help="Output results in JSON format")

    args = parser.parse_args()
    totals = get_queues_message_totals(args.queues)

    if args.json:
        print(json.dumps(totals, indent=2))
    else:
        for queue, count in totals.items():
            print(f"{queue}: {count}")
