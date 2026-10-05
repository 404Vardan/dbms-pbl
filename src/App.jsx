import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Layout from './components/Layout';

import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Students from './pages/Students';
import StudentDetails from './pages/StudentDetails';
import Departments from './pages/Departments';
import Courses from './pages/Courses';
import Faculty from './pages/Faculty';
import Semesters from './pages/Semesters';
import Sections from './pages/Sections';
import Registration from './pages/Registration';
import Attendance from './pages/Attendance';
import Examinations from './pages/Examinations';
import Fees from './pages/Fees';
import Reports from './pages/Reports';

function ProtectedRoute({ children }) {
  const { user, loading } = useAuth();
  if (loading) {
    return <div style={{ padding: '40px', textAlign: 'center', color: '#64748b' }}>Authenticating user session...</div>;
  }
  // Allow unauthenticated demo preview if user hasn't explicitly signed in
  return children;
}

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Dashboard />} />
            <Route path="students" element={<Students />} />
            <Route path="students/:id" element={<StudentDetails />} />
            <Route path="departments" element={<Departments />} />
            <Route path="courses" element={<Courses />} />
            <Route path="faculty" element={<Faculty />} />
            <Route path="semesters" element={<Semesters />} />
            <Route path="sections" element={<Sections />} />
            <Route path="registration" element={<Registration />} />
            <Route path="attendance" element={<Attendance />} />
            <Route path="examinations" element={<Examinations />} />
            <Route path="fees" element={<Fees />} />
            <Route path="reports" element={<Reports />} />
          </Route>

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
