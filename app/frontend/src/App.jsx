import './App.css'
import Header from './components/Header.jsx';
import HealthMetrics from './components/HealthMetrics.jsx';
import PasswordGate from './components/PasswordGate.jsx';

function App() {
  const isDevelopment = import.meta.env.DEV;

  const content = (
    <>
      <div>
        <Header />
      </div>
      <div>
        <HealthMetrics />
      </div>
    </>
  );

  if (isDevelopment) {
    return content;
  }

  return (
    // NOTE: The password here is largely included to prevent casual browsing of the app.
    // It is not intended to be a robust security measure.
    <PasswordGate password="shred">
      {content}
    </PasswordGate>
  );
}

export default App
