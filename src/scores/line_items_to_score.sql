SELECT
    _it.surrogate_line_item_pk,
    _it.line_item,
    _it.n
FROM {INPUT_TABLE} as _it
LEFT JOIN {OUTPUT_TABLE} as _ot USING (surrogate_line_item_pk)
WHERE _ot.score IS NULL