# FIXME: Figure this out, but for now we'll import the modules here
# rather than at the top of the model
import bigframes.pandas as bpd
from bigframes.ml import llm


def model(dbt, session):
    dbt.config(
        packages=["bigframes", "scikit-learn"],
        submission_method="serverless",
        enabled=False,
    )

    # Materialize the data in memory as a DataFrame
    df = dbt.ref("stg__00__food_journal").to_pandas()

    # NOTE: The connection is managed via Terraform - see the infra/ folder
    gemini_model = llm.GeminiTextGenerator(
        model_name="gemini-1.5-flash",
        connection_name="ian-is-online.us-central1.gemini-connection",
    )

    # We ask Gemini to evaluate how healthy each food item is
    # Use the .ai.predict() or a similar mapping function
    df["rating"] = (
        "Please rate the 'healthiness' of each food item, with 10.0 being incredibly healthy and 0.0 being incredibly unhealthy: "
        + df["food_line_item"].astype(str)
    )

    # Run the predictions
    predictions = gemini_model.predict(df["rating"])

    return predictions
