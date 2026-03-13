import logging
import os

from google import genai
from klondike.gcp.bigquery import BigQueryConnector

from common.logger import metrics_logger

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

INPUT_TABLE = "dbt_health_metrics_staging.stg__01__food_intake"
OUTPUT_TABLE = "dbt_health_metrics_staging.stg__02__food_intake_scored"

PROMPT = """
Score the overall healthiness of the following food intake on a scale of 1.0 to 10.0, where 1.0 is 
very unhealthy and 10.0 is very healthy. 

Consider factors such as nutritional value and contribution to my weight loss goals.

Some reminders:
* Quest protein bars have 20g sugar and 1g of sugar (these are the only protein bars I eat, unless the brand is otherwise specified)
* Fairlife chocolate milk 12g sugar and 13g of protein
* Fairlife protein shakes have 42g protein and 7g of sugar
* I only use olive oil (no butter or other oils)
* I am trying to lose weight and build muscle, so I want to prioritize high protein and low sugar foods.
"""

with open("src/scores/line_items_to_score.sql", "r") as f:
    LINE_ITEMS_TO_SCORE_QUERY = f.read().format(
        INPUT_TABLE=INPUT_TABLE,
        OUTPUT_TABLE=OUTPUT_TABLE,
    )
    metrics_logger.debug(LINE_ITEMS_TO_SCORE_QUERY)
