import { useState, useEffect } from "react";
import "./MetricCards.css";

function MetricCards() {
    const [totalMiles, setTotalMiles] = useState(null);
    const [weeklyGoal, setWeeklyGoal] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchMetrics = async () => {
            try {
                const [milesResponse, goalResponse] = await Promise.all([
                    fetch('/api/total-miles-run'),
                    fetch('/api/weekly-running-goal-met')
                ]);

                if (milesResponse.ok) {
                    const milesData = await milesResponse.json();
                    setTotalMiles(milesData.total_miles_run);
                }

                if (goalResponse.ok) {
                    const goalData = await goalResponse.json();
                    setWeeklyGoal((goalData.pct_weeks_running_goal_met * 100).toFixed(0));
                }
            } catch (err) {
                console.error('Error fetching metric cards:', err);
            } finally {
                setLoading(false);
            }
        };

        fetchMetrics();
    }, []);

    return (
        <div className="metric-cards-container">
            <div className="metric-card">
                <div className="metric-label">Total Miles Run</div>
                <div className="metric-value">
                    {loading ? '...' : totalMiles !== null && totalMiles !== undefined ? Number(totalMiles).toFixed(2) : 'N/A'}
                </div>
            </div>

            <div className="metric-card">
                <div className="metric-label">Weekly Running Goal Met</div>
                <div className="metric-value">
                    {loading ? '...' : weeklyGoal !== null && weeklyGoal !== undefined ? `${weeklyGoal}%` : 'N/A'}
                </div>
            </div>

            <div className="metric-card">
                <div className="metric-label">Coming Soon</div>
                <div className="metric-value">
                    {loading ? '...' : '—'}
                </div>
            </div>
        </div>
    );
}

export default MetricCards;
