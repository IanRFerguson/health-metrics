import { BarChart, Bar, XAxis, YAxis, Tooltip, Cell } from 'recharts';
import CustomTooltip from './CustomTooltip';

export default function WorkoutsPlot({ data, isDaily = false }) {
    console.log(data);
    return (
        <BarChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="target_date" />
            <YAxis domain={['auto', 'auto']} />
            {/* <Tooltip
                content={<CustomTooltip isDaily={isDaily} series={dailyTooltipSeries} />}
                cursor={{ fill: 'transparent' }}
            /> */}
            <Bar dataKey="workout_duration">
                {data.map((entry, index) => (
                    <Cell
                        key={`cell-${index}`}
                        fill={"rgba(34, 197, 94, 0.8)"}
                    />
                ))}
            </Bar>
        </BarChart>
    );
}