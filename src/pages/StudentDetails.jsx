import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { formatDbError } from '../lib/errors';

export default function StudentDetails() {
  const { id } = useParams();
  const [student, setStudent] = useState(null);
  const [history, setHistory] = useState([]);
  const [bills, setBills] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadStudentData();
  }, [id]);

  async function loadStudentData() {
    setLoading(true);
    try {
      const [
        { data: st, error: stErr },
        { data: hist, error: histErr },
        { data: fbList, error: fbErr }
      ] = await Promise.all([
        supabase
          .from('student')
          .select(`
            *,
            programme:programme_id (programme_code, programme_name),
            guardian (*)
          `)
          .eq('student_id', id)
          .single(),
        supabase
          .from('v_student_academic_history')
          .select('*')
          .eq('student_id', id),
        supabase
          .from('v_fee_dues')
          .select('*')
          .eq('student_id', id)
      ]);

      if (stErr) throw stErr;
      setStudent(st);
      setHistory(hist || []);
      setBills(fbList || []);
    } catch (err) {
      console.error(err);
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return <div style={{ padding: '24px', color: '#64748b' }}>Loading comprehensive student profile...</div>;
  }

  if (!student) {
    return (
      <div className="alert alert-danger">
        <span>⚠️</span> Student record not found or inaccessible.
      </div>
    );
  }

  const totalOutstanding = bills.reduce((sum, b) => sum + Number(b.balance || 0), 0);

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <Link to="/students" className="btn btn-secondary btn-sm" style={{ marginBottom: '12px' }}>
          ← Back to Students Directory
        </Link>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 style={{ fontSize: '1.4rem', fontWeight: '700' }}>{student.full_name}</h2>
            <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
              Registration No: <code>{student.reg_no}</code> • Enrolled: {student.admission_date}
            </p>
          </div>
          <span className={`badge ${student.status === 'Active' ? 'badge-success' : 'badge-danger'}`} style={{ fontSize: '0.85rem' }}>
            {student.status}
          </span>
        </div>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      {/* Profile & Guardian Summary */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '20px', marginBottom: '24px' }}>
        <div className="card">
          <div className="card-header">
            <h3>Academic & Contact Information</h3>
          </div>
          <div className="card-body" style={{ fontSize: '0.875rem' }}>
            <div style={{ display: 'grid', gridTemplateColumns: '130px 1fr', gap: '10px' }}>
              <span style={{ color: '#64748b' }}>Programme:</span>
              <strong>{student.programme?.programme_code} - {student.programme?.programme_name}</strong>

              <span style={{ color: '#64748b' }}>Date of Birth:</span>
              <span>{student.dob}</span>

              <span style={{ color: '#64748b' }}>Email:</span>
              <span>{student.email}</span>

              <span style={{ color: '#64748b' }}>Phone:</span>
              <span>{student.phone}</span>
            </div>
          </div>
        </div>

        <div className="card">
          <div className="card-header">
            <h3>Registered Guardian Record</h3>
          </div>
          <div className="card-body" style={{ fontSize: '0.875rem' }}>
            {student.guardian && student.guardian.length > 0 ? (
              <div style={{ display: 'grid', gridTemplateColumns: '130px 1fr', gap: '10px' }}>
                <span style={{ color: '#64748b' }}>Guardian Name:</span>
                <strong>{student.guardian[0].name} ({student.guardian[0].relation})</strong>

                <span style={{ color: '#64748b' }}>Contact Phone:</span>
                <span>{student.guardian[0].phone}</span>

                <span style={{ color: '#64748b' }}>Email:</span>
                <span>{student.guardian[0].email || 'N/A'}</span>

                <span style={{ color: '#64748b' }}>Address:</span>
                <span>{student.guardian[0].address || 'N/A'}</span>
              </div>
            ) : (
              <span style={{ color: '#94a3b8' }}>No linked guardian record found.</span>
            )}
          </div>
        </div>
      </div>

      {/* Academic Registrations & Grades */}
      <div className="card">
        <div className="card-header">
          <h3>Course Registrations & Examination Results</h3>
        </div>
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Semester</th>
                <th>Course</th>
                <th>Sec</th>
                <th>Instructor</th>
                <th>Attendance</th>
                <th>Mid-Term</th>
                <th>End-Term</th>
                <th>Grade</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {history.length === 0 ? (
                <tr>
                  <td colSpan="9" style={{ textAlign: 'center', padding: '20px', color: '#94a3b8' }}>
                    No registered courses recorded for this student.
                  </td>
                </tr>
              ) : (
                history.map((h, idx) => (
                  <tr key={idx}>
                    <td><span className="badge badge-neutral">{h.semester_label}</span></td>
                    <td style={{ fontWeight: '500' }}>{h.course_code} - {h.course_name}</td>
                    <td>{h.section_code}</td>
                    <td style={{ fontSize: '0.8rem' }}>{h.faculty_name}</td>
                    <td>
                      <span className={`badge ${Number(h.attendance_pct || 0) < 75 ? 'badge-danger' : 'badge-success'}`}>
                        {h.attendance_pct ? `${h.attendance_pct}%` : 'N/A'}
                      </span>
                    </td>
                    <td>{h.mid_term_marks ?? '—'}</td>
                    <td>{h.end_term_marks ?? '—'}</td>
                    <td>
                      {h.final_grade ? (
                        <span className={`badge ${h.final_grade === 'F' ? 'badge-danger' : 'badge-primary'}`}>
                          {h.final_grade} ({h.final_grade_point})
                        </span>
                      ) : '—'}
                    </td>
                    <td>
                      <span className={`badge ${h.registration_status === 'Completed' ? 'badge-neutral' : 'badge-success'}`}>
                        {h.registration_status}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Fee Statement */}
      <div className="card">
        <div className="card-header">
          <h3>Financial Statement & Dues</h3>
          <span style={{ fontWeight: '600', color: totalOutstanding > 0 ? '#b91c1c' : '#15803d' }}>
            Total Outstanding: ₹{totalOutstanding.toLocaleString('en-IN')}
          </span>
        </div>
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Bill #</th>
                <th>Semester</th>
                <th>Due Date</th>
                <th>Amount Due</th>
                <th>Amount Paid</th>
                <th>Balance</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {bills.length === 0 ? (
                <tr>
                  <td colSpan="7" style={{ textAlign: 'center', padding: '20px', color: '#94a3b8' }}>
                    No fee bills generated.
                  </td>
                </tr>
              ) : (
                bills.map((b) => (
                  <tr key={b.bill_id}>
                    <td>#{b.bill_id}</td>
                    <td>{b.semester_label}</td>
                    <td>{b.due_date}</td>
                    <td>₹{Number(b.amount_due).toLocaleString('en-IN')}</td>
                    <td style={{ color: '#15803d', fontWeight: '500' }}>
                      ₹{Number(b.amount_paid).toLocaleString('en-IN')}
                    </td>
                    <td style={{ color: Number(b.balance) > 0 ? '#b91c1c' : '#64748b', fontWeight: '600' }}>
                      ₹{Number(b.balance).toLocaleString('en-IN')}
                    </td>
                    <td>
                      <span className={`badge ${b.status === 'Paid' ? 'badge-success' : b.status === 'Partially Paid' ? 'badge-warning' : 'badge-danger'}`}>
                        {b.status}
                      </span>
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
