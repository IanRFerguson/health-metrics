import { useState, useEffect } from "react";
import "./StatsTable.css";
import { CACHE_DURATION_MS } from "../Constants.js";

function tidyColumnName(name) {
    return name.replace(/_/g, ' ').replace(/pct/gi, '%').replace(/avg/gi, 'Average').toUpperCase();
}

function StatsTable() {
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const fetchMonthlyStats = async () => {
            setLoading(true);
            try {
                const cacheKey = 'monthly_stats';
                const cacheTimestampKey = `${cacheKey}_timestamp`;

                const cachedData = sessionStorage.getItem(cacheKey);
                const cacheTimestamp = sessionStorage.getItem(cacheTimestampKey);

                if (cachedData && cacheTimestamp) {
                    const age = Date.now() - parseInt(cacheTimestamp);
                    if (age < CACHE_DURATION_MS) {
                        setData(JSON.parse(cachedData));
                        setLoading(false);
                        return;
                    }
                }

                const response = await fetch('/api/monthly-stats');
                if (!response.ok) throw new Error('Failed to fetch monthly stats');
                const result = await response.json();
                setData(result);
                sessionStorage.setItem(cacheKey, JSON.stringify(result));
                sessionStorage.setItem(cacheTimestampKey, Date.now().toString());
            } catch (err) {
                setError(err.message);
            } finally {
                setLoading(false);
            }
        };

        fetchMonthlyStats();
    }, []);

    // Calculate min and max for each column
    const getColumnStats = (columnName) => {
        const values = data
            .map(row => row[columnName])
            .filter(val => val !== null && val !== undefined && !isNaN(Number(val)))
            .map(val => Number(val));

        if (values.length === 0) return { min: 0, max: 0 };

        return {
            min: Math.min(...values),
            max: Math.max(...values)
        };
    };

    // Helper function to determine cell color based on value within column range
    const getCellStyle = (value, columnName) => {
        if (value === null || value === undefined || value === 'N/A') {
            return {};
        }

        const numValue = Number(value);
        if (isNaN(numValue)) {
            return {};
        }

        const { min, max } = getColumnStats(columnName);

        // If all values are the same, use a medium intensity
        if (min === max) {
            return {
                backgroundColor: 'rgba(34, 197, 94, 0.3)',
                color: 'rgba(255, 255, 255, 0.95)'
            };
        }

        // Normalize value between 0 and 1
        const normalized = (numValue - min) / (max - min);

        // Map to green intensity (0.1 to 0.6 for background, lighter for lower values)
        const intensity = 0.1 + (normalized * 0.5);

        return {
            backgroundColor: `rgba(34, 197, 94, ${intensity})`,
            color: normalized > 0.5 ? 'rgba(255, 255, 255, 0.95)' : 'rgba(255, 255, 255, 0.87)'
        };
    };

    // Format month/year for display
    const formatMonth = (year, month) => {
        const date = new Date(year, month - 1);
        return date.toLocaleDateString('en-US', { month: 'long' });
    };

    if (loading) return <div className="stats-table-container">Loading stats...</div>;
    if (error) return <div className="stats-table-container">Error: {error}</div>;
    if (data.length === 0) return <div className="stats-table-container">No data available</div>;

    // Define which columns to display (excluding year and month)
    const columns = Object.keys(data[0]).filter(key => !['year', 'month'].includes(key));

    return (
        <div className="stats-table-container">
            <h3>Monthly Statistics</h3>
            <div className="stats-table-wrapper">
                <table className="stats-table">
                    <thead>
                        <tr>
                            <th>MONTH</th>
                            {columns.map(col => (
                                <th key={col}>{tidyColumnName(col)}</th>
                            ))}
                        </tr>
                    </thead>
                    <tbody>
                        {data.map((row, idx) => (
                            <tr key={idx}>
                                <td>{formatMonth(row.year, row.month).toUpperCase()}</td>
                                {columns.map(col => (
                                    <td key={col} style={getCellStyle(row[col], col)}>
                                        {row[col] !== null && row[col] !== undefined
                                            ? typeof row[col] === 'number'
                                                ? row[col].toFixed(2)
                                                : row[col]
                                            : 'N/A'}
                                    </td>
                                ))}
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
}

export default StatsTable;
