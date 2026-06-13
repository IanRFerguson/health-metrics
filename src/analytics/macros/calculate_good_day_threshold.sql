{% macro calculate_good_day_threshold(fields, cutoff_percentile=0.80, column_name="is_good_day") %}
    {%- set total_thresholds_met = [] -%}
    {%- set total_fields = fields | length -%}
    
    {% for field in fields %}
        {% set _ = total_thresholds_met.append("CAST(" ~ field ~ " AS INT64)") %}
    {% endfor %}
    
    {%- set total_thresholds_met_expr = total_thresholds_met | join(" + ") -%}
    
    CASE
        WHEN {{ total_thresholds_met_expr }} >= ({{ total_fields }} * {{ cutoff_percentile }}) THEN TRUE
        ELSE FALSE
    END AS {{ column_name }}

{% endmacro %}