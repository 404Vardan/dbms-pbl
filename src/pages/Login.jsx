import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Login() {
  const [email, setEmail] = useState('registrar@scms.edu.in');
  const [password, setPassword] = useState('Demo@12345');
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);
  const { signIn } = useAuth();
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      await signIn(email, password);
      navigate('/');
    } catch (err) {
      setError(err.message || 'Login failed. Please verify email and password.');
    } finally {
      setLoading(false);
    }
  };

  const handleSelectDemo = (demoEmail) => {
    setEmail(demoEmail);
    setPassword('Demo@12345');
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      backgroundColor: '#f1f5f9',
      padding: '20px'
    }}>
      <div style={{
        maxWidth: '460px',
        width: '100%',
        backgroundColor: 'white',
        borderRadius: '8px',
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
        border: '1px solid #e2e8f0',
        padding: '32px'
      }}>
        <div style={{ textAlign: 'center', marginBottom: '24px' }}>
          <div style={{
            width: '48px',
            height: '48px',
            backgroundColor: '#1e40af',
            color: 'white',
            borderRadius: '8px',
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontSize: '1.4rem',
            fontWeight: 'bold',
            marginBottom: '12px'
          }}>
            S
          </div>
          <h2 style={{ fontSize: '1.4rem', color: '#0f172a', fontWeight: '700' }}>SCMS Portal</h2>
          <p style={{ color: '#64748b', fontSize: '0.875rem', marginTop: '4px' }}>
            Student & College Management ERP System
          </p>
        </div>

        {error && (
          <div className="alert alert-danger" style={{ marginBottom: '16px' }}>
            <span>⚠️</span> {error}
          </div>
        )}

        <form onSubmit={handleLogin}>
          <div className="form-group" style={{ marginBottom: '16px' }}>
            <label className="form-label">Email Address</label>
            <input
              type="email"
              className="form-control"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              placeholder="e.g. registrar@scms.edu.in"
            />
          </div>

          <div className="form-group" style={{ marginBottom: '20px' }}>
            <label className="form-label">Password</label>
            <input
              type="password"
              className="form-control"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              placeholder="••••••••"
            />
          </div>

          <button
            type="submit"
            className="btn btn-primary"
            style={{ width: '100%', padding: '10px' }}
            disabled={loading}
          >
            {loading ? 'Authenticating...' : 'Sign In to SCMS'}
          </button>
        </form>

        <div style={{ marginTop: '24px', paddingTop: '20px', borderTop: '1px solid #e2e8f0' }}>
          <p style={{ fontSize: '0.75rem', color: '#64748b', marginBottom: '8px', fontWeight: '600', textTransform: 'uppercase' }}>
            Quick Demo Role Profiles
          </p>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '8px' }}>
            <button
              type="button"
              className="btn btn-secondary btn-sm"
              onClick={() => handleSelectDemo('registrar@scms.edu.in')}
            >
              👑 Registrar (Admin)
            </button>
            <button
              type="button"
              className="btn btn-secondary btn-sm"
              onClick={() => handleSelectDemo('priya.raghavan@scms.edu.in')}
            >
              👩‍🏫 Dr. Priya (Faculty)
            </button>
            <button
              type="button"
              className="btn btn-secondary btn-sm"
              onClick={() => handleSelectDemo('accounts@scms.edu.in')}
            >
              💳 Accounts Officer
            </button>
            <button
              type="button"
              className="btn btn-secondary btn-sm"
              onClick={() => handleSelectDemo('meera.nair@students.scms.edu.in')}
            >
              🎓 Meera Nair (Student)
            </button>
          </div>
          <p style={{ fontSize: '0.7rem', color: '#94a3b8', marginTop: '10px', textAlign: 'center' }}>
            Default seeded password is: <code>Demo@12345</code>
          </p>
        </div>
      </div>
    </div>
  );
}
