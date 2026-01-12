import { useState, useEffect } from "react";
import { ResponsiveContainer } from 'recharts';

// We've broken these into individual components for maximum customizability
import ExercisePlot from "./plots/Exercise";
import WeightPlot from "./plots/Weight";
import MilesPlot from "./plots/Miles";

// Cache duration in milliseconds (5 minutes)
const CACHE_DURATION = 5 * 60 * 1000;

function WeeklyStats() {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [selectedMetric, setSelectedMetric] = useState('total_exercise_minutes');
    const [dailyStats, setDailyStats] = useState(false);

    const metrics = [
        { key: 'total_exercise_minutes', plot_component: ExercisePlot, label: 'Total Exercise Minutes' },
        { key: 'avg_weight_lb', plot_component: WeightPlot, label: 'Weight' },
        { key: 'total_miles_run', plot_component: MilesPlot, label: 'Miles Run' },
    ];

    useEffect(() => {
        const fetchStats = async () => {
            setLoading(true);
            try {
                const endpoint = dailyStats ? '/api/daily-stats' : '/api/weekly-stats';
                const cacheKey = `stats_${dailyStats ? 'daily' : 'weekly'}`;

                // Check cache first
                const cached = sessionStorage.getItem(cacheKey);
                const cacheTimestamp = sessionStorage.getItem(`${cacheKey}_timestamp`);

                if (cached && cacheTimestamp) {
                    const age = Date.now() - parseInt(cacheTimestamp);
                    if (age < CACHE_DURATION) {
                        console.log(`Using cached ${dailyStats ? 'daily' : 'weekly'} data (${Math.round(age / 1000)}s old)`);
                        setData(JSON.parse(cached));
                        setLoading(false);
                        return;
                    }
                }

                // Fetch fresh data
                const response = await fetch(endpoint);
                if (!response.ok) throw new Error(`Failed to fetch ${dailyStats ? 'daily' : 'weekly'} stats`);
                const result = await response.json();

                console.log('Raw API result:', result);

                // Format the data for the chart
                const formattedData = result.map(item => {
                    // The API returns dates in RFC format like "Mon, 05 Jan 2026 00:00:00 GMT"
                    // Use UTC methods to avoid timezone conversion
                    const date = new Date(item.start_date);
                    const formattedDate = date.toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                        timeZone: 'UTC'
                    });

                    return {
                        ...item,
                        start_date: formattedDate,
                        total_exercise_minutes: Number(item.total_exercise_minutes) || 0,
                        avg_weight_lb: Number(item.avg_weight_lb || "Missing"),
                    };
                })

                console.log('Fetched fresh data:', formattedData);

                // Cache the formatted data
                sessionStorage.setItem(cacheKey, JSON.stringify(formattedData));
                sessionStorage.setItem(`${cacheKey}_timestamp`, Date.now().toString());

                setData(formattedData);
            } catch (err) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };

        fetchStats();
    }, [dailyStats]);

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
            <div style={{ marginTop: '20px', display: 'flex', gap: '10px', alignItems: 'center' }}>
                <label htmlFor="daily-toggle" style={{ fontWeight: 'bold' }}>Daily Stats:</label>
                <input
                    type="checkbox"
                    id="daily-toggle"
                    checked={dailyStats}
                    onChange={(e) => setDailyStats(e.target.checked)}
                    style={{
                        width: '18px',
                        height: '18px',
                        cursor: 'pointer'
                    }}
                />
            </div>
        </div>
    );
}

export default WeeklyStats;