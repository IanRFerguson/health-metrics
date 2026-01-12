import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend } from 'recharts';
import CustomTooltip from './CustomTooltip';

export default function WeightPlot({ data, isDaily = false }) {
    return (
        <LineChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="start_date" />
            <YAxis domain={['auto', 'auto']} />
            <Tooltip content={<CustomTooltip isDaily={isDaily} />} />
            <Legend />

            {/* 
                NOTE - we only display the "maximum weight" line on daily plots,
                since min and avg weights are less meaningful on a daily basis.
            */}
            {!isDaily && (<Line
                type="monotone"
                dataKey={"min_weight_lb"}
                stroke={"#82ca9d"}
                name={"Minimum Weight"}
                strokeWidth={2}
                dot={{ r: 4 }}
            />)}

            <Line
                type="monotone"
                dataKey={"max_weight_lb"}
                stroke={"#3b82f6"}
                name={"Maximum Weight"}
                strokeWidth={2}
                dot={{ r: 4 }}
            />
        </LineChart>
    );
}