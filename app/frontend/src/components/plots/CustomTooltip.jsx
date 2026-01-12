const CustomTooltip = ({ active, payload, label, isDaily = false }) => {
    if (active && payload && payload.length) {
        const data = payload[0].payload; // Contains all fields from the data object
        return (
            <div style={{
                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                padding: '10px',
                border: '1px solid #ccc',
                borderRadius: '4px',
                color: '#fff'
            }}>
                <p style={{ margin: '0 0 5px 0', fontWeight: 'bold' }}>{isDaily ? `${label}` : `Week of ${label}`}</p>
                <p style={{ margin: 0, color: '#8884d8' }}>
                    Exercise: {payload[0].value.toFixed(2)} minutes
                </p>

                {/* Debug: see all available fields */}
                {/* <details style={{ marginTop: '5px', fontSize: '10px' }}>
                    <summary>Available fields</summary>
                    <pre>{JSON.stringify(data, null, 2)}</pre>
                </details> */}
            </div>
        );
    }
    return null;
};

export default CustomTooltip;