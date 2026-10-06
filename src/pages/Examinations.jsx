import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { formatDbError } from '../lib/errors';

export default function Examinations() {
  const [sections, setSections] = useState([]);
  const [selectedSection, setSelectedSection] = useState('');
  const [students, setStudents] = useState([]);
  const [examType, setExamType] = useState('Mid-Term');
  const [examDate, setExamDate] = useState(new Date().toISOString().split('T')[0]);
  const [examRecords, setExamRecords] = useState([]);
  
  const [selectedReg, setSelectedReg] = useState('');
  const [marks, setMarks] = useState('');
  const [maxMarks, setMaxMarks] = useState(100);
  
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    loadSections();
  }, []);

  useEffect(() => {
    if (selectedSection) {
      loadSectionData();
    }
  }, [selectedSection, examType]);

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

  async function loadSectionData() {
    try {
      const res = await api.getExamData(selectedSection, examType);
      setStudents(res.students || []);
      setExamRecords(res.records || []);
      if (res.students?.length > 0 && !selectedReg) {
        setSelectedReg(res.students[0].registration_id);
      }
    } catch (err) {
      setError(formatDbError(err));
    }
  }

  const handleRecordMarks = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const numMarks = Number(marks);
      const numMax = Number(maxMarks);

      const res = await api.recordExamMarks({
        registration_id: Number(selectedReg),
        exam_type: examType,
        exam_date: examDate,
        marks: numMarks,
        max_marks: numMax
      });

      setSuccess(res.message || 'Marks recorded successfully! Deterministic grade computed by MySQL trigger.');
      setMarks('');
      await loadSectionData();
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '1.35rem', fontWeight: '700' }}>Examinations & Grade Computation</h2>
        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
          Evaluate marks with MySQL constraint validation. Grades and points are generated automatically by database triggers.
        </p>
      </div>

      {error && <div className="alert alert-danger"><span>⚠️</span> {error}</div>}
      {success && <div className="alert alert-success"><span>✅</span> {success}</div>}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))', gap: '24px', marginBottom: '28px' }}>
        <div className="card">
          <div className="card-header">
            <h3>Record / Update Marks (Stored Procedure)</h3>
          </div>
          <form onSubmit={handleRecordMarks} className="card-body">
            <div className="form-group" style={{ marginBottom: '14px' }}>
              <label className="form-label">Course Section</label>
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

            <div className="form-group" style={{ marginBottom: '14px' }}>
              <label className="form-label">Exam Classification</label>
              <select
                className="form-control"
                value={examType}
                onChange={(e) => setExamType(e.target.value)}
              >
                <option value="Mid-Term">Mid-Term (Theoretical Evaluation)</option>
                <option value="End-Term">End-Term (Final Semester Exam)</option>
                <option value="Internal">Internal Assessment / Quiz</option>
                <option value="Practical">Practical / Lab Exam</option>
              </select>
            </div>

            <div className="form-group" style={{ marginBottom: '14px' }}>
              <label className="form-label">Candidate Student *</label>
              <select
                className="form-control"
                value={selectedReg}
                onChange={(e) => setSelectedReg(e.target.value)}
                required
              >
                {students.map(s => (
                  <option key={s.registration_id} value={s.registration_id}>
                    {s.full_name} ({s.reg_no})
                  </option>
                ))}
              </select>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '14px' }}>
              <div className="form-group">
                <label className="form-label">Marks Scored *</label>
                <input
                  type="number"
                  step="0.01"
                  className="form-control"
                  placeholder="0 - 100"
                  value={marks}
                  onChange={(e) => setMarks(e.target.value)}
                  required
                />
              </div>

              <div className="form-group">
                <label className="form-label">Maximum Marks</label>
                <input
                  type="number"
                  className="form-control"
                  value={maxMarks}
                  onChange={(e) => setMaxMarks(e.target.value)}
                  required
                />
              </div>
            </div>

            <div className="form-group" style={{ marginBottom: '18px' }}>
              <label className="form-label">Exam Date</label>
              <input
                type="date"
                className="form-control"
                value={examDate}
                onChange={(e) => setExamDate(e.target.value)}
                required
              />
            </div>

            <button
              type="submit"
              className="btn btn-primary"
              style={{ width: '100%', padding: '10px' }}
              disabled={submitting || students.length === 0}
            >
              {submitting ? 'Calculating via MySQL...' : 'Submit & Calculate Grade'}
            </button>
          </form>
        </div>

        <div className="card">
          <div className="card-header">
            <h3>Deterministic University Grading Standard</h3>
          </div>
          <div className="card-body">
            <p style={{ fontSize: '0.825rem', color: '#64748b', marginBottom: '12px' }}>
              Grades and points are mapped automatically by MySQL trigger <code>trg_examination_after_insert</code>:
            </p>
            <table className="data-table" style={{ fontSize: '0.8rem' }}>
              <thead>
                <tr>
                  <th>Percentage</th>
                  <th>Grade Letter</th>
                  <th>Grade Point</th>
                  <th>Classification</th>
                </tr>
              </thead>
              <tbody>
                <tr><td>90% – 100%</td><td><span className="badge badge-primary">A+</span></td><td>10.0</td><td>Outstanding</td></tr>
                <tr><td>80% – 89.99%</td><td><span className="badge badge-primary">A</span></td><td>9.0</td><td>Excellent</td></tr>
                <tr><td>70% – 79.99%</td><td><span className="badge badge-success">B+</span></td><td>8.0</td><td>Very Good</td></tr>
                <tr><td>60% – 69.99%</td><td><span className="badge badge-success">B</span></td><td>7.0</td><td>Good</td></tr>
                <tr><td>50% – 59.99%</td><td><span className="badge badge-warning">C</span></td><td>6.0</td><td>Satisfactory</td></tr>
                <tr><td>40% – 49.99%</td><td><span className="badge badge-warning">D</span></td><td>5.0</td><td>Pass</td></tr>
                <tr><td>&lt; 40%</td><td><span className="badge badge-danger">F</span></td><td>0.0</td><td>Fail (Repeat)</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <div className="card">
        <div className="card-header">
          <h3>Evaluated Candidate Results ({examType})</h3>
          <span className="badge badge-neutral">{examRecords.length} Results Recorded</span>
        </div>
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Reg No</th>
                <th>Candidate Name</th>
                <th>Exam Date</th>
                <th>Marks</th>
                <th>Percentage</th>
                <th>Grade Letter</th>
                <th>Grade Point</th>
                <th>Graded Timestamp</th>
              </tr>
            </thead>
            <tbody>
              {examRecords.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                    No results recorded yet for this examination type in the selected section.
                  </td>
                </tr>
              ) : (
                examRecords.map(r => (
                  <tr key={r.exam_id}>
                    <td><code>{r.reg_no}</code></td>
                    <td style={{ fontWeight: '500' }}>{r.student_name}</td>
                    <td>{r.exam_date?.split('T')[0] || r.exam_date}</td>
                    <td style={{ fontWeight: '600' }}>
                      {r.marks != null ? `${r.marks} / ${r.max_marks}` : '—'}
                    </td>
                    <td>{r.percentage != null ? `${r.percentage}%` : '—'}</td>
                    <td>
                      {r.grade_letter ? (
                        <span className={`badge ${r.grade_letter === 'F' ? 'badge-danger' : 'badge-primary'}`}>
                          {r.grade_letter}
                        </span>
                      ) : '—'}
                    </td>
                    <td><strong>{r.grade_point ?? '—'}</strong></td>
                    <td style={{ fontSize: '0.75rem', color: '#64748b' }}>
                      {r.graded_on ? new Date(r.graded_on).toLocaleTimeString() : '—'}
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
