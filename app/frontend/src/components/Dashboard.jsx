import HealthMetrics from "./health_metrics/HealthMetrics";
import MetricCards from "./metric_cards/MetricCards";
import StatsTable from "./stats_table/StatsTable";

function Dashboard() {
    return (
        <div>
            <HealthMetrics />
            <MetricCards />
            <StatsTable />
        </div>
    );
}

export default Dashboard;