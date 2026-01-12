import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Cell } from 'recharts';

export default function MilesPlot({ data, isDaily = false }) {
    return (
        <BarChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="start_date" />
            <YAxis domain={['auto', 'auto']} />
            <Bar dataKey="total_miles_run">
                {data.map((entry, index) => (
                    <Cell
                        key={`cell-${index}`}
                        fill={!isDaily ? (entry.total_miles_run >= 10 ? "#00BFC4" : "#F8766D") : "#00BFC4"}
                    />
                ))}
            </Bar>
        </BarChart>
    );
}