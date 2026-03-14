import logging

import click
import polars as pl
from google.cloud.exceptions import NotFound
from google.genai import types

from common.logger import metrics_logger
from src.scores.constants import (
    GEMINI_CLIENT,
    GEMINI_MODEL,
    INPUT_TABLE,
    KLONDIKE_CONNECTOR,
    LINE_ITEMS_TO_SCORE_QUERY,
    OUTPUT_TABLE,
    PROMPT,
)

#####


# Suppress Klondike warnings here
logging.getLogger("klondike").setLevel(logging.WARNING)

food_score_schema = types.Schema(
    type="OBJECT",
    properties={"score": types.Schema(type="NUMBER")},
    required=["score"],
)


@click.command()
@click.option(
    "--full-refresh", is_flag=True, help="Whether to perform a full refresh of the data"
)
def cli(full_refresh: bool = False):
    metrics_logger.info("Starting scoring process...")

    if full_refresh:
        metrics_logger.info(
            "Performing full refresh. Deleting existing data from output table..."
        )
        KLONDIKE_CONNECTOR.query(f"DROP TABLE {OUTPUT_TABLE};")

    try:
        # Read unscored data from BigQuery
        df = KLONDIKE_CONNECTOR.query(LINE_ITEMS_TO_SCORE_QUERY)
    except NotFound:
        df = KLONDIKE_CONNECTOR.query("SELECT * FROM {table}".format(table=INPUT_TABLE))

    if df.is_empty():
        metrics_logger.info("No new line items to score. Exiting.")
        return

    # Process each row with Gemini
    scores = []
    for _, row in enumerate(df.iter_rows()):
        metrics_logger.debug(row)

        # Get the score from Gemini
        response = GEMINI_CLIENT.models.generate_content(
            model=GEMINI_MODEL,
            contents=[
                PROMPT,
                row[1],
            ],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=food_score_schema,
            ),
        )

        # Extract the score from the response
        score = response.parsed.get("score", 0.0)
        metrics_logger.info(f"Scored {row[1].strip().upper()} with score: {score}")

        # Update the DataFrame with the new score
        scores.append(score)

    # Add the scores to the DataFrame and cast to float
    df = df.with_columns(pl.Series(name="score", values=scores, dtype=pl.Float64))

    # Write the processed data back to BigQuery
    metrics_logger.info(f"Writing scored data back to {OUTPUT_TABLE}...")
    KLONDIKE_CONNECTOR.write_dataframe(
        df=df, table_name=OUTPUT_TABLE, if_exists="append"
    )
    metrics_logger.info("Success!")


#####

if __name__ == "__main__":
    cli()
