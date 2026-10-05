import React from 'react';
import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Layout() {
  const { user, profile, role, signOut } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await signOut();
    navigate('/login');
  };

  return (
    <div className="app-container">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="sidebar-brand-icon">S</div>
          <div className="sidebar-brand-text">
            <h1>SCMS ERP</h1>
            <span>College Management</span>
          </div>
        </div>

        <nav className="sidebar-nav">
          <div className="nav-section-title">Core Modules</div>
          <NavLink to="/" end className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <span>📊</span> Dashboard
          </NavLink>

          {(role === 'admin' || role === 'accounts') && (
            <NavLink to="/students" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
              <span>🎓</span> Students & Admissions
            </NavLink>
          )}

          {role === 'admin' && (
            <>
              <div className="nav-section-title">Academic Structure</div>
              <NavLink to="/departments" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                <span>🏛️</span> Departments & Programmes
              </NavLink>
              <NavLink to="/courses" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                <span>📚</span> Courses
              </NavLink>
              <NavLink to="/faculty" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                <span>👨‍🏫</span> Faculty Directory
              </NavLink>
              <NavLink to="/semesters" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                <span>📅</span> Semesters
              </NavLink>
              <NavLink to="/sections" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                <span>🏫</span> Section Allocation
              </NavLink>
            </>
          )}

          {(role === 'admin' || role === 'student') && (
            <NavLink to="/registration" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
              <span>📝</span> Course Registration
            </NavLink>
          )}

          {(role === 'admin' || role === 'faculty' || role === 'student') && (
            <>
              <div className="nav-section-title">Academics & Evaluation</div>
              <NavLink to="/attendance" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                <span>📋</span> Attendance Tracker
              </NavLink>
              <NavLink to="/examinations" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                <span>📝</span> Examinations & Grades
              </NavLink>
            </>
          )}

          {(role === 'admin' || role === 'accounts' || role === 'student') && (
            <>
              <div className="nav-section-title">Finance</div>
              <NavLink to="/fees" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
                <span>💳</span> Fee Bills & Payments
              </NavLink>
            </>
          )}

          <div className="nav-section-title">Analytics</div>
          <NavLink to="/reports" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <span>📈</span> Institutional Reports
          </NavLink>
        </nav>

        <div className="sidebar-footer">
          <div className="user-badge">
            <div className="user-info-text">
              <div className="user-name">{profile?.full_name || user?.email || 'Administrator'}</div>
              <div className="user-role-tag">{role}</div>
            </div>
            <button
              onClick={handleLogout}
              className="btn btn-secondary btn-sm"
              title="Sign Out"
              style={{ padding: '4px 6px', background: 'transparent', color: '#cbd5e1', borderColor: 'rgba(255,255,255,0.2)' }}
            >
              🚪
            </button>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="content-wrapper">
        <header className="topbar">
          <div className="page-title">
            <h2>Student & College Management System</h2>
          </div>
          <div className="topbar-actions">
            <span className="badge badge-neutral" style={{ fontSize: '0.8rem' }}>
              Academic Session: <strong>2026-27 (Odd)</strong>
            </span>
            <span className="badge badge-success">
              Database Online
            </span>
          </div>
        </header>

        <main className="main-content">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
