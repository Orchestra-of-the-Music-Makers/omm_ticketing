import os
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, Email

# from address we pass to our Mail object, edit with your name
FROM_EMAIL = Email("ticketing@orchestra.sg", "OMM Ticketing")

# update to your dynamic template id from the UI
TEMPLATE_ID = "d-a9eda0dc7c5d483789fff18191da259e"

# list of emails and preheader names, update with yours
TO_EMAILS = []


def SendDynamic(ticket_id, email_address):
    """Send a dynamic email to a list of email addresses

    :returns API response code
    :raises Exception e: raises an exception"""
    # create Mail object and populate
    message = Mail(from_email=FROM_EMAIL, to_emails=[email_address])
    # pass custom values for our HTML placeholders
    message.dynamic_template_data = {
        "ticket_id": ticket_id,
        "short_ticket_id": ticket_id[:6].upper(),
    }
    message.template_id = TEMPLATE_ID
    # create our sendgrid client object, pass it our key, then send and return our response objects
    try:
        sg = SendGridAPIClient(os.environ.get("SENDGRID_API_KEY"))
        response = sg.send(message)
        code, body, headers = response.status_code, response.body, response.headers
        print(f"Response code: {code}")
        print(f"Response headers: {headers}")
        print(f"Response body: {body}")
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
