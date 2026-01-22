import { Configuration, PopupRequest } from "@azure/msal-browser";

export const msalConfig: Configuration = {
    auth: {
        clientId: process.env.REACT_APP_CLIENT_ID || "default_client_id", // Application (client) ID from Azure portal
        authority: process.env.REACT_APP_AUTHORITY || "https://login.microsoftonline.com/common", // Directory (tenant) ID from Azure portal
        redirectUri: process.env.REACT_APP_REDIRECT_URI || "http://localhost:3000", // Fallback
        postLogoutRedirectUri: "/",
    },
    cache: {
        cacheLocation: "sessionStorage", 
    },
    system: {
      loggerOptions: {
        logLevel: 3, // Verbose logging
      },
      allowRedirectInIframe: true,
    }
};

// This scope is what we created in the Backend registration
export const loginRequest: PopupRequest = {
    scopes: (process.env.REACT_APP_SCOPES || "openid profile").split(' '),
};
