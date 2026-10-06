import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { formatDbError } from '../lib/errors';

export default function Sections() {
  const [sections, setSections] = useState([]);
  const [courses, setCourses] = useState([]);
  const [faculty, setFaculty] = useState([]);
  const [semesters, setSemesters] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    course_id: '',
    faculty_id: '',
    semester_id: '',
    section_code: 'A',
    room_no: 'LH-101',
    capacity: 60
  });
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    try {
      const data = await api.getSections();
      setSections(data.sections || []);
      setCourses(data.courses || []);
      setFaculty(data.faculty || []);
      setSemesters(data.semesters || []);

      if (data.courses?.length > 0 && !formData.course_id) setFormData(p => ({ ...p, course_id: data.courses[0].course_id }));
      if (data.faculty?.length > 0 && !formData.faculty_id) setFormData(p => ({ ...p, faculty_id: data.faculty[0].faculty_id }));
      if (data.semesters?.length > 0 && !formData.semester_id) setFormData(p => ({ ...p, semester_id: data.semesters[0].semester_id }));
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  const handleCreateSection = async (e) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    try {
      const res = await api.createSection({
        course_id: Number(formData.course_id),
        faculty_id: Number(formData.faculty_id),
        semester_id: Number(formData.semester_id),
        section_code: formData.section_code.toUpperCase(),
        room_no: formData.room_no,
        capacity: Number(formData.capacity)
      });

      setSuccess(res.message || `Section ${formData.section_code} created successfully!`);
      setShowModal(false);
      await loadData();
    } catch (err) {
      setError(formatDbError(err));
    }
  };

  return (
    <div>
      <div className="filter-bar">
        <div>
          <h2 style={{ fontSize: '1.35rem', fontWeight: '700' }}>Class Sections & Room Allocation</h2>
          <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
            Lecture and laboratory section assignments with classroom capacities stored in MySQL.
          </p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowModal(true)}>
          <span>➕</span> Allocate New Section
        </button>
      </div>

      {error && <div className="alert alert-danger"><span>⚠️</span> {error}</div>}
      {success && <div className="alert alert-success"><span>✅</span> {success}</div>}

      <div className="card">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Course</th>
                <th>Course Title</th>
                <th>Section</th>
                <th>Assigned Instructor</th>
                <th>Semester</th>
                <th>Room</th>
                <th>Capacity</th>
                <th>Occupancy</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {sections.map(s => (
                <tr key={s.section_id}>
                  <td><code>{s.course_code}</code></td>
                  <td style={{ fontWeight: '500' }}>{s.course_name}</td>
                  <td><strong>Sec {s.section_code}</strong></td>
                  <td>{s.faculty_name}</td>
                  <td><span className="badge badge-neutral">{s.semester_label}</span></td>
                  <td>{s.room_no}</td>
                  <td>{s.capacity} seats</td>
                  <td>
                    <strong>{s.registered_count}</strong> ({s.occupancy_pct}%)
                  </td>
                  <td>
                    {s.is_full ? (
                      <span className="badge badge-danger">FULL</span>
                    ) : (
                      <span className="badge badge-success">{s.remaining_seats} available</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {showModal && (
        <div className="modal-backdrop">
          <div className="modal-content" style={{ maxWidth: '480px' }}>
            <div className="card-header">
              <h3>Allocate Class Section</h3>
              <button
                type="button"
                onClick={() => setShowModal(false)}
                style={{ background: 'none', border: 'none', fontSize: '1.2rem', cursor: 'pointer' }}
              >
                ✕
              </button>
            </div>
            <form onSubmit={handleCreateSection} style={{ padding: '20px' }}>
              <div className="form-group" style={{ marginBottom: '14px' }}>
                <label className="form-label">Course *</label>
                <select
                  className="form-control"
                  value={formData.course_id}
                  onChange={(e) => setFormData({ ...formData, course_id: e.target.value })}
                  required
                >
                  {courses.map(c => (
                    <option key={c.course_id} value={c.course_id}>{c.course_code} - {c.course_name}</option>
                  ))}
                </select>
              </div>

              <div className="form-group" style={{ marginBottom: '14px' }}>
                <label className="form-label">Faculty Instructor *</label>
                <select
                  className="form-control"
                  value={formData.faculty_id}
                  onChange={(e) => setFormData({ ...formData, faculty_id: e.target.value })}
                  required
                >
                  {faculty.map(f => (
                    <option key={f.faculty_id} value={f.faculty_id}>{f.full_name}</option>
                  ))}
                </select>
              </div>

              <div className="form-group" style={{ marginBottom: '14px' }}>
                <label className="form-label">Semester *</label>
                <select
                  className="form-control"
                  value={formData.semester_id}
                  onChange={(e) => setFormData({ ...formData, semester_id: e.target.value })}
                  required
                >
                  {semesters.map(sm => (
                    <option key={sm.semester_id} value={sm.semester_id}>{sm.academic_year} {sm.term}</option>
                  ))}
                </select>
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: '10px', marginBottom: '18px' }}>
                <div className="form-group">
                  <label className="form-label">Sec Code *</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.section_code}
                    onChange={(e) => setFormData({ ...formData, section_code: e.target.value })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Room No *</label>
                  <input
                    type="text"
                    className="form-control"
                    value={formData.room_no}
                    onChange={(e) => setFormData({ ...formData, room_no: e.target.value })}
                    required
                  />
                </div>
                <div className="form-group">
                  <label className="form-label">Capacity *</label>
                  <input
                    type="number"
                    min="1"
                    className="form-control"
                    value={formData.capacity}
                    onChange={(e) => setFormData({ ...formData, capacity: e.target.value })}
                    required
                  />
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Save Section
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
