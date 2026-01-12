import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import CustomTooltip from './CustomTooltip';

export default function MilesPlot({ data }) {
    return (
        <BarChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="start_date" />
            <YAxis domain={['auto', 'auto']} />
            <Legend />
            <Bar
                dataKey="total_miles_run"
                fill={"total_miles_run" >= 10 ? "#83da77ff" : "#d89284ff"}

            />
        </BarChart>
    );
}