import { BarChart, Bar, XAxis, YAxis, Cell } from 'recharts';

export default function MilesPlot({ data, isDaily = false }) {
    return (
        <BarChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="start_date" />
            <YAxis domain={['auto', 'auto']} />
            <Bar dataKey="total_miles_run">
                {data.map((entry, index) => (
                    <Cell
                        key={`cell-${index}`}
                        fill={!isDaily ? (entry.total_miles_run >= 10 ? "rgba(34, 197, 94, 0.8)" : "rgba(239, 68, 68, 0.8)") : "rgba(34, 197, 94, 0.8)"}
                    />
                ))}
            </Bar>
        </BarChart>
    );
}