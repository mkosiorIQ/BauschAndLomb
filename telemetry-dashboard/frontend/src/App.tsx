import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import TelemetryPage from './pages/TelemetryPage';
import WeatherPage from './pages/WeatherPage';
import AppBar from './components/AppBar';

function HomePage() {
  const [message, setMessage] = useState<string>("");
  const [error, setError] = useState<string>("");

  useEffect(() => {
    fetch('http://localhost:5000/api/helloworld')
      .then(res => res.text())
      .then(data => setMessage(data))
      .catch(err => setError(err.message));
  }, []);

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1>Welcome to Central Connected Device Application</h1>
      <p>Message from Backend: {message}</p>
      {error && <p style={{color: 'red'}}>Error: {error}</p>}
      
      <hr />
      
      <Link to="/telemetry">
        <button style={{
          padding: '10px 20px',
          fontSize: '16px',
          backgroundColor: '#28a745',
          color: 'white',
          border: 'none',
          borderRadius: '5px',
          cursor: 'pointer',
          marginBottom: '20px',
          marginRight: '10px'
        }}>
          View Real-Time Telemetry
        </button>
      </Link>
      
      <Link to="/weather">
        <button style={{
          padding: '10px 20px',
          fontSize: '16px',
          backgroundColor: '#007bff',
          color: 'white',
          border: 'none',
          borderRadius: '5px',
          cursor: 'pointer',
          marginBottom: '20px'
        }}>
          View Weather Forecast
        </button>
      </Link>
    </div>
  );
}

function App() {
  return (
    <Router>
      <AppBar />
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/telemetry" element={<TelemetryPage />} />
        <Route path="/weather" element={<WeatherPage />} />
      </Routes>
    </Router>
  );
}

export default App;
