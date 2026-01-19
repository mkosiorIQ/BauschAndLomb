import React, { useEffect, useState } from 'react';
import * as signalR from '@microsoft/signalr';
import { Link } from 'react-router-dom';
import { LogLevel } from '@microsoft/signalr'; // Might be missing something

interface TelemetryMessage {
  timestamp: string;
  data: string;
}

function TelemetryPage() {
  const [messages, setMessages] = useState<TelemetryMessage[]>([]);
  const [connectionStatus, setConnectionStatus] = useState<string>('Disconnected');
  const [error, setError] = useState<string>('');

  useEffect(() => {
    const connection = new signalR.HubConnectionBuilder()
      .withUrl('http://localhost:5000/telemetryHub')
      //.withUrl('http://localhost:3000/telemetryHub')
      .withAutomaticReconnect()
      .configureLogging(LogLevel.Information)
      .build();

    connection.start()
      .then(() => {
        setConnectionStatus('Connected');
        setError(''); // Clear error on successful connection
        console.log('SignalR Connected');
      })
      .catch(err => {
        setError(err.toString());
        setConnectionStatus('Failed to connect');
        console.error('SignalR Connection Error: ', err);
      });

    connection.on('ReceiveTelemetry', (message: string) => {
      console.log('Received telemetry:', message);
      setMessages(prev => [{
        timestamp: new Date().toISOString(),
        data: message
      }, ...prev].slice(0, 100)); // Keep last 100 messages
    });

    connection.onreconnecting(() => setConnectionStatus('Reconnecting...'));
    connection.onreconnected(() => {
      setConnectionStatus('Reconnected');
      setError(''); // Clear error on reconnect
    });
    connection.onclose(() => setConnectionStatus('Disconnected'));

    return () => {
      connection.stop();
    };
  }, []);

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial, sans-serif' }}>
      <h1>Real-Time Telemetry Dashboard</h1>
      
      <Link to="/">
        <button style={{
          padding: '10px 20px',
          fontSize: '16px',
          backgroundColor: '#6c757d',
          color: 'white',
          border: 'none',
          borderRadius: '5px',
          cursor: 'pointer',
          marginBottom: '20px'
        }}>
          ← Back to Home
        </button>
      </Link>

      <div style={{ marginBottom: '20px' }}>
        <strong>Connection Status:</strong> 
        <span style={{ 
          color: connectionStatus === 'Connected' || connectionStatus === 'Reconnected' ? 'green' : 'red',
          marginLeft: '10px'
        }}>
          {connectionStatus}
        </span>
      </div>

      {error && <p style={{color: 'red'}}>Error: {error}</p>}

      <h2>Messages ({messages.length})</h2>
      
      <div style={{
        maxHeight: '600px',
        overflowY: 'auto',
        border: '1px solid #ddd',
        borderRadius: '5px',
        padding: '10px',
        backgroundColor: '#f9f9f9'
      }}>
        {messages.length === 0 ? (
          <p style={{ color: '#999' }}>Waiting for messages...</p>
        ) : (
          messages.map((msg, index) => (
            <div key={index} style={{
              padding: '10px',
              marginBottom: '10px',
              backgroundColor: 'white',
              border: '1px solid #ddd',
              borderRadius: '3px'
            }}>
              <div style={{ fontSize: '12px', color: '#666' }}>
                {new Date(msg.timestamp).toLocaleString()}
              </div>
              <pre style={{ margin: '5px 0 0 0', whiteSpace: 'pre-wrap' }}>
                {msg.data}
              </pre>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default TelemetryPage;