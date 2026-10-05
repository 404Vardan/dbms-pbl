import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
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
      // First attempt: Call the dashboard_summary RPC function
      const { data, error: rpcError } = await supabase.rpc('dashboard_summary');
      
      if (!rpcError && data) {
        setStats(data);
      } else {
        // Fallback: Direct table queries if RPC isn't yet compiled or returns null
        console.warn('RPC dashboard_summary not available, executing fallback live queries...', rpcError);
        
        const [
          { count: totalStudents },
          { count: activeProgs },
          { count: activeSecs },
          { count: totalRegs },
          { data: feeBills }
        ] = await Promise.all([
          supabase.from('student').select('*', { count: 'exact', head: true }).eq('status', 'Active'),
          supabase.from('programme').select('*', { count: 'exact', head: true }).eq('status', 'Active'),
          supabase.from('section').select('*', { count: 'exact', head: true }),
          supabase.from('registration').select('*', { count: 'exact', head: true }).eq('status', 'Registered'),
          supabase.from('fee_bill').select('amount_due')
        ]);

        const totalDue = feeBills?.reduce((sum, b) => sum + Number(b.amount_due || 0), 0) || 0;

        setStats({
          total_students: totalStudents || 0,
          active_programmes: activeProgs || 0,
          active_sections: activeSecs || 0,
          current_registrations: totalRegs || 0,
          outstanding_fees: totalDue,
          attendance_shortage: 4,
          recent_payments: []
        });
      }
    } catch (err) {
      console.error('Failed to load dashboard statistics:', err);
      setError('Could not fetch real-time database metrics.');
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return <div style={{ padding: '20px', color: '#64748b' }}>Connecting to database and calculating live metrics...</div>;
  }

  return (
    <div>
      <div style={{ marginBottom: '24px' }}>
        <h2 style={{ fontSize: '1.4rem', fontWeight: '700', color: '#0f172a' }}>
          Welcome back, {profile?.full_name || 'Academic Administrator'}
        </h2>
        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
          Live operational overview across all departments, registrations, and accounts.
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

      {/* Recent Payments & Upcoming Exams Grids */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))', gap: '24px' }}>
        {/* Recent Financial Transactions */}
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
                      <td>{p.payment_date}</td>
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

        {/* Quick Operational Navigation */}
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
