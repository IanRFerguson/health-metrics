const CustomTooltip = ({ active, payload, label, isDaily = false, series = [], labelOverride = null, labelFormatter = null }) => {
    if (active && payload && payload.length) {
        const data = payload[0].payload;

        const formattedLabel = labelFormatter ? labelFormatter(label) : (isDaily ? `${label}` : `Week of ${label}`);
        const displayLabel = labelOverride !== null ? labelOverride : formattedLabel;

        return (
            <div style={{
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                padding: '10px',
                border: '1px solid #ccc',
                borderRadius: '4px',
                color: '#fff'
            }}>
                <p style={{ margin: '0 0 5px 0', fontWeight: 'bold' }}>{displayLabel}</p>
                {series.map(s => {
                    // Use the accessor if provided, otherwise, fall back to dataKey
                    const value = s.accessor ? s.accessor(data) : data[s.dataKey];
                    if (value === undefined || value === null) return null;

                    const displayValue = typeof value === 'number' ? value.toFixed(2) : value;
                    const unit = s.unit ? ` ${s.unit}` : '';

                    return (
                        <p key={s.label} style={{ margin: 0, color: s.color || '#8884d8' }}>
                            {s.label}: {displayValue}{unit}
                        </p>
                    );
                })}
            </div>
        );
    }
    return null;
};

export default CustomTooltip;