{% macro parse_time_of_day(column_name) %}
    CASE
        WHEN EXTRACT(HOUR FROM {{ column_name}}) < 12
            THEN '00-MORNING'
        WHEN EXTRACT(HOUR FROM {{ column_name}}) BETWEEN 12 AND 17
            THEN '01-AFTERNOON'
        WHEN EXTRACT(HOUR FROM {{ column_name}}) BETWEEN 17 AND 20
            THEN '02-EVENING'
        WHEN EXTRACT(HOUR FROM {{ column_name}}) > 20
            THEN '03-LATE-NIGHT'
        ELSE NULL
    END
{% endmacro %}