import { useState, useEffect } from "react";
import { ResponsiveContainer } from 'recharts';

// We've broken these into individual components for maximum customizability
import MilesPlot from "./plots/Miles.jsx";
import WeightPlot from "./plots/Weight.jsx";
import WorkoutsPlot from "./plots/Workouts.jsx";
import StepCountPlot from "./plots/StepCount.jsx";


import { CACHE_DURATION_MS } from "../Constants.js";

function formatStandardData(apiResponseData) {
    // Validate input
    if (!Array.isArray(apiResponseData)) {
        console.warn('formatStandardData expected array but got:', typeof apiResponseData, apiResponseData);
        return [];
    }

    return apiResponseData.map(item => {
        if (!item || typeof item !== 'object') {
            console.warn('Invalid item in data array:', item);
            return item; // Return as-is if invalid
        }

        // The API returns dates in RFC format like "Mon, 05 Jan 2026 00:00:00 GMT"
        // Use UTC methods to avoid timezone conversion
        let formattedDate = item.start_date;
        if (item.start_date) {
            try {
                const date = new Date(item.start_date);
                if (!isNaN(date.getTime())) {
                    formattedDate = date.toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                        timeZone: 'UTC'
                    });
                }
            } catch (dateError) {
                console.warn('Date parsing error for:', item.start_date, dateError);
            }
        }

        return {
            ...item,
            start_date: formattedDate,
            total_exercise_minutes: Number(item.total_exercise_minutes) || 0,
            avg_weight_lb: Number(item.avg_weight_lb) || 0,
        };
    });
}

function formatWorkoutsData(apiResponse) {
    // Validate input
    if (!Array.isArray(apiResponse)) {
        console.warn('formatWorkoutsData expected array but got:', typeof apiResponse, apiResponse);
        return [];
    }

    return apiResponse.map(item => {
        if (!item || typeof item !== 'object') {
            console.warn('Invalid item in data array:', item);
            return item; // Return as-is if invalid
        }

        // The API returns dates in RFC format like "Mon, 05 Jan 2026 00:00:00 GMT"
        // Use UTC methods to avoid timezone conversion
        let formattedDate = item.target_date;
        if (item.target_date) {
            try {
                const date = new Date(item.target_date);
                if (!isNaN(date.getTime())) {
                    formattedDate = date.toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                        timeZone: 'UTC'
                    });
                }
            } catch (dateError) {
                console.warn('Date parsing error for:', item.target_date, dateError);
            }
        }

        // Convert workout_duration from string (HH:MM:SS or MM:SS) to minutes
        let durationMinutes = 0;
        if (item.workout_duration) {
            try {
                const parts = item.workout_duration.split(':');
                if (parts.length === 3) {
                    // HH:MM:SS format
                    durationMinutes = parseInt(parts[0]) * 60 + parseInt(parts[1]) + parseInt(parts[2]) / 60;
                } else if (parts.length === 2) {
                    // MM:SS format
                    durationMinutes = parseInt(parts[0]) + parseInt(parts[1]) / 60;
                }
            } catch (parseError) {
                console.warn('Duration parsing error for:', item.workout_duration, parseError);
            }
        }

        return {
            ...item,
            target_date: formattedDate,
            workout_count: Number(item.workout_count) || 0,
            workout_duration_minutes: durationMinutes,
            workout_duration_original: item.workout_duration,
        };
    });
}

function HealthMetrics() {
    // These state variables manage data fetching and UI state
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);
    const [selectedMetric, setSelectedMetric] = useState('total_miles_run');
    const [dailyStats, setDailyStats] = useState(true);

    // This array informs our dropdown (that builds the plot)
    const metrics = [
        { key: 'total_miles_run', plot_component: MilesPlot, label: 'Miles Run' },
        { key: 'avg_weight_lb', plot_component: WeightPlot, label: 'Weight' },
        { key: 'workouts', plot_component: WorkoutsPlot, label: 'Workouts', endpoint: '/api/workout-stats?daily={daily}', formatFn: formatWorkoutsData },
        { key: 'step_count', plot_component: StepCountPlot, label: 'Step Count' },
    ];

    // This is the value that's currently selected from the dropdown
    const currentMetric = metrics.find(m => m.key === selectedMetric);

    useEffect(() => {
        const fetchStats = async () => {
            // Reset data state
            setData([]);

            // Indicate loading state
            setLoading(true);

            // Add null check for currentMetric
            if (!currentMetric) {
                setError('Invalid metric selected');
                setLoading(false);
                return;
            }

            try {
                /*
                    The basic logic here is to determine the correct API endpoint based on the selected metric.
                    If the metric has a specific endpoint, we use that (replacing {daily} as needed).
                    Otherwise, we default to either /api/daily-stats or /api/weekly-stats based on the dailyStats toggle.
                */
                const endpoint = currentMetric.endpoint ?
                    currentMetric.endpoint.replace('{daily}', dailyStats ? 'true' : 'false') :
                    (dailyStats ? '/api/daily-stats' : '/api/weekly-stats');

                const cacheKey = currentMetric.endpoint ? `stats_${selectedMetric}_${dailyStats ? 'daily' : 'weekly'}` : `stats_${dailyStats ? 'daily' : 'weekly'}`;

                // Check cache first
                const cached = sessionStorage.getItem(cacheKey);
                const cacheTimestamp = sessionStorage.getItem(`${cacheKey}_timestamp`);

                // If cached data exists and is fresh, use it instead of calling the API again
                if (cached && cacheTimestamp) {
                    const age = Date.now() - parseInt(cacheTimestamp);
                    if (age < CACHE_DURATION_MS) {
                        console.log(`Using cached ${dailyStats ? 'daily' : 'weekly'} data (${Math.round(age / 1000)}s old)`);
                        try {
                            const parsedCached = JSON.parse(cached);
                            setData(parsedCached);
                            setLoading(false);
                            return;
                        } catch (cacheParseError) {
                            console.warn('Failed to parse cached data, fetching fresh:', cacheParseError);
                            // Clear corrupted cache and continue to fetch fresh data
                            sessionStorage.removeItem(cacheKey);
                            sessionStorage.removeItem(`${cacheKey}_timestamp`);
                        }
                    }
                }

                // Fetch fresh data
                console.log(`Fetching fresh ${dailyStats ? 'daily' : 'weekly'} data from ${endpoint}`);
                const response = await fetch(endpoint);
                if (!response.ok) {
                    const errorText = await response.text();
                    console.error(`API Error (${response.status}):`, errorText);
                    throw new Error(`Failed to fetch ${dailyStats ? 'daily' : 'weekly'} stats: ${response.status}`);
                }

                // Check if response is JSON
                const contentType = response.headers.get('content-type');
                if (!contentType || !contentType.includes('application/json')) {
                    const responseText = await response.text();
                    console.error('Non-JSON response:', responseText);
                    throw new Error(`Expected JSON response but got ${contentType || 'unknown content type'}`);
                }

                let result;
                try {
                    result = await response.json();
                } catch (parseError) {
                    const responseText = await response.text();
                    console.error('JSON Parse Error:', parseError);
                    console.error('Response text:', responseText);
                    throw new Error(`JSON Parse error: ${parseError.message}`);
                }

                // Format the data for the chart
                let formattedData;
                try {
                    formattedData = currentMetric.formatFn ? currentMetric.formatFn(result) : formatStandardData(result);
                    console.log('Fetched fresh data:', formattedData);
                } catch (formatError) {
                    console.error('Data formatting error:', formatError);
                    console.error('Raw result:', result);
                    throw new Error(`Data formatting error: ${formatError.message}`);
                }

                // Cache the formatted data
                try {
                    sessionStorage.setItem(cacheKey, JSON.stringify(formattedData));
                    sessionStorage.setItem(`${cacheKey}_timestamp`, Date.now().toString());
                } catch (storageError) {
                    console.warn('Failed to cache data:', storageError);
                    // Continue without caching
                }

                setData(formattedData);
            } catch (err) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };
        fetchStats();
    }, [dailyStats, selectedMetric]); // Added selectedMetric to dependencies

    if (loading) return <div>Loading...</div>;
    if (error) return <div>Error: {error}</div>;

    const PlotComponent = currentMetric.plot_component;

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
                <PlotComponent data={data} isDaily={dailyStats} />
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

export default HealthMetrics;