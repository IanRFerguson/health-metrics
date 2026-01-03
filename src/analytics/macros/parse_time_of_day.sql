{% macro parse_time_of_day(column_name) %}
    CASE
        WHEN EXTRACT(HOUR FROM {{ column_name}}) < 12
            THEN 'MORNING'
        WHEN EXTRACT(HOUR FROM {{ column_name}}) BETWEEN 12 AND 17
            THEN 'AFTERNOON'
        WHEN EXTRACT(HOUR FROM {{ column_name}}) BETWEEN 17 AND 20
            THEN 'EVENING'
        WHEN EXTRACT(HOUR FROM {{ column_name}}) > 20
            THEN 'LATE NIGHT'
        ELSE NULL
    END
{% endmacro %}