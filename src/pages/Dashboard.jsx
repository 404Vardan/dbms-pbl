import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { useAuth } from '../context/AuthContext';
import { Link } from 'react-router-dom';

export default function Dashboard() {
  const { role, profile } = useAuth();
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadDashboard();
  }, [role]);

  async function loadDashboard() {
    setLoading(true);
    setError(null);
    try {
      const data = await api.getDashboardStats();
      setStats(data);
    } catch (err) {
      console.error('Failed to load dashboard statistics:', err);
      setError('Could not connect to MySQL backend server. Ensure server is running.');
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return <div style={{ padding: '20px', color: '#64748b' }}>Connecting to MySQL database and calculating live metrics...</div>;
  }

  return (
    <div>
      <div style={{ marginBottom: '24px' }}>
        <h2 style={{ fontSize: '1.4rem', fontWeight: '700', color: '#0f172a' }}>
          Welcome back, {profile?.fullName || 'Academic Administrator'}
        </h2>
        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
          Real-time operational metrics queried directly from MySQL <code>scms_db</code>.
        </p>
      </div>

      {error && (
        <div className="alert alert-warning">
          <span>⚠️</span> {error}
        </div>
      )}

      {/* KPI Cards */}
      <div className="stats-grid">
        <div className="stat-card">
          <div className="stat-label">Active Students</div>
          <div className="stat-value">{stats?.total_students ?? 0}</div>
          <div className="stat-desc">Enrolled in university programmes</div>
        </div>

        <div className="stat-card">
          <div className="stat-label">Academic Programmes</div>
          <div className="stat-value">{stats?.active_programmes ?? 0}</div>
          <div className="stat-desc">Across all 5 departments</div>
        </div>

        <div className="stat-card">
          <div className="stat-label">Active Sections</div>
          <div className="stat-value">{stats?.active_sections ?? 0}</div>
          <div className="stat-desc">Allocated this semester</div>
        </div>

        <div className="stat-card">
          <div className="stat-label">Registrations</div>
          <div className="stat-value">{stats?.current_registrations ?? 0}</div>
          <div className="stat-desc">Course enrolments this term</div>
        </div>

        <div className="stat-card danger">
          <div className="stat-label">Attendance Shortage</div>
          <div className="stat-value">{stats?.attendance_shortage ?? 0}</div>
          <div className="stat-desc">Students below mandatory 75%</div>
        </div>

        <div className="stat-card warning">
          <div className="stat-label">Outstanding Fees</div>
          <div className="stat-value">
            ₹{Number(stats?.outstanding_fees || 0).toLocaleString('en-IN')}
          </div>
          <div className="stat-desc">Pending tuition fee recovery</div>
        </div>
      </div>

      {/* Recent Payments & Navigation */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '24px' }}>
        <div className="card">
          <div className="card-header">
            <h3>Recent Fee Receipts</h3>
            <Link to="/fees" className="btn btn-secondary btn-sm">View All Bills</Link>
          </div>
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Student</th>
                  <th>Reg No</th>
                  <th>Date</th>
                  <th>Amount</th>
                  <th>Mode</th>
                </tr>
              </thead>
              <tbody>
                {stats?.recent_payments && stats.recent_payments.length > 0 ? (
                  stats.recent_payments.map((p, idx) => (
                    <tr key={idx}>
                      <td style={{ fontWeight: '500' }}>{p.student_name}</td>
                      <td><code>{p.reg_no}</code></td>
                      <td>{p.payment_date?.split('T')[0] || p.payment_date}</td>
                      <td style={{ fontWeight: '600', color: '#15803d' }}>
                        ₹{Number(p.amount_paid).toLocaleString('en-IN')}
                      </td>
                      <td>
                        <span className="badge badge-neutral">{p.payment_mode}</span>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="5" style={{ textAlign: 'center', color: '#94a3b8', padding: '24px' }}>
                      No recent payment transactions found.
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <h3>Core Administrative Actions</h3>
          </div>
          <div className="card-body" style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <Link to="/students" className="btn btn-secondary" style={{ justifyContent: 'flex-start', padding: '12px' }}>
              <span>➕</span> New Student Admission
            </Link>
            <Link to="/registration" className="btn btn-secondary" style={{ justifyContent: 'flex-start', padding: '12px' }}>
              <span>📝</span> Section Enrolment
            </Link>
            <Link to="/attendance" className="btn btn-secondary" style={{ justifyContent: 'flex-start', padding: '12px' }}>
              <span>📋</span> Mark Section Attendance
            </Link>
            <Link to="/examinations" className="btn btn-secondary" style={{ justifyContent: 'flex-start', padding: '12px' }}>
              <span>🎯</span> Enter Exam Marks
            </Link>
            <Link to="/fees" className="btn btn-secondary" style={{ justifyContent: 'flex-start', padding: '12px' }}>
              <span>💳</span> Generate Fee Bill
            </Link>
            <Link to="/reports" className="btn btn-primary" style={{ justifyContent: 'flex-start', padding: '12px' }}>
              <span>📊</span> Run SQL Analytical Reports
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
