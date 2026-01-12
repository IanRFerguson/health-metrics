import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import CustomTooltip from './CustomTooltip';

export default function ExercisePlot({ data, isDaily = false }) {
    return (
        <LineChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="start_date" />
            <YAxis domain={['auto', 'auto']} />
            <Tooltip content={<CustomTooltip isDaily={isDaily} />} />
            <Legend />
            <Line
                type="monotone"
                dataKey={"total_exercise_minutes"}
                stroke={"#8884d8"}
                name={"Total Exercise Minutes"}
                strokeWidth={2}
                dot={{ r: 4 }}
            />
        </LineChart>
    );
}