{% macro get_date_window(column_name, window_size=30) %}
    {{ column_name }} BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL {{ window_size }} DAY) AND CURRENT_DATE()
{% endmacro %}