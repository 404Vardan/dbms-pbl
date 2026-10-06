import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { formatDbError } from '../lib/errors';

export default function Registration() {
  const [students, setStudents] = useState([]);
  const [sections, setSections] = useState([]);
  const [registrations, setRegistrations] = useState([]);
  const [selectedStudent, setSelectedStudent] = useState('');
  const [selectedSection, setSelectedSection] = useState('');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    try {
      const data = await api.getRegistrationOptions();
      setStudents(data.students || []);
      setSections(data.sections || []);
      setRegistrations(data.registrations || []);

      if (data.students?.length > 0 && !selectedStudent) {
        setSelectedStudent(data.students[0].student_id);
      }
      if (data.sections?.length > 0 && !selectedSection) {
        setSelectedSection(data.sections[0].section_id);
      }
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  const handleRegister = async (e) => {
    e.preventDefault();
    if (!selectedStudent || !selectedSection) return;

    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const res = await api.registerCourse(Number(selectedStudent), Number(selectedSection));
      setSuccess(res.message || 'Course Section Registration confirmed by MySQL database!');
      await loadData();
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setSubmitting(false);
    }
  };

  const currentSection = sections.find(s => s.section_id === Number(selectedSection));

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '1.35rem', fontWeight: '700' }}>Course Registration & Section Allocation</h2>
        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
          Enrol students into lecture/lab sections with real-time MySQL database capacity and duplicate checks.
        </p>
      </div>

      {error && <div className="alert alert-danger"><span>⚠️</span> {error}</div>}
      {success && <div className="alert alert-success"><span>✅</span> {success}</div>}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(360px, 1fr))', gap: '24px', marginBottom: '28px' }}>
        <div className="card">
          <div className="card-header">
            <h3>New Course Enrolment (Trigger Validation)</h3>
          </div>
          <form onSubmit={handleRegister} className="card-body">
            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label className="form-label">Select Student *</label>
              <select
                className="form-control"
                value={selectedStudent}
                onChange={(e) => setSelectedStudent(e.target.value)}
                required
              >
                {students.map((s) => (
                  <option key={s.student_id} value={s.student_id}>
                    {s.full_name} ({s.reg_no})
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group" style={{ marginBottom: '16px' }}>
              <label className="form-label">Select Section *</label>
              <select
                className="form-control"
                value={selectedSection}
                onChange={(e) => setSelectedSection(e.target.value)}
                required
              >
                {sections.map((s) => (
                  <option key={s.section_id} value={s.section_id}>
                    {s.course_code} Sec {s.section_code} ({s.faculty_name}) — Seats: {s.remaining_seats}/{s.capacity} {s.is_full ? '[FULL]' : ''}
                  </option>
                ))}
              </select>
            </div>

            {currentSection && (
              <div style={{
                padding: '12px',
                borderRadius: '6px',
                backgroundColor: currentSection.is_full ? '#fef2f2' : '#f8fafc',
                border: `1px solid ${currentSection.is_full ? '#fecaca' : '#e2e8f0'}`,
                marginBottom: '16px',
                fontSize: '0.85rem'
              }}>
                <div style={{ fontWeight: '600', marginBottom: '4px' }}>
                  {currentSection.course_code} - {currentSection.course_name}
                </div>
                <div>Instructor: <strong>{currentSection.faculty_name}</strong></div>
                <div>Room: <strong>{currentSection.room_no}</strong> • Credits: <strong>{currentSection.credits}</strong></div>
                <div style={{ marginTop: '6px' }}>
                  Occupancy: <strong>{currentSection.registered_count} / {currentSection.capacity}</strong> students
                  ({currentSection.remaining_seats} seats remaining)
                </div>
              </div>
            )}

            <button
              type="submit"
              className="btn btn-primary"
              style={{ width: '100%', padding: '10px' }}
              disabled={submitting}
            >
              {submitting ? 'Verifying with MySQL Database...' : 'Register Course Section'}
            </button>
          </form>
        </div>

        <div className="card">
          <div className="card-header">
            <h3>Active Section Occupancies (MySQL View)</h3>
          </div>
          <div className="table-responsive" style={{ maxHeight: '350px', overflowY: 'auto' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Course</th>
                  <th>Sec</th>
                  <th>Faculty</th>
                  <th>Occupancy</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {sections.map((sec) => (
                  <tr key={sec.section_id} style={{ backgroundColor: sec.is_full ? '#fff5f5' : 'inherit' }}>
                    <td style={{ fontWeight: '600' }}>{sec.course_code}</td>
                    <td>{sec.section_code}</td>
                    <td style={{ fontSize: '0.8rem' }}>{sec.faculty_name}</td>
                    <td>
                      <strong>{sec.registered_count}</strong> / {sec.capacity}
                    </td>
                    <td>
                      {sec.is_full ? (
                        <span className="badge badge-danger">FULL (0 seats)</span>
                      ) : (
                        <span className="badge badge-success">{sec.remaining_seats} left</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <h3>Recent Registrations Log</h3>
        </div>
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Reg ID</th>
                <th>Student</th>
                <th>Reg No</th>
                <th>Course</th>
                <th>Section</th>
                <th>Registered On</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {registrations.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '20px', color: '#94a3b8' }}>
                    No registrations found.
                  </td>
                </tr>
              ) : (
                registrations.map((r) => (
                  <tr key={r.registration_id}>
                    <td>#{r.registration_id}</td>
                    <td style={{ fontWeight: '500' }}>{r.student_name}</td>
                    <td><code>{r.reg_no}</code></td>
                    <td>{r.course_code} - {r.course_name}</td>
                    <td>Sec {r.section_code} ({r.room_no})</td>
                    <td>{r.registered_on?.split('T')[0] || r.registered_on}</td>
                    <td>
                      <span className="badge badge-success">{r.status}</span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
