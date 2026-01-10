import { useState, useEffect } from "react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

const CustomTooltip = ({ active, payload, label }) => {
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
                <p style={{ margin: '0 0 5px 0', fontWeight: 'bold' }}>Week of {label}</p>
                <p style={{ margin: 0, color: '#8884d8' }}>
                    Exercise: {payload[0].value} minutes
                </p>
                <p style={{ margin: 0, color: '#8884d8' }}>Weight: {data.avg_weight_lb} lbs</p>
                <p style={{ margin: 0, color: '#8884d8' }}>Miles Run: {data.total_miles_run}</p>
                <p style={{ margin: 0, color: '#8884d8' }}>Mileage Goal: {data.total_miles_run >= 10 ? "✅" : "❌"}</p>

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

function WeeklyStats() {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [selectedMetric, setSelectedMetric] = useState('total_exercise_minutes');

    const metrics = [
        { key: 'total_exercise_minutes', label: 'Exercise Minutes', color: '#8884d8' },
        { key: 'avg_weight_lb', label: 'Average Weight (lbs)', color: '#82ca9d' },
        { key: 'total_miles_run', label: 'Miles Run', color: '#ffc658' },
        // Add more metrics as needed
    ];

    useEffect(() => {
        const fetchWeeklyStats = async () => {
            try {
                const response = await fetch('/api/weekly-stats');
                if (!response.ok) throw new Error('Failed to fetch weekly stats');
                const result = await response.json();

                // Format the data for the chart
                const formattedData = result.map(item => ({
                    ...item,
                    start_date: new Date(item.start_date).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric'
                    }),
                    total_exercise_minutes: Number(item.total_exercise_minutes) || 0,
                    avg_weight_lb: Number(item.avg_weight_lb || "Missing"),
                }))

                console.log('Raw result:', result);
                console.log('Formatted data:', formattedData);
                setData(formattedData);
            } catch (err) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };

        fetchWeeklyStats();
    }, []);

    if (loading) return <div>Loading...</div>;
    if (error) return <div>Error: {error}</div>;

    const currentMetric = metrics.find(m => m.key === selectedMetric);

    return (
        <div style={{ width: '100%', maxWidth: '100%', margin: '0 auto', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <div style={{ marginBottom: '20px', display: 'flex', gap: '10px', alignItems: 'center' }}>
                <label htmlFor="metric-select" style={{ fontWeight: 'bold' }}>Metric:</label>
                <select
                    id="metric-select"
                    value={selectedMetric}
                    onChange={(e) => setSelectedMetric(e.target.value)}
                    style={{
                        padding: '8px 12px',
                        fontSize: '14px',
                        borderRadius: '4px',
                        border: '1px solid #ccc',
                        cursor: 'pointer'
                    }}
                >
                    {metrics.map(metric => (
                        <option key={metric.key} value={metric.key}>
                            {metric.label}
                        </option>
                    ))}
                </select>
            </div>
            <ResponsiveContainer width="90%" height={500}>
                <LineChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="start_date" />
                    <YAxis domain={['auto', 'auto']} />
                    <Tooltip content={<CustomTooltip />} />
                    <Legend />
                    <Line
                        type="monotone"
                        dataKey={selectedMetric}
                        stroke={currentMetric.color}
                        name={currentMetric.label}
                        strokeWidth={2}
                        dot={{ r: 4 }}
                    />
                </LineChart>
            </ResponsiveContainer>
        </div>
    );
}

export default WeeklyStats;