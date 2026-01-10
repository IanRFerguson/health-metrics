function Header() {
    const currentYear = new Date().getFullYear();

    return (
        <header>
            <h1>Health Metrics {currentYear}</h1>
            <p>Last updated x</p>
        </header>
    );
}

export default Header;