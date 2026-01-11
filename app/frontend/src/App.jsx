import './App.css'
import Header from './components/Header.jsx';
import WeeklyStats from './components/WeeklyStats.jsx';
import PasswordGate from './components/PasswordGate.jsx';

function App() {
  const isDevelopment = import.meta.env.DEV;

  const content = (
    <>
      <div>
        <Header />
      </div>
      <div>
        <WeeklyStats />
      </div>
    </>
  );

  if (isDevelopment) {
    return content;
  }

  return (
    <PasswordGate password="shred">
      {content}
    </PasswordGate>
  );
}

export default App
