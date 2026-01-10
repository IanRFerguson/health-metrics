import { useEffect, useState } from "react";


function Header() {
    // Get the current year
    const currentYear = new Date().getFullYear();

    // State to hold the last updated time
    const [lastUpdated, setLastUpdated] = useState(null);

    // Fetch the last updated time from the backend API
    useEffect(() => {
        const fetchLastUpdated = async () => {
            try {
                const response = await fetch('/api/last-updated-at');
                if (!response.ok) throw new Error('Failed to fetch last updated time');
                const result = await response.json();
                setLastUpdated(new Date(result.last_updated_at).toLocaleString());
            } catch (err) {
                console.error(err);
            }
        };
        fetchLastUpdated();
    }, []);

    return (
        <header>
            <h1>Health Metrics {currentYear}</h1>
            <p>Last updated {lastUpdated}</p>
        </header>
    );
}

export default Header;