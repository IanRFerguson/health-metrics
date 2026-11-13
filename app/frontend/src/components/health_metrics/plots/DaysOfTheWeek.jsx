import { BarChart, Bar, XAxis, YAxis, Tooltip, Cell } from 'recharts';
import CustomTooltip from './CustomTooltip';

const tooltipSeries = [
    {
        dataKey: "dow_name",
        label: "Day of Week",
        color: "#3b82f6"
    },
    {
        dataKey: "avg_exercise_minutes",
        label: "Exercise Minutes",
        unit: " min",
        color: "#3b82f6"
    },
    {
        dataKey: "days_run",
        label: "Days Run",
        unit: " days",
        color: "#3b82f6"
    },
    {
        dataKey: "avg_step_count",
        label: "Average Step Count",
        unit: " steps",
        color: "#3b82f6"
    }
];

export default function DaysOfTheWeekPlot({ data }) {
    return (
        <BarChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="dow_name" />
            <YAxis dataKey="avg_exercise_minutes" domain={['auto', 'auto']} />
            <Bar dataKey="avg_exercise_minutes">
                {data.map((entry, index) => (
                    <Cell
                        key={`cell-${index}`}
                        fill={entry.dow_name === 'Monday' ? "rgba(34, 197, 94, 0.8)" : "rgba(59, 130, 246, 0.8)"}
                    />
                ))}
            </Bar>
            <Tooltip content={<CustomTooltip series={tooltipSeries} />}
                cursor={{ fill: 'transparent' }}
            />
        </BarChart>
    );
}