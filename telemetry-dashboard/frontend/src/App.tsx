import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import TelemetryPage from './pages/TelemetryPage';

interface WeatherForecast {
  date: string;
  temperatureC: number;
  temperatureF: number;
  summary: string;
}

function HomePage() {
  const [message, setMessage] = useState<string>("");
  const [error, setError] = useState<string>("");
  const [weatherData, setWeatherData] = useState<WeatherForecast[]>([]);
  const [weatherError, setWeatherError] = useState<string>("");

  useEffect(() => {
    fetch('http://localhost:5000/api/helloworld')
      .then(res => res.text())
      .then(data => setMessage(data))
      .catch(err => setError(err.message));
  }, []);

  const fetchWeatherForecast = () => {
    setWeatherError("");
    fetch('http://localhost:5000/api/weatherforecast')
      .then(res => res.json())
      .then((data: WeatherForecast[]) => setWeatherData(data))
      .catch(err => setWeatherError(err.message));
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1>React + .NET Hello World</h1>
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
          marginBottom: '20px'
        }}>
          View Real-Time Telemetry
        </button>
      </Link>
      
      <hr />
      
      <h2>Weather Forecast</h2>
      <button onClick={fetchWeatherForecast} style={{
        padding: '10px 20px',
        fontSize: '16px',
        backgroundColor: '#007bff',
        color: 'white',
        border: 'none',
        borderRadius: '5px',
        cursor: 'pointer'
      }}>
        Get Weather Forecast
      </button>
      
      {weatherError && <p style={{color: 'red'}}>Weather Error: {weatherError}</p>}
      
      {weatherData.length > 0 && (
        <table style={{
          marginTop: '20px',
          borderCollapse: 'collapse',
          width: '100%',
          maxWidth: '600px'
        }}>
          <thead>
            <tr style={{ backgroundColor: '#f2f2f2' }}>
              <th style={{ border: '1px solid #ddd', padding: '8px' }}>Date</th>
              <th style={{ border: '1px solid #ddd', padding: '8px' }}>Temp (°C)</th>
              <th style={{ border: '1px solid #ddd', padding: '8px' }}>Temp (°F)</th>
              <th style={{ border: '1px solid #ddd', padding: '8px' }}>Summary</th>
            </tr>
          </thead>
          <tbody>
            {weatherData.map((forecast, index) => (
              <tr key={index}>
                <td style={{ border: '1px solid #ddd', padding: '8px' }}>{forecast.date}</td>
                <td style={{ border: '1px solid #ddd', padding: '8px' }}>{forecast.temperatureC}</td>
                <td style={{ border: '1px solid #ddd', padding: '8px' }}>{forecast.temperatureF}</td>
                <td style={{ border: '1px solid #ddd', padding: '8px' }}>{forecast.summary}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/telemetry" element={<TelemetryPage />} />
      </Routes>
    </Router>
  );
}

export default App;
