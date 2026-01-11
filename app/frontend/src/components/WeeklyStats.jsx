import { useState, useEffect } from "react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

// We've broken these into individual components for maximum customizability
import ExercisePlot from "./plots/Exercise";
import WeightPlot from "./plots/Weight";
import MilesPlot from "./plots/Miles";

function WeeklyStats() {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [selectedMetric, setSelectedMetric] = useState('total_exercise_minutes');

    const metrics = [
        { key: 'total_exercise_minutes', plot_component: ExercisePlot, label: 'Total Exercise Minutes' },
        { key: 'avg_weight_lb', plot_component: WeightPlot, label: 'Average Weight (lbs)' },
        { key: 'total_miles_run', plot_component: MilesPlot, label: 'Miles Run' },
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
                {currentMetric.plot_component({ data })}
            </ResponsiveContainer>
        </div>
    );
}

export default WeeklyStats;