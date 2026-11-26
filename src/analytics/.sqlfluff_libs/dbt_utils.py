"""Stubs so sqlfluff's jinja templater can render dbt_utils calls."""


def star(*args, **kwargs):
    return "*"


def generate_surrogate_key(*args, **kwargs):
    return "surrogate_key"
