{% macro format_pace_string(pace_in_seconds) -%}
    SAFE.FORMAT_TIME('%M:%S', TIME_ADD(TIME '00:00:00', INTERVAL {{ pace_in_seconds }} SECOND))
{%- endmacro %}