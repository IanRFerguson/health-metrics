import { LineChart, Line, XAxis, YAxis, Tooltip, Legend } from 'recharts';
import CustomTooltip from './CustomTooltip';

export default function StepCountPlot({ data, isDaily = false }) {
    return (
        <LineChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
        </LineChart>
    );
}