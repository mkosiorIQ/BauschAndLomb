import React from 'react';
import { Link } from 'react-router-dom';
import { useMsal, useIsAuthenticated } from "@azure/msal-react";
import { loginRequest } from '../authConfig';

function AppBar() {
    const { instance, accounts, inProgress } = useMsal();
    const isAuthenticated = useIsAuthenticated();

    const handleLogin = () => {
        instance.loginRedirect(loginRequest).catch(e => {
            console.error("Login error:", e);
            alert(`Login failed: ${e.message || JSON.stringify(e)}`);
        });
    };

    const handleLogout = () => {
        instance.logoutRedirect().catch(e => console.error(e));
    };

    if (inProgress === "startup") {
        return <div>Loading...</div>;
    }

    const userName = accounts.length > 0 ? (accounts[0].name || accounts[0].username) : '';

  return (
    <div style={{
      backgroundColor: '#282c34',
      padding: '15px 20px',
      color: 'white',
      display: 'flex',
      justifyContent: 'space-between',
      alignItems: 'center',
      boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
        <h2 style={{ margin: 0, fontSize: '24px' }}>Bausch Health</h2>
        <Link to="/" style={{ color: 'white', textDecoration: 'none', fontSize: '16px' }}>
          Home
        </Link>
        {isAuthenticated ? (
          <Link to="/telemetry" style={{ color: 'white', textDecoration: 'none', fontSize: '16px' }}>
            Real-Time Telemetry
          </Link>
        ) : (
          <span 
            style={{ 
              color: '#666', 
              fontSize: '16px',
              cursor: 'not-allowed',
              opacity: 0.5
            }}
            title="Please login to access Real-Time Telemetry"
          >
            Real-Time Telemetry
          </span>
        )}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
        {isAuthenticated && (
          <span style={{ fontSize: '14px' }}>
            Welcome, {userName}
          </span>
        )}
        <button 
          onClick={isAuthenticated ? handleLogout : handleLogin}
          style={{
            padding: '8px 20px',
            fontSize: '14px',
            backgroundColor: '#61dafb',
            color: '#282c34',
            border: 'none',
            borderRadius: '5px',
            cursor: 'pointer',
            fontWeight: 'bold',
            transition: 'background-color 0.3s'
          }}
          onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#4fc3dc'}
          onMouseLeave={(e) => e.currentTarget.style.backgroundColor = '#61dafb'}
        >
          {isAuthenticated ? 'Logout' : 'Login'}
        </button>
      </div>
    </div>
  );
}

export default AppBar;
