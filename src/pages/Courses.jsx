import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { formatDbError } from '../lib/errors';

export default function Courses() {
  const [courses, setCourses] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [formData, setFormData] = useState({
    dept_id: '',
    course_code: '',
    course_name: '',
    credits: 4,
    course_type: 'Core'
  });
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [
        { data: cList, error: cErr },
        { data: dList, error: dErr }
      ] = await Promise.all([
        supabase
          .from('course')
          .select(`
            course_id, course_code, course_name, credits, course_type, status,
            department:dept_id (dept_code, dept_name)
          `)
          .order('course_code'),
        supabase.from('department').select('dept_id, dept_code, dept_name').order('dept_id')
      ]);

      if (cErr) throw cErr;
      if (dErr) throw dErr;

      setCourses(cList || []);
      setDepartments(dList || []);
      if (dList && dList.length > 0) {
        setFormData(prev => ({ ...prev, dept_id: dList[0].dept_id }));
      }
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  const handleAddCourse = async (e) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    try {
      const { data, error: insertErr } = await supabase
        .from('course')
        .insert([{
          dept_id: Number(formData.dept_id),
          course_code: formData.course_code.toUpperCase(),
          course_name: formData.course_name,
          credits: Number(formData.credits),
          course_type: formData.course_type,
          status: 'Active'
        }])
        .select()
        .single();

      if (insertErr) throw insertErr;

      setSuccess(`Course ${formData.course_code} created successfully!`);
      setShowModal(false);
      setFormData(prev => ({ ...prev, course_code: '', course_name: '' }));
      await loadData();
    } catch (err) {
      setError(formatDbError(err));
    }
  };

  return (
    <div>
      <div className="filter-bar">
        <div>
          <h2 style={{ fontSize: '1.35rem', fontWeight: '700' }}>Curriculum Courses Directory</h2>
          <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
            Catalogue of approved courses with academic credit weights and course types.
          </p>
        </div>
        <button className="btn btn-primary" onClick={() => setShowModal(true)}>
          <span>➕</span> Add New Course
        </button>
      </div>

      {error && <div className="alert alert-danger"><span>⚠️</span> {error}</div>}
      {success && <div className="alert alert-success"><span>✅</span> {success}</div>}

      <div className="card">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Course Code</th>
                <th>Course Name</th>
                <th>Department</th>
                <th>Credits</th>
                <th>Course Type</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {courses.map(c => (
                <tr key={c.course_id}>
                  <td><code>{c.course_code}</code></td>
                  <td style={{ fontWeight: '500' }}>{c.course_name}</td>
                  <td><span className="badge badge-neutral">{c.department?.dept_code}</span></td>
                  <td><strong>{c.credits} Credits</strong></td>
                  <td>
                    <span className="badge badge-primary">{c.course_type}</span>
                  </td>
                  <td>
                    <span className="badge badge-success">{c.status}</span>
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
              <h3>Create Curriculum Course</h3>
              <button
                type="button"
                onClick={() => setShowModal(false)}
                style={{ background: 'none', border: 'none', fontSize: '1.2rem', cursor: 'pointer' }}
              >
                ✕
              </button>
            </div>
            <form onSubmit={handleAddCourse} style={{ padding: '20px' }}>
              <div className="form-group" style={{ marginBottom: '14px' }}>
                <label className="form-label">Department *</label>
                <select
                  className="form-control"
                  value={formData.dept_id}
                  onChange={(e) => setFormData({ ...formData, dept_id: e.target.value })}
                  required
                >
                  {departments.map(d => (
                    <option key={d.dept_id} value={d.dept_id}>{d.dept_code} - {d.dept_name}</option>
                  ))}
                </select>
              </div>

              <div className="form-group" style={{ marginBottom: '14px' }}>
                <label className="form-label">Course Code *</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. CS401"
                  value={formData.course_code}
                  onChange={(e) => setFormData({ ...formData, course_code: e.target.value })}
                  required
                />
              </div>

              <div className="form-group" style={{ marginBottom: '14px' }}>
                <label className="form-label">Course Title *</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. Distributed Computing"
                  value={formData.course_name}
                  onChange={(e) => setFormData({ ...formData, course_name: e.target.value })}
                  required
                />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginBottom: '18px' }}>
                <div className="form-group">
                  <label className="form-label">Credits *</label>
                  <input
                    type="number"
                    min="1"
                    max="10"
                    className="form-control"
                    value={formData.credits}
                    onChange={(e) => setFormData({ ...formData, credits: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Course Type *</label>
                  <select
                    className="form-control"
                    value={formData.course_type}
                    onChange={(e) => setFormData({ ...formData, course_type: e.target.value })}
                  >
                    <option value="Core">Core</option>
                    <option value="Elective">Elective</option>
                    <option value="Lab">Lab</option>
                    <option value="Project">Project</option>
                  </select>
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                <button type="button" className="btn btn-secondary" onClick={() => setShowModal(false)}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Save Course
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
