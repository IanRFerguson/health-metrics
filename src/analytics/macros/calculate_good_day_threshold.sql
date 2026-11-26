{#
    Flags a day as "good" when it meets at least `min_thresholds_met` out of
    all `fields`, scaled to the fields that could actually be evaluated.

    A NULL field means "no data" and is left out of the evaluation rather
    than counted as a miss. The bar is kept proportional: with 4 of 6
    required, a day with only 3 evaluable fields needs 2, with 4 it needs 3,
    and with 5 it needs 4 (always rounding up).

    Returns NULL when fewer than `min_thresholds_evaluated` fields have data,
    since there isn't enough to judge the day.

    Integer math (met * total >= evaluated * required) avoids float rounding.
#}
{% macro calculate_good_day_threshold(
    fields,
    min_thresholds_met,
    min_thresholds_evaluated=3,
    column_name="is_good_day"
) %}
    {%- set total_fields = fields | length -%}
    {%- if min_thresholds_met > total_fields or min_thresholds_evaluated > total_fields -%}
        {{ exceptions.raise_compiler_error(
            "min_thresholds_met (" ~ min_thresholds_met ~ ") and min_thresholds_evaluated ("
            ~ min_thresholds_evaluated ~ ") can't exceed the number of fields (" ~ total_fields ~ ")"
        ) }}
    {%- endif -%}

    {%- set met = [] -%}
    {%- set evaluated = [] -%}
    {%- for field in fields -%}
        {%- do met.append("COALESCE(CAST(" ~ field ~ " AS INT64), 0)") -%}
        {%- do evaluated.append("IF(" ~ field ~ " IS NULL, 0, 1)") -%}
    {%- endfor -%}

    {%- set met_expr = "(" ~ met | join(" + ") ~ ")" -%}
    {%- set evaluated_expr = "(" ~ evaluated | join(" + ") ~ ")" -%}

    CASE
        WHEN {{ evaluated_expr }} >= {{ min_thresholds_evaluated }}
            THEN {{ met_expr }} * {{ total_fields }} >= {{ evaluated_expr }} * {{ min_thresholds_met }}
    END AS {{ column_name }}
{% endmacro %}
