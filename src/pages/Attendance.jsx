import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { formatDbError } from '../lib/errors';

export default function Attendance() {
  const [sections, setSections] = useState([]);
  const [selectedSection, setSelectedSection] = useState('');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [roster, setRoster] = useState([]);
  const [attendanceMap, setAttendanceMap] = useState({});
  const [summaryList, setSummaryList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    loadSections();
  }, []);

  useEffect(() => {
    if (selectedSection) {
      loadRosterAndAttendance();
    }
  }, [selectedSection, date]);

  async function loadSections() {
    setLoading(true);
    try {
      const data = await api.getAttendanceSections();
      setSections(data || []);
      if (data?.length > 0 && !selectedSection) {
        setSelectedSection(data[0].section_id);
      }
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  async function loadRosterAndAttendance() {
    setError(null);
    setSuccess(null);
    try {
      const res = await api.getAttendanceRoster(selectedSection, date);
      setRoster(res.roster || []);
      setSummaryList(res.summary || []);

      const existingAtt = {};
      (res.attendanceRecords || []).forEach(a => {
        existingAtt[a.registration_id] = a.status;
      });

      const initialMap = {};
      (res.roster || []).forEach(r => {
        initialMap[r.registration_id] = existingAtt[r.registration_id] || 'Present';
      });
      setAttendanceMap(initialMap);
    } catch (err) {
      setError(formatDbError(err));
    }
  }

  const handleStatusChange = (regId, newStatus) => {
    setAttendanceMap(prev => ({ ...prev, [regId]: newStatus }));
  };

  const handleSaveAttendance = async () => {
    setSaving(true);
    setError(null);
    setSuccess(null);

    try {
      const entries = Object.keys(attendanceMap).map(regId => ({
        registration_id: Number(regId),
        status: attendanceMap[regId]
      }));

      const res = await api.saveAttendance({
        section_id: Number(selectedSection),
        date,
        entries
      });

      setSuccess(res.message || `Attendance for ${entries.length} students on ${date} saved successfully!`);
      await loadRosterAndAttendance();
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '1.35rem', fontWeight: '700' }}>Faculty Attendance Register</h2>
        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
          Mark, verify, and correct student daily attendance. MySQL validates date bounds and status constraints.
        </p>
      </div>

      {error && <div className="alert alert-danger"><span>⚠️</span> {error}</div>}
      {success && <div className="alert alert-success"><span>✅</span> {success}</div>}

      <div className="card" style={{ marginBottom: '24px' }}>
        <div className="card-body" style={{ display: 'flex', gap: '20px', flexWrap: 'wrap', alignItems: 'flex-end' }}>
          <div className="form-group" style={{ minWidth: '280px' }}>
            <label className="form-label">Course & Section</label>
            <select
              className="form-control"
              value={selectedSection}
              onChange={(e) => setSelectedSection(e.target.value)}
            >
              {sections.map(s => (
                <option key={s.section_id} value={s.section_id}>
                  {s.course_code} - Sec {s.section_code} ({s.faculty_name})
                </option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Attendance Date</label>
            <input
              type="date"
              className="form-control"
              value={date}
              max={new Date().toISOString().split('T')[0]}
              onChange={(e) => setDate(e.target.value)}
            />
          </div>

          <button
            className="btn btn-primary"
            onClick={handleSaveAttendance}
            disabled={saving || roster.length === 0}
            style={{ height: '38px' }}
          >
            {saving ? 'Persisting to MySQL...' : '💾 Save Attendance'}
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(420px, 1fr))', gap: '24px' }}>
        <div className="card">
          <div className="card-header">
            <h3>Daily Session Register ({date})</h3>
            <span className="badge badge-neutral">{roster.length} Enrolled</span>
          </div>
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Reg No</th>
                  <th>Student Name</th>
                  <th style={{ textAlign: 'center' }}>Mark Status</th>
                </tr>
              </thead>
              <tbody>
                {roster.length === 0 ? (
                  <tr>
                    <td colSpan="3" style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                      No active students found in this section roster.
                    </td>
                  </tr>
                ) : (
                  roster.map(r => (
                    <tr key={r.registration_id}>
                      <td><code>{r.reg_no}</code></td>
                      <td style={{ fontWeight: '500' }}>{r.full_name}</td>
                      <td style={{ textAlign: 'center' }}>
                        <div style={{ display: 'inline-flex', gap: '6px' }}>
                          {['Present', 'Absent', 'Late'].map(status => (
                            <button
                              key={status}
                              type="button"
                              onClick={() => handleStatusChange(r.registration_id, status)}
                              className={`btn btn-sm ${
                                attendanceMap[r.registration_id] === status
                                  ? status === 'Present'
                                    ? 'btn-primary'
                                    : status === 'Absent'
                                    ? 'btn-danger'
                                    : 'btn-secondary'
                                  : 'btn-secondary'
                              }`}
                              style={{
                                opacity: attendanceMap[r.registration_id] === status ? 1 : 0.6,
                                fontWeight: attendanceMap[r.registration_id] === status ? '700' : '400'
                              }}
                            >
                              {status}
                            </button>
                          ))}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <h3>Cumulative Attendance & Shortage Flag (&lt;75%)</h3>
          </div>
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Reg No</th>
                  <th>Student</th>
                  <th>Attended / Total</th>
                  <th>Percentage</th>
                  <th>Shortage Flag</th>
                </tr>
              </thead>
              <tbody>
                {summaryList.length === 0 ? (
                  <tr>
                    <td colSpan="5" style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                      No session history recorded yet.
                    </td>
                  </tr>
                ) : (
                  summaryList.map(s => (
                    <tr key={s.registration_id} style={{ backgroundColor: s.is_shortage ? '#fff5f5' : 'inherit' }}>
                      <td><code>{s.reg_no}</code></td>
                      <td style={{ fontWeight: '500' }}>{s.student_name}</td>
                      <td>
                        {Number(s.present_count || 0) + Number(s.late_count || 0)} / {s.total_classes}
                      </td>
                      <td style={{ fontWeight: '600' }}>
                        {s.attendance_pct != null ? `${s.attendance_pct}%` : 'N/A'}
                      </td>
                      <td>
                        {s.is_shortage ? (
                          <span className="badge badge-danger">SHORTAGE (&lt;75%)</span>
                        ) : (
                          <span className="badge badge-success">Regular</span>
                        )}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
