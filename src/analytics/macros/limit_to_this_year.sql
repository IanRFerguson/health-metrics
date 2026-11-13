{% macro limit_records_to_current_year(column_name) %}
    EXTRACT(YEAR FROM {{ column_name }}) = EXTRACT(YEAR FROM CURRENT_DATE())
{% endmacro %}