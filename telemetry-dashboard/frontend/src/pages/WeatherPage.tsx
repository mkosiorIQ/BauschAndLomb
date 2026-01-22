import React, { useState } from 'react';
import { useMsal } from '@azure/msal-react';
import { loginRequest } from '../authConfig';

interface WeatherForecast {
  date: string;
  temperatureC: number;
  temperatureF: number;
  summary: string;
}

function WeatherPage() {
  const { instance, accounts } = useMsal();
  const [weatherData, setWeatherData] = useState<WeatherForecast[]>([]);
  const [weatherError, setWeatherError] = useState<string>("");
  const [loading, setLoading] = useState<boolean>(false);

  const fetchWeatherForecast = async () => {
    setWeatherError("");
    setLoading(true);
    
    try {
      // Check if user is logged in
      if (!accounts || accounts.length === 0) {
        throw new Error('You must be logged in to access the weather forecast');
      }

      // Get access token for the backend API
      const response = await instance.acquireTokenSilent({
        scopes: loginRequest.scopes,
        account: accounts[0],
      });

      // Call API with Bearer token
      const apiResponse = await fetch('http://localhost:5000/api/weatherforecast', {
        headers: {
          'Authorization': `Bearer ${response.accessToken}`,
        },
      });

      if (!apiResponse.ok) {
        throw new Error(`HTTP error! status: ${apiResponse.status}`);
      }

      const data: WeatherForecast[] = await apiResponse.json();
      setWeatherData(data);
      setLoading(false);
    } catch (err: any) {
      // Handle MSAL-specific errors
      if (err.errorCode === 'no_account_error' || err.message?.includes('no_account_error')) {
        setWeatherError('You must be logged in to access the weather forecast');
      } else {
        setWeatherError(err.message || 'Failed to fetch weather data');
      }
      setLoading(false);
    }
  };

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1>Weather Forecast</h1>
      
      <button onClick={fetchWeatherForecast} style={{
        padding: '10px 20px',
        fontSize: '16px',
        backgroundColor: '#007bff',
        color: 'white',
        border: 'none',
        borderRadius: '5px',
        cursor: 'pointer',
        marginBottom: '20px'
      }}>
        {loading ? 'Loading...' : 'Get Weather Forecast'}
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

export default WeatherPage;
