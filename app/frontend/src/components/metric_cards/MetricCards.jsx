import { useState, useEffect } from "react";
import "./MetricCards.css";
import { CACHE_DURATION_MS } from "../Constants.js";

function MetricCards() {
    const [totalMiles, setTotalMiles] = useState(null);
    const [weeklyGoal, setWeeklyGoal] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchMetrics = async () => {
            try {
                const cacheKeyMiles = 'metric_total_miles_run';
                const cacheKeyGoal = 'metric_weekly_running_goal_met';

                const cachedMiles = sessionStorage.getItem(cacheKeyMiles);
                const cacheTimestampMiles = sessionStorage.getItem(`${cacheKeyMiles}_timestamp`);
                const cachedGoal = sessionStorage.getItem(cacheKeyGoal);
                const cacheTimestampGoal = sessionStorage.getItem(`${cacheKeyGoal}_timestamp`);

                let useCacheMiles = false;
                let useCacheGoal = false;

                if (cachedMiles && cacheTimestampMiles) {
                    const age = Date.now() - parseInt(cacheTimestampMiles);
                    if (age < CACHE_DURATION_MS) {
                        useCacheMiles = true;
                        setTotalMiles(JSON.parse(cachedMiles));
                    }
                }

                if (cachedGoal && cacheTimestampGoal) {
                    const age = Date.now() - parseInt(cacheTimestampGoal);
                    if (age < CACHE_DURATION_MS) {
                        useCacheGoal = true;
                        setWeeklyGoal(JSON.parse(cachedGoal));
                    }
                }

                if (useCacheMiles && useCacheGoal) {
                    console.log('Using cached metric card data');
                    setLoading(false);
                    return;
                }

                const [milesResponse, goalResponse] = await Promise.all([
                    fetch('/api/total-miles-run'),
                    fetch('/api/weekly-running-goal-met')
                ]);

                if (milesResponse.ok) {
                    const milesData = await milesResponse.json();
                    setTotalMiles(milesData.total_miles_run);
                    sessionStorage.setItem('metric_total_miles_run', JSON.stringify(milesData.total_miles_run));
                    sessionStorage.setItem('metric_total_miles_run_timestamp', Date.now().toString());
                }

                if (goalResponse.ok) {
                    const goalData = await goalResponse.json();
                    setWeeklyGoal((goalData.pct_weeks_running_goal_met * 100).toFixed(0));
                    sessionStorage.setItem('metric_weekly_running_goal_met', JSON.stringify((goalData.pct_weeks_running_goal_met * 100).toFixed(0)));
                    sessionStorage.setItem('metric_weekly_running_goal_met_timestamp', Date.now().toString());
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

            {/* <div className="metric-card">
                <div className="metric-label">Coming Soon</div>
                <div className="metric-value">
                    {loading ? '...' : '—'}
                </div>
            </div> */}
        </div>
    );
}

export default MetricCards;
