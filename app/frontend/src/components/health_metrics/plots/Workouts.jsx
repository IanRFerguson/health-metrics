import { BarChart, Bar, XAxis, YAxis, Tooltip, Cell } from 'recharts';
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
        dataKey: "workout_count",
        label: "Workout Count",
        color: "#3b82f6"
    },
    {
        dataKey: "average_workout_duration_minutes",
        label: "Average Workout Duration",
        color: "#3b82f6"
    },
    {
        dataKey: "average_pace",
        label: "Average Pace",
        color: "#3b82f6"
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
    // Give each bar a unique x-axis key to avoid Recharts matching the wrong bar
    // when multiple bars share the same month value.
    const chartData = data.map(d => ({ ...d, _barKey: `${d.month}_${d.workout_type}` }));
    const formatBarKeyTick = (key) => formatMonth(parseInt(key.split('_')[0]));
    const formatBarKeyLabel = (key) => formatMonth(parseInt(key.split('_')[0]));

    return (
        <BarChart data={chartData} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="_barKey" tickFormatter={formatBarKeyTick} />
            <YAxis
                domain={['auto', 'auto']}
                tickFormatter={formatMinutesToTime}
                label={{ value: 'Total Workouts', angle: -90, position: 'insideLeft' }}
            />
            <Tooltip content={<CustomTooltip isDaily={false} series={aggregatedTooltipSeries} labelFormatter={formatBarKeyLabel} />} cursor={{ fill: 'transparent' }} />
            <Bar dataKey="workout_count">
                {chartData.map((entry, index) => (
                    <Cell
                        key={`cell-${index}`}
                        fill={entry.workout_type === 'RUN' ? "rgba(34, 197, 94, 0.8)" : "rgba(59, 130, 246, 0.8)"}
                    />
                ))}
            </Bar>
        </BarChart>
    );
}

export default function WorkoutsPlot({ data, isDaily = false }) {
    return isDaily ? <DailyWorkoutsPlot data={data} /> : <AggregatedWorkoutsPlot data={data} />;
}