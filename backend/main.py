import time
from decimal import Decimal
from boto3.dynamodb.conditions import Key
import boto3
import json
import os

print("Loading function")

dynamo = boto3.resource("dynamodb").Table("ticketing")
SECRET_KEY = os.environ["SECRET_KEY"]
ALLOWED_ORIGINS = os.environ["ALLOWED_ORIGINS"]


def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError


def respond(err, res=None):
    return {
        "statusCode": "400" if err else "200",
        "body": str(err) if err else json.dumps(res, default=decimal_default),
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": ALLOWED_ORIGINS,
        },
    }


def lambda_handler(event, context):
    path = event["path"].split("/")[1:]

    if len(path) != 2:
        return respond(ValueError(f"Malformed path: {path}"))

    verb = event["httpMethod"]
    ticket_id = path[0]
    action = path[1]

    response = dynamo.query(KeyConditionExpression=Key("pk").eq(ticket_id))

    if response["Count"] == 0:
        return respond(ValueError(f"Invalid ticket_id {ticket_id}"))

    ticket = response["Items"][0]
    ticket_scanned_at = ticket.get("scanned_at")

    # Query dynamo DB for event based on ticket ID
    event_id = ticket.get("sk").split("-")[1]
    event_response = dynamo.query(KeyConditionExpression=Key("pk").eq("example_event_name"))
    if event_response["Count"] == 0:
        return respond(ValueError(f"Invalid event_id {event_id}"))

    event = event_response["Items"][0]

    # POST /<ticket_id>/submit
    if verb == "POST" and action == "submit":
        try:
            secret_key = json.loads(event["body"])["secret_key"]
        except:
            return respond(ValueError(f"Invalid request body"))

        if secret_key != SECRET_KEY:
            return respond(ValueError(f"Invalid secret key"))

        if ticket_scanned_at is not None:
            return respond(ValueError(f"Ticket already scanned"))

        dynamo.update_item(
            Key={"ticket_id": ticket_id},
            UpdateExpression="set scanned_at = :val",
            ExpressionAttributeValues={":val": int(time.time())},
        )
        return respond(None, {"status": "success"})

    # GET /<ticket_id>/status
    elif verb == "GET" and action == "status":
        print(f"GET_STATUS: {ticket_id}")
        dynamo.update_item(
            Key={"ticket_id": ticket_id},
            UpdateExpression="add scanned_count :val",
            ExpressionAttributeValues={":val": 1},
        )
        return respond(None, ticket)

    # GET /<ticket_id>/data
    elif verb == "GET" and action == "data":
        return respond(None, {**event, **ticket})


    return respond(ValueError(f"Unsupported action"))
