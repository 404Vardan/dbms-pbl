import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
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
      const { data, error: secErr } = await supabase
        .from('section')
        .select(`
          section_id, section_code, room_no,
          course:course_id (course_code, course_name),
          faculty:faculty_id (full_name)
        `)
        .order('section_id');

      if (secErr) throw secErr;
      setSections(data || []);
      if (data && data.length > 0) {
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
      // 1. Fetch section roster (active registrations)
      const { data: regList, error: regErr } = await supabase
        .from('registration')
        .select(`
          registration_id, student_id,
          student:student_id (student_id, reg_no, full_name)
        `)
        .eq('section_id', selectedSection)
        .eq('status', 'Registered')
        .order('registration_id');

      if (regErr) throw regErr;
      setRoster(regList || []);

      // 2. Fetch attendance already marked for this date
      const regIds = (regList || []).map(r => r.registration_id);
      let existingAtt = {};
      if (regIds.length > 0) {
        const { data: attList } = await supabase
          .from('attendance')
          .select('registration_id, status')
          .eq('attendance_date', date)
          .in('registration_id', regIds);

        (attList || []).forEach(a => {
          existingAtt[a.registration_id] = a.status;
        });
      }

      // Default status to Present if not marked
      const initialMap = {};
      (regList || []).forEach(r => {
        initialMap[r.registration_id] = existingAtt[r.registration_id] || 'Present';
      });
      setAttendanceMap(initialMap);

      // 3. Fetch attendance summary stats for this section
      const { data: sumList } = await supabase
        .from('v_attendance_summary')
        .select('*')
        .eq('section_id', selectedSection);

      setSummaryList(sumList || []);
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

      // Try RPC first
      const { error: rpcErr } = await supabase.rpc('save_attendance', {
        p_section_id: Number(selectedSection),
        p_date: date,
        p_entries: entries
      });

      if (rpcErr) {
        console.warn('RPC save_attendance failed, upserting directly...', rpcErr);
        // Direct upsert
        const rowsToInsert = entries.map(e => ({
          registration_id: e.registration_id,
          attendance_date: date,
          status: e.status
        }));

        const { error: upsertErr } = await supabase
          .from('attendance')
          .upsert(rowsToInsert, { onConflict: 'registration_id, attendance_date' });

        if (upsertErr) throw upsertErr;
      }

      setSuccess(`Attendance for ${entries.length} students on ${date} saved successfully!`);
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
          Mark, verify, and correct student daily attendance. Database validates date bounds and status constraints.
        </p>
      </div>

      {error && <div className="alert alert-danger"><span>⚠️</span> {error}</div>}
      {success && <div className="alert alert-success"><span>✅</span> {success}</div>}

      {/* Control Bar */}
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
                  {s.course?.course_code} - Sec {s.section_code} ({s.faculty?.full_name})
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
            {saving ? 'Persisting to DB...' : '💾 Save Attendance'}
          </button>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(420px, 1fr))', gap: '24px' }}>
        {/* Roster Attendance Sheet */}
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
                      <td><code>{r.student?.reg_no}</code></td>
                      <td style={{ fontWeight: '500' }}>{r.student?.full_name}</td>
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

        {/* Section Cumulative Percentage & Shortage Tracker */}
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
