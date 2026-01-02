# Getting Healthy
In an effort to improve my health and fitness, I'm making a concerted effort to centralize and analyze my food intake, exercise, and activity levels. This repo pulls data from the necessary sources, transforms and combines it with `dbt`, and plots it for analysis.

## Data Sources
* **Self-reported food journal (sent via SMS)**
* **Apple Health API**
  * Key metrics
    * Daily ring status
    * Daily steps
    * Weight
    * Blood pressure
    * Fitness events (e.g., runs, walks, strength training)

## Project Structure

| Directory | Usage                                                                                                       |
| --------- | ----------------------------------------------------------------------------------------------------------- |
| `app`     | This directory includes the full-stack web application that services the webhook and the application itself |
| `common`  | These are shared bits of code that are used throughout the project (e.g., the common `logger`)              |
| `devops`  | This is where we write the Dockerfiles, cloud build YAMLs, and other bits of deployment code                |
| `infra`   | All of the relevant Terraform is written here (the state is written to GCS)                                 |
| `src`     | The data pipeline itself is written here, including the load from GCS to BigQuery and the analytical `dbt`  |

### Web Server
The full-stack application serves two important roles:
1. It defines the webhook that writes the response data to Google Cloud Storage
2. It runs the web application that hosts the summary metrics, plots, analytics, etc.


### Data Pipeline
The data pipeline is fairly straightforward - after flat files are written to GCS (by the `Health Auto Export` mobile application), the pipeline reads them into memory and writes them back to BigQuery.

These destination BigQuery tables are the source layer of the `dbt` project - see [the dbt README](./src/analytics/README.md) for more information.