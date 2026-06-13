{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    
    {# If the model is in the "marts" directory, we want to omit the schema prefix #}
    {%- set omit_schema_prefix = node.path.startswith("marts") and target.name == "cloud" -%}
    
    {%- if custom_schema_name is none -%}

        {{ default_schema }}

    {%- elif omit_schema_prefix -%}

        {{ custom_schema_name | trim }}

    {%- else -%}

        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- endif -%}

{%- endmacro %}