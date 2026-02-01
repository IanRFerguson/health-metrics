import { BarChart, Bar, XAxis, YAxis, Tooltip, Cell } from 'recharts';
import CustomTooltip from './CustomTooltip';

const tooltipSeries = [
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

// Helper function to format minutes back to HH:MM for display
const formatMinutesToTime = (minutes) => {
    const hours = Math.floor(minutes / 60);
    const mins = Math.floor(minutes % 60);
    if (hours > 0) {
        return `${hours}:${mins.toString().padStart(2, '0')}`;
    }
    return `${mins}`;
};

export default function WorkoutsPlot({ data, isDaily = false }) {
    console.log(data);
    return (
        <BarChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="target_date" />
            <YAxis
                domain={['auto', 'auto']}
                tickFormatter={formatMinutesToTime}
                label={{ value: 'Duration (min)', angle: -90, position: 'insideLeft' }}
            />
            <Tooltip
                content={<CustomTooltip isDaily={isDaily} series={tooltipSeries} />}
                cursor={{ fill: 'transparent' }}
            />
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