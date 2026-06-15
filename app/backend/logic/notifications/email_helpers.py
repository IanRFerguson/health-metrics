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
    sections = "".join(
        f'<div class="section">{summary}</div>' for _, summary in summaries.items()
    )

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {{
      margin: 0;
      padding: 0;
      background-color: #f4f6f8;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
      color: #2d3748;
    }}
    .wrapper {{
      max-width: 640px;
      margin: 32px auto;
      background: #ffffff;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 2px 12px rgba(0,0,0,0.08);
    }}
    .header {{
      background: linear-gradient(135deg, #2f855a 0%, #276749 100%);
      padding: 36px 40px 28px;
    }}
    .header h1 {{
      margin: 0;
      color: #ffffff;
      font-size: 24px;
      font-weight: 700;
      letter-spacing: -0.3px;
    }}
    .header p {{
      margin: 6px 0 0;
      color: rgba(255,255,255,0.75);
      font-size: 14px;
    }}
    .body {{
      padding: 32px 40px 24px;
    }}
    .section {{
      border-left: 4px solid #48bb78;
      padding: 0 0 0 16px;
      margin-bottom: 28px;
    }}
    .section:last-child {{
      margin-bottom: 0;
    }}
    .section h2 {{
      margin: 0 0 10px;
      font-size: 17px;
      font-weight: 600;
      color: #276749;
    }}
    .section p {{
      margin: 0 0 10px;
      font-size: 14px;
      line-height: 1.65;
      color: #4a5568;
    }}
    .section p:last-child {{
      margin-bottom: 0;
    }}
    .section ul, .section ol {{
      margin: 0 0 10px;
      padding-left: 20px;
      font-size: 14px;
      line-height: 1.65;
      color: #4a5568;
    }}
    .footer {{
      border-top: 1px solid #e2e8f0;
      padding: 20px 40px;
      font-size: 12px;
      color: #a0aec0;
      text-align: center;
    }}
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="header">
      <h1>Weekly Health Summary</h1>
      <p>Your personalized health insights, powered by Gemini</p>
    </div>
    <div class="body">
      {sections}
    </div>
    <div class="footer">
      Generated automatically &mdash; health@ianferguson.dev
    </div>
  </div>
</body>
</html>"""
