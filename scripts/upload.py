import boto3

dynamo = boto3.resource("dynamodb").Table("ticketing-table")

ticket_list = []

for i in ticket_list:
    response = dynamo.put_item(
        Item={"ticket_id": i[0], "seat_id": i[1], "start_time": i[2]}
    )
    print(response)
