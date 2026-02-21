import resend

from common.logger import metrics_logger

#####


def send_email_notification(
    summaries: dict, to_email: str = "IANFERGUSONRVA@gmail.com"
) -> None:
    """
    Send an email notification with the provided summaries.

    Args:
        summaries (dict): A dictionary containing summaries for each category.
        to_email (str): The recipient's email address. Defaults to "IANFERGUSONRVA@gmail.com".
    """

    html = generate_html_body(summaries)

    params: resend.EmailParams = {
        "from": "health@ianferguson.dev",
        "to": [to_email],
        "subject": "Your Weekly Health Summary",
        "html": html,
    }

    try:
        resend.Emails.send(params)
        metrics_logger.info(f"Email notification sent to {to_email}")
    except Exception as e:
        metrics_logger.error(f"Error sending email: {e}")
        raise e


def generate_html_body(summaries: dict) -> str:
    """
    Generate the HTML body for the email notification.

    Args:
        summaries (dict): A dictionary containing summaries for each category.

    Returns:
        str: The HTML content for the email.
    """

    html = "<h1>Weekly Health Summary</h1>"
    for _, summary in summaries.items():
        html += summary  # Assuming the summary is already formatted in HTML by Gemini

    return html
