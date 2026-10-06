import React, { createContext, useContext, useEffect, useState } from 'react';
import { api } from '../lib/api';

const AuthContext = createContext({});

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const saved = localStorage.getItem('scms_user');
    return saved ? JSON.parse(saved) : null;
  });
  const [loading, setLoading] = useState(false);

  const signIn = async (email, password) => {
    const res = await api.login(email, password);
    localStorage.setItem('scms_token', res.token);
    localStorage.setItem('scms_user', JSON.stringify(res.user));
    setUser(res.user);
    return res.user;
  };

  const signOut = async () => {
    localStorage.removeItem('scms_token');
    localStorage.removeItem('scms_user');
    setUser(null);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        profile: user,
        role: user?.role || 'admin',
        loading,
        signIn,
        signOut
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
