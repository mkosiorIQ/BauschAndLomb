import React from 'react';
import { render, screen } from '@testing-library/react';
import App from './App';

test('renders Hello World heading', () => {
  render(<App />);
  const heading = screen.getByText(/React \+ \.NET Hello World/i);
  expect(heading).toBeInTheDocument();
});
