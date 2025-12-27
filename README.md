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
    * Fitness events (e.g., strength training)
* **Strava API**