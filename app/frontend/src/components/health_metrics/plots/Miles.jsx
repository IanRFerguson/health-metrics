import { BarChart, Bar, XAxis, YAxis, Tooltip, Cell } from 'recharts';
import CustomTooltip from './CustomTooltip';

const dailyTooltipSeries = [
    {
        dataKey: "total_miles_run",
        label: "Distance",
        color: "#8884d8"
    },
    {
        label: "Duration",
        accessor: (data) => {
            const runningWorkout = data.all_daily_workouts?.find(w => w.workout_type?.includes('RUN'));
            return runningWorkout?.workout_duration;
        },
        color: "#8884d8"
    },
    {
        label: "Pace",
        accessor: (data) => {
            const runningWorkout = data.all_daily_workouts?.find(w => w.workout_type?.includes('RUN'));
            return runningWorkout?.pace;
        },
        color: "#8884d8"
    }
];

const weeklyTooltipSeries = [
    {
        dataKey: "total_miles_run",
        label: "Distance",
        color: "#8884d8"
    },
    {
        dataKey: "running_workouts",
        label: "Running Workouts",
        color: "#8884d8"
    },
    {
        dataKey: "avg_pace",
        label: "Average Pace",
        color: "#8884d8"
    }
];

export default function MilesPlot({ data, isDaily = false }) {
    return isDaily ? dailyMilesPlot(data, isDaily) : weeklyMilesPlot(data, isDaily);
}

function dailyMilesPlot(data, isDaily) {
    return (
        <BarChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="start_date" />
            <YAxis domain={["auto", "auto"]} />
            <Tooltip
                content={<CustomTooltip isDaily={isDaily} series={dailyTooltipSeries} />}
                cursor={{ fill: 'transparent' }}
            />
            <Bar dataKey="total_miles_run">
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

function weeklyMilesPlot(data, isDaily) {
    return (
        <BarChart data={data} margin={{ top: 5, right: 30, left: 20, bottom: 5 }}>
            <XAxis dataKey="start_date" />
            <YAxis domain={[0, 20]} />
            <Tooltip
                content={<CustomTooltip isDaily={isDaily} series={weeklyTooltipSeries} />}
                cursor={{ fill: 'transparent' }}
            />
            <Bar dataKey="total_miles_run">
                {data.map((entry, index) => (
                    <Cell
                        key={`cell-${index}`}
                        fill={entry.total_miles_run >= 10 ? "rgba(34, 197, 94, 0.8)" : "rgba(239, 68, 68, 0.8)"}
                    />
                ))}
            </Bar>
        </BarChart>
    );
}