import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import CustomTooltip from './CustomTooltip';

export default function MilesPlot({ data, isDaily = false }) {
    return (
        <BarChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="start_date" />
            <YAxis domain={['auto', 'auto']} />
            <Bar
                dataKey="total_miles_run"
                fill={!isDaily ? (data.total_miles_run >= 10 ? "#83da77ff" : "#d89284ff") : "#3b82f6"}

            />
        </BarChart>
    );
}