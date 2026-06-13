import { BarChart, Bar, XAxis, YAxis, Tooltip, Legend, Cell } from 'recharts';
import CustomTooltip from './CustomTooltip';

const dailyTooltipSeries = [
    {
        dataKey: "workout_type",
        label: "Workout Type",
        color: "#3b82f6"
    },
    {
        dataKey: "workout_duration",
        label: "Duration",
        color: "#3b82f6"
    },
    {
        dataKey: "total_energy",
        label: "Total Energy",
        color: "#3b82f6"
    },
    {
        dataKey: "active_energy",
        label: "Active Energy",
        color: "#3b82f6"
    }
];

const aggregatedTooltipSeries = [
    {
        dataKey: "run_count",
        label: "Running",
        color: "rgba(34, 197, 94, 0.8)"
    },
    {
        dataKey: "strength_count",
        label: "Strength",
        color: "rgba(59, 130, 246, 0.8)"
    }
];

const MONTH_NAMES = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"];

const formatMonth = (month) => MONTH_NAMES[month - 1] ?? month;

// Helper function to format minutes back to HH:MM for display
const formatMinutesToTime = (minutes) => {
    const hours = Math.floor(minutes / 60);
    const mins = Math.floor(minutes % 60);
    if (hours > 0) {
        return `${hours}:${mins.toString().padStart(2, '0')}`;
    }
    return `${mins}`;
};

function DailyWorkoutsPlot({ data }) {
    return (
        <BarChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="target_date" />
            <YAxis
                domain={['auto', 'auto']}
                tickFormatter={formatMinutesToTime}
                label={{ value: 'Duration (min)', angle: -90, position: 'insideLeft' }}
            />
            <Tooltip content={<CustomTooltip isDaily={true} series={dailyTooltipSeries} />} cursor={{ fill: 'transparent' }} />
            <Bar dataKey="workout_duration_minutes">
                {data.map((entry, index) => (
                    <Cell
                        key={`cell-${index}`}
                        fill={entry.workout_type === 'RUN' ? "rgba(34, 197, 94, 0.8)" : "rgba(59, 130, 246, 0.8)"}
                    />
                ))}
            </Bar>
        </BarChart>
    );
}

function AggregatedWorkoutsPlot({ data }) {
    // Pivot rows into one entry per month with separate run/strength counts
    const byMonth = {};
    for (const row of data) {
        if (!byMonth[row.month]) {
            byMonth[row.month] = { month: row.month, run_count: 0, strength_count: 0 };
        }
        if (row.workout_type === 'RUN') {
            byMonth[row.month].run_count = row.workout_count;
        } else {
            byMonth[row.month].strength_count = row.workout_count;
        }
    }
    const chartData = Object.values(byMonth).sort((a, b) => a.month - b.month);

    return (
        <BarChart data={chartData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="month" tickFormatter={formatMonth} />
            <YAxis
                domain={[0, 'auto']}
                label={{ value: 'Total Workouts', angle: -90, position: 'insideLeft' }}
            />
            <Tooltip content={<CustomTooltip isDaily={false} series={aggregatedTooltipSeries} labelFormatter={formatMonth} />} cursor={{ fill: 'transparent' }} />
            <Legend />
            <Bar dataKey="run_count" name="Running" fill="rgba(34, 197, 94, 0.8)" />
            <Bar dataKey="strength_count" name="Strength" fill="rgba(59, 130, 246, 0.8)" />
        </BarChart>
    );
}

export default function WorkoutsPlot({ data, isDaily = false }) {
    return isDaily ? <DailyWorkoutsPlot data={data} /> : <AggregatedWorkoutsPlot data={data} />;
}