import os

import requests

#####


def main():
    resp = requests.post(
        "http://localhost:5000/notify/email-summaries",
        json={"trigger_key": os.getenv("EMAIL_SUMMARIES_TRIGGER_KEY")},
    )
    print(resp.status_code)


#####

if __name__ == "__main__":
    main()
