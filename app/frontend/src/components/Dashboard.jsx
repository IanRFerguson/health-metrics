import HealthMetrics from "./HealthMetrics";
import MetricCards from "./MetricCards";
import StatsTable from "./StatsTable";

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