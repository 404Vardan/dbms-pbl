import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { formatDbError } from '../lib/errors';

export default function Reports() {
  const [activeTab, setActiveTab] = useState('occupancy');
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadReportData(activeTab);
  }, [activeTab]);

  async function loadReportData(tab) {
    setLoading(true);
    setError(null);
    try {
      const res = await api.getReport(tab);
      setData(res || []);
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '1.35rem', fontWeight: '700' }}>Institutional SQL Analytical Reports</h2>
        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
          Real-time analytical views queried from MySQL featuring multi-table joins, aggregates, and calculations.
        </p>
      </div>

      {error && <div className="alert alert-danger"><span>⚠️</span> {error}</div>}

      <div style={{ display: 'flex', gap: '8px', borderBottom: '1px solid #cbd5e1', marginBottom: '20px', flexWrap: 'wrap' }}>
        {[
          { id: 'occupancy', label: '1. Section Occupancy & Capacity' },
          { id: 'attendance', label: '2. Attendance Shortage Analysis' },
          { id: 'results', label: '3. Examination Performance & Pass %' },
          { id: 'history', label: '4. Student Academic History' },
          { id: 'dues', label: '5. Student Fee Dues Recovery' },
          { id: 'departments', label: '6. Department Academic Summary' }
        ].map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            style={{
              padding: '10px 14px',
              border: 'none',
              background: 'transparent',
              fontSize: '0.85rem',
              fontWeight: activeTab === tab.id ? '600' : '500',
              color: activeTab === tab.id ? '#1e40af' : '#64748b',
              borderBottom: activeTab === tab.id ? '2px solid #1e40af' : '2px solid transparent',
              cursor: 'pointer'
            }}
          >
            {tab.label}
          </button>
        ))}
      </div>

      <div className="card">
        <div className="card-header">
          <h3>
            MySQL View: <code>v_{activeTab === 'departments' ? 'department_summary' : activeTab === 'results' ? 'result_analysis' : activeTab === 'history' ? 'student_academic_history' : activeTab === 'dues' ? 'student_dues' : activeTab === 'attendance' ? 'attendance_summary' : 'section_occupancy'}</code>
          </h3>
          <span className="badge badge-neutral">{data.length} Rows Computed</span>
        </div>
        <div className="table-responsive">
          {loading ? (
            <div style={{ textAlign: 'center', padding: '30px', color: '#64748b' }}>
              Executing SQL analytical view query on MySQL server...
            </div>
          ) : (
            <table className="data-table">
              {activeTab === 'occupancy' && (
                <>
                  <thead>
                    <tr>
                      <th>Course</th>
                      <th>Course Name</th>
                      <th>Sec</th>
                      <th>Instructor</th>
                      <th>Room</th>
                      <th>Capacity</th>
                      <th>Registered</th>
                      <th>Available Seats</th>
                      <th>Occupancy %</th>
                      <th>Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.map((row) => (
                      <tr key={row.section_id}>
                        <td><code>{row.course_code}</code></td>
                        <td>{row.course_name}</td>
                        <td>{row.section_code}</td>
                        <td>{row.faculty_name}</td>
                        <td>{row.room_no}</td>
                        <td>{row.capacity}</td>
                        <td><strong>{row.registered_count}</strong></td>
                        <td>{row.remaining_seats}</td>
                        <td>{row.occupancy_pct}%</td>
                        <td>
                          {row.is_full ? (
                            <span className="badge badge-danger">FULL</span>
                          ) : (
                            <span className="badge badge-success">Available</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </>
              )}

              {activeTab === 'attendance' && (
                <>
                  <thead>
                    <tr>
                      <th>Reg No</th>
                      <th>Student Name</th>
                      <th>Course</th>
                      <th>Sec</th>
                      <th>Faculty</th>
                      <th>Total Sessions</th>
                      <th>Present</th>
                      <th>Late</th>
                      <th>Absent</th>
                      <th>Attendance %</th>
                      <th>Action Required</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.map((row) => (
                      <tr key={row.registration_id} style={{ backgroundColor: row.is_shortage ? '#fff5f5' : 'inherit' }}>
                        <td><code>{row.reg_no}</code></td>
                        <td style={{ fontWeight: '500' }}>{row.student_name}</td>
                        <td>{row.course_code}</td>
                        <td>{row.section_code}</td>
                        <td>{row.faculty_name}</td>
                        <td>{row.total_classes}</td>
                        <td>{row.present_count}</td>
                        <td>{row.late_count}</td>
                        <td>{row.absent_count}</td>
                        <td style={{ fontWeight: '700' }}>{row.attendance_pct}%</td>
                        <td>
                          {row.is_shortage ? (
                            <span className="badge badge-danger">Shortage Notice (&lt;75%)</span>
                          ) : (
                            <span className="badge badge-success">Compliant</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </>
              )}

              {activeTab === 'results' && (
                <>
                  <thead>
                    <tr>
                      <th>Course</th>
                      <th>Sec</th>
                      <th>Faculty</th>
                      <th>Exam Type</th>
                      <th>Candidates</th>
                      <th>Evaluated</th>
                      <th>Average %</th>
                      <th>Highest %</th>
                      <th>Passed</th>
                      <th>Failed</th>
                      <th>Pass %</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.map((row, idx) => (
                      <tr key={idx}>
                        <td><code>{row.course_code}</code></td>
                        <td>{row.section_code}</td>
                        <td>{row.faculty_name}</td>
                        <td><span className="badge badge-neutral">{row.exam_type}</span></td>
                        <td>{row.candidates}</td>
                        <td>{row.evaluated}</td>
                        <td style={{ fontWeight: '600' }}>{row.average_pct}%</td>
                        <td style={{ color: '#15803d' }}>{row.highest_pct}%</td>
                        <td>{row.passed}</td>
                        <td style={{ color: row.failed > 0 ? '#b91c1c' : '#64748b' }}>{row.failed}</td>
                        <td>
                          <span className={`badge ${Number(row.pass_pct || 0) >= 80 ? 'badge-success' : 'badge-warning'}`}>
                            {row.pass_pct}%
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </>
              )}

              {activeTab === 'history' && (
                <>
                  <thead>
                    <tr>
                      <th>Reg No</th>
                      <th>Student</th>
                      <th>Semester</th>
                      <th>Course Code</th>
                      <th>Course Name</th>
                      <th>Credits</th>
                      <th>Mid-Term</th>
                      <th>End-Term</th>
                      <th>Final Grade</th>
                      <th>Points</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.map((row, idx) => (
                      <tr key={idx}>
                        <td><code>{row.reg_no}</code></td>
                        <td style={{ fontWeight: '500' }}>{row.student_name}</td>
                        <td>{row.semester_label}</td>
                        <td><code>{row.course_code}</code></td>
                        <td>{row.course_name}</td>
                        <td>{row.credits}</td>
                        <td>{row.mid_term_marks ?? '—'}</td>
                        <td>{row.end_term_marks ?? '—'}</td>
                        <td>
                          {row.final_grade ? (
                            <span className={`badge ${row.final_grade === 'F' ? 'badge-danger' : 'badge-primary'}`}>
                              {row.final_grade}
                            </span>
                          ) : '—'}
                        </td>
                        <td><strong>{row.final_grade_point ?? '—'}</strong></td>
                      </tr>
                    ))}
                  </tbody>
                </>
              )}

              {activeTab === 'dues' && (
                <>
                  <thead>
                    <tr>
                      <th>Reg No</th>
                      <th>Student Name</th>
                      <th>Status</th>
                      <th>Total Invoiced</th>
                      <th>Total Paid</th>
                      <th>Outstanding Balance</th>
                      <th>Overdue Invoices</th>
                      <th>Max Overdue (Days)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.map((row) => (
                      <tr key={row.student_id}>
                        <td><code>{row.reg_no}</code></td>
                        <td style={{ fontWeight: '500' }}>{row.student_name}</td>
                        <td><span className="badge badge-neutral">{row.student_status}</span></td>
                        <td>₹{Number(row.total_billed).toLocaleString('en-IN')}</td>
                        <td style={{ color: '#15803d' }}>₹{Number(row.total_paid).toLocaleString('en-IN')}</td>
                        <td style={{ fontWeight: '700', color: Number(row.outstanding) > 0 ? '#b91c1c' : '#15803d' }}>
                          ₹{Number(row.outstanding).toLocaleString('en-IN')}
                        </td>
                        <td>
                          {row.overdue_bills > 0 ? (
                            <span className="badge badge-danger">{row.overdue_bills} Overdue</span>
                          ) : (
                            <span className="badge badge-success">0</span>
                          )}
                        </td>
                        <td>{row.max_days_overdue || 0} days</td>
                      </tr>
                    ))}
                  </tbody>
                </>
              )}

              {activeTab === 'departments' && (
                <>
                  <thead>
                    <tr>
                      <th>Dept Code</th>
                      <th>Department Name</th>
                      <th>Office Contact</th>
                      <th>Programmes</th>
                      <th>Active Faculty</th>
                      <th>Active Courses</th>
                      <th>Total Enrolment</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.map((row) => (
                      <tr key={row.dept_id}>
                        <td><code>{row.dept_code}</code></td>
                        <td style={{ fontWeight: '500' }}>{row.dept_name}</td>
                        <td style={{ fontSize: '0.8rem' }}>{row.office_email}</td>
                        <td>{row.programmes}</td>
                        <td>{row.faculty_count}</td>
                        <td>{row.course_count}</td>
                        <td><strong>{row.total_students} Students</strong></td>
                      </tr>
                    ))}
                  </tbody>
                </>
              )}
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
