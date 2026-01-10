import { useState, useEffect } from "react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

function WeeklyStats() {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

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
                        day: 'numeric'
                    }),
                    total_exercise_minutes: Number(item.total_exercise_minutes) || 0
                }));

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

    return (
        <div>
            <div style={{ marginBottom: '10px', fontSize: '12px', color: '#999' }}>
                Data points: {data.length} | Sample: {data[0]?.total_exercise_minutes || 'N/A'}
            </div>
            <ResponsiveContainer width="100%" height={400}>
                <LineChart data={data}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="start_date" />
                    <YAxis domain={['auto', 'auto']} />
                    <Tooltip />
                    <Legend />
                    <Line type="monotone" dataKey="total_exercise_minutes" stroke="#8884d8" name="Exercise Minutes" strokeWidth={2} dot={{ r: 4 }} />
                </LineChart>
            </ResponsiveContainer>
        </div>
    );
}

export default WeeklyStats;