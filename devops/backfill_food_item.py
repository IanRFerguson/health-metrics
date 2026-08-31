import hashlib
from dataclasses import dataclass, field
from datetime import datetime

import click
from google.cloud import bigquery

#####

PROJECT_ID = "ian-is-online"
DATASET_ID = "health"
TABLE_ID = "food_diary_backfill"


@dataclass
class FoodItem:
    """
    Represents a food item for backfilling into the food diary.

    Args:
        name (str): The name of the food item.
        target_date (datetime): The date for which the food item is being backfilled.
        target_time_of_day (str): The time of day for the food item (e.g., "morning", "afternoon", "evening", "late-night").
    """

    id: str = field(init=False)  # This gets generated in the post_init method
    food_item: str
    target_date: datetime
    target_time_of_day: str

    def __post_init__(self):
        # Generate a unique ID for the food item based on its name and target date
        self.id = hashlib.md5(
            f"{self.food_item}-{self.target_date}".encode("utf-8")
        ).hexdigest()

        self.target_date = self.target_date.strftime(
            "%Y-%m-%d"
        )  # Format the date as a string

        # Infer the time of day based on the provided string
        self.target_time_of_day = self.infer_time_of_day(self.target_time_of_day)

    def infer_time_of_day(self, time_of_day: str) -> str:
        """
        Infer the time of day based on the provided string. This method maps common
        time-of-day strings to a standardized format.
        """

        match time_of_day.lower():
            case "morning":
                output = "00-MORNING"
            case "afternoon":
                output = "01-AFTERNOON"
            case "evening":
                output = "02-EVENING"
            case "late-night":
                output = "03-LATE-NIGHT"
            case _:
                raise ValueError(
                    f"Invalid time of day: {time_of_day}. Must be one of: morning, afternoon, evening, late-night."
                )
        return output


def write_to_bigquery(client: bigquery.Client, data: list[dict]):
    """
    Write a list of dictionaries to a BigQuery table.

    Args:
        client (bigquery.Client): The BigQuery client.
        data (list[dict]): A list of dictionaries representing the rows to be inserted.
    """

    table_ref = client.dataset(DATASET_ID).table(TABLE_ID)
    errors = client.insert_rows_json(table_ref, data)

    if errors:
        raise RuntimeError(f"Failed to insert rows into BigQuery: {errors}")


@click.command()
@click.argument("name", type=str)
@click.option(
    "--target-date",
    "-d",
    type=click.DateTime(formats=["%Y-%m-%d"]),
    help="Target date for backfill",
)
@click.option(
    "--time-of-day",
    "-t",
    type=click.Choice(
        ["morning", "afternoon", "evening", "late-night"], case_sensitive=False
    ),
    help="Target time of day for backfill",
)
def cli(name: str, target_date: str, time_of_day: str):
    """
    Backfill a food item into the food diary.

    Args:
        name (str): The name of the food item.
        target_date (str): The target date for backfill in YYYY-MM-DD format.
        time_of_day (str): The target time of day for backfill (e.g., "morning", "afternoon", "evening", "late-night").
    """

    click.echo(f"Backfilling food item `{name}` on target date {target_date}")

    food_item = FoodItem(
        food_item=name,
        target_date=target_date,
        target_time_of_day=time_of_day,
    )
    write_to_bigquery(
        client=bigquery.Client(project=PROJECT_ID),
        data=[
            {
                **food_item.__dict__,
                "added_at": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            }
        ],
    )
    click.echo("✅ Successfully backfilled")


#####

if __name__ == "__main__":
    cli()
