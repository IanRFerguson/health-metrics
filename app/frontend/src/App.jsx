import './App.css'
import Header from './components/Header.jsx';
import WeeklyStats from './components/WeeklyStats.jsx';
import PasswordGate from './components/PasswordGate.jsx';

function App() {
  return (
    <PasswordGate password="shred">
      <>
        <div>
          <Header />
        </div>
        <div>
          <WeeklyStats />
        </div>
      </>
    </PasswordGate>
  )
}

export default App
