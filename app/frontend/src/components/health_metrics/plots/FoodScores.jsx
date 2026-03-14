import { LineChart, Line, XAxis, YAxis, Tooltip, Legend } from 'recharts';
import CustomTooltip from './CustomTooltip';

const tooltipSeriesWeekly = [
    {
        dataKey: "avg_max_food_score",
        label: "Maximum Food Score",
        unit: " points",
        color: "#3b82f6"
    },
    {
        dataKey: "avg_min_food_score",
        label: "Minimum Food Score",
        unit: " points",
        color: "#82ca9d"
    },
];

const tooltipSeriesDaily = [
    {
        dataKey: "avg_food_score",
        label: "Average Food Score",
        unit: " points",
        color: "#3b82f6"
    },
];

export default function FoodScores({ data, isDaily = false }) {
    return (
        <LineChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="start_date" />
            <YAxis domain={['auto', 'auto']} />
            <Tooltip content={<CustomTooltip isDaily={isDaily} series={isDaily ? tooltipSeriesDaily : tooltipSeriesWeekly} />} />
            <Legend />

            {/* 
                For "daily" data we'll show the average food score for the day, which is a single line. 
                For "weekly" data we'll show both the minimum and maximum food scores for the week, which are two lines.
            */}
            {isDaily ? (
                <Line
                    type="monotone"
                    dataKey={"avg_food_score"}
                    stroke={"#3b82f6"}
                    name={"Average Food Score"}
                    strokeWidth={2}
                    dot={{ r: 2 }}
                />
            ) : (
                <>
                    <Line
                        type="monotone"
                        dataKey={"avg_min_food_score"}
                        stroke={"#82ca9d"}
                        name={"Minimum Food Score"}
                        strokeWidth={2}
                        dot={{ r: 2 }}
                    />

                    <Line
                        type="monotone"
                        dataKey={"avg_max_food_score"}
                        stroke={"#3b82f6"}
                        name={"Maximum Food Score"}
                        strokeWidth={2}
                        dot={{ r: 2 }}
                    />
                </>
            )}
        </LineChart>
    );
}