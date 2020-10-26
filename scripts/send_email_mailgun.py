import os
import requests
import json

# from address we pass to our Mail object, edit with your name
FROM_EMAIL = "OMM Ticketing <ticketing@orchestra.sg>"

# update to your dynamic template id from the UI
TEMPLATE_ID = os.environ.get("TEMPLATE_ID")

TO_EMAILS = []


def SendDynamic(ticket_id, email_address):
    """Send a dynamic email to a list of email addresses

    :returns API response code
    :raises Exception e: raises an exception"""
    dynamic_template_data = {
        "ticket_id": ticket_id,
        "short_ticket_id": ticket_id[:6].upper(),
    }
    # create our sendgrid client object, pass it our key, then send and return our response objects
    try:
        response = requests.post(
            "https://api.mailgun.net/v3/mg.orchestra.sg/messages",
            auth=("api", os.environ.get("MAILGUN_API_KEY")),
            data={
                "from": FROM_EMAIL,
                "to": email_address,
                "subject": f"Your Ticket for OMM Restarts! #{dynamic_template_data['short_ticket_id']}",
                "template": TEMPLATE_ID,
                "h:X-Mailgun-Variables": json.dumps(dynamic_template_data),
                "o:tag": "omm_pilot",
            },
        )
        print(f"Response code: {response.status_code}")
        print(f"Response headers: {response.headers}")
        print("Dynamic Messages Sent!")
    except Exception as e:
        print("Error: {0}".format(e))

    return str(response.status_code)


if __name__ == "__main__":
    count = 0
    for item in TO_EMAILS:
        count += 1
        SendDynamic(item[0], item[1])
        print(f"Sent {count}")
