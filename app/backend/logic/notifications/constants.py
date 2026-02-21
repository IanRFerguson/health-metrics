import logging
import os

from google import genai
from google.cloud import storage
from klondike.gcp.bigquery import BigQueryConnector

#####

# Suppress Klondike warnings here
logging.getLogger("klondike").setLevel(logging.WARNING)

if os.environ.get("STAGE") == "dev":
    KLONDIKE_CONNECTOR = BigQueryConnector(
        app_creds=os.environ["GOOGLE_APPLICATION_CREDENTIALS"]
    )
else:
    KLONDIKE_CONNECTOR = BigQueryConnector(bypass_env_variable=True)

GEMINI_CLIENT = genai.Client()
GEMINI_MODEL = "gemini-2.0-flash"
STORAGE_CLIENT = storage.Client()

PROMPT = """
I'm going to give you two sets of data - daily health data from the last week and weekly summaries for the year. 
Highlight what's going well and what can be improved, and be as specific as possible when describing diet, exercise, and overall health trends.
Please structure the output in HTML so that it can be directly used in an email notification. 
You do not need to wrap the output in ```html``` tags, but please make sure to use appropriate HTML tags for formatting. 
Use <h2> tags for category headings and <p> tags for the summaries.
Please include the date ranges included in your analysis.

Some assumptions you can make:
* I am targeting a goal weight of 200 pounds.
* My goal is to run 10 miles per week.
* I subscribe to the 80/20 diet, so 80% of my diet should be healthy whole foods and 20% can be more indulgent foods.
* If there's a day with no food logs, assume that I took the day off from tracking (i.e., this is not an error in the data, but rather a conscious choice to not track that day).
"""
