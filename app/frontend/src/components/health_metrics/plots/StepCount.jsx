import { LineChart, Line, XAxis, YAxis, Tooltip, Legend } from 'recharts';
import CustomTooltip from './CustomTooltip';

const tooltipSeries = [
    {
        dataKey: "total_step_count",
        label: "Step Count",
        unit: " steps",
        color: "#8884d8"
    }
];

export default function StepCountPlot({ data, isDaily = false }) {
    return (
        <LineChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="start_date" />
            <YAxis domain={['auto', 'auto']} />
            <Tooltip content={<CustomTooltip isDaily={isDaily} series={tooltipSeries} />} />
            <Legend />
            <Line
                type="linear"
                dataKey={"total_step_count"}
                stroke={"#8884d8"}
                name={"Step Count"}
                strokeWidth={2}
                dot={{ r: 4 }}
            />
        </LineChart>
    );
}