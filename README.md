
This project contains two main components:

---

## Part 1: Terraform Module `sqs_queues`

This module creates AWS SQS queues and their dead-letter queues, along with IAM policies for producing and consuming messages.

- Creates main queues and their DLQs (`queue_name` and `queue_name-dlq`)
- Creates IAM policies for:
  - Consuming (ReceiveMessage, DeleteMessage) on all queues
  - Writing (SendMessage) on main queues only
- Optionally creates IAM roles attached to these policies

See the detailed module README in [`sqs_queues/README.md`](sqs_queues/README.md).

---

## Part 2: Python Script `sqs_queues.py`

Fetches and displays the approximate number of messages in specified SQS queues and their DLQs.

### Usage

#### CLI

```bash
python sqs_queues.py priority-10 priority-100 [--json]
