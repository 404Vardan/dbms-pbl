import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { formatDbError } from '../lib/errors';
import { Link } from 'react-router-dom';

export default function Students() {
  const [students, setStudents] = useState([]);
  const [programmes, setProgrammes] = useState([]);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [showModal, setShowModal] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  const [formData, setFormData] = useState({
    programme_id: '',
    reg_no: '',
    full_name: '',
    dob: '',
    email: '',
    phone: '',
    admission_date: new Date().toISOString().split('T')[0],
    guardian_name: '',
    guardian_relation: 'Father',
    guardian_phone: '',
    guardian_email: '',
    guardian_address: ''
  });

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [stList, deptData] = await Promise.all([
        api.getStudents(),
        api.getDepartments()
      ]);

      setStudents(stList || []);
      setProgrammes(deptData.programmes || []);
      if (deptData.programmes?.length > 0 && !formData.programme_id) {
        setFormData(prev => ({ ...prev, programme_id: deptData.programmes[0].programme_id }));
      }
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const payload = {
        student: {
          programme_id: Number(formData.programme_id),
          reg_no: formData.reg_no,
          full_name: formData.full_name,
          dob: formData.dob,
          email: formData.email,
          phone: formData.phone,
          admission_date: formData.admission_date
        },
        guardian: formData.guardian_name ? {
          name: formData.guardian_name,
          relation: formData.guardian_relation,
          phone: formData.guardian_phone,
          email: formData.guardian_email || null,
          address: formData.guardian_address || null
        } : null
      };

      await api.admitStudent(payload);
      setSuccess(`Student ${formData.full_name} (${formData.reg_no}) admitted successfully via MySQL transaction!`);
      setShowModal(false);
      setFormData(prev => ({
        ...prev,
        reg_no: '',
        full_name: '',
        dob: '',
        email: '',
        phone: '',
        guardian_name: '',
        guardian_phone: ''
      }));
      await loadData();
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setSubmitting(false);
    }
  };

  const filtered = students.filter(s =>
    s.full_name?.toLowerCase().includes(search.toLowerCase()) ||
    s.reg_no?.toLowerCase().includes(search.toLowerCase()) ||
    s.email?.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div>
      <div className="filter-bar">
        <div>
          <h2 style={{ fontSize: '1.25rem', fontWeight: '700' }}>Student Admissions & Records</h2>
          <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
            Comprehensive directory of admitted students and guardians stored in MySQL.
          </p>
        </div>
        <div style={{ display: 'flex', gap: '10px' }}>
          <input
            type="text"
            className="form-control search-input"
            placeholder="Search by name, reg no, email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
          <button className="btn btn-primary" onClick={() => setShowModal(true)}>
            <span>➕</span> New Admission
          </button>
        </div>
      </div>

      {error && <div className="alert alert-danger"><span>⚠️</span> {error}</div>}
      {success && <div className="alert alert-success"><span>✅</span> {success}</div>}

      <div className="card">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Reg No</th>
                <th>Full Name</th>
                <th>Programme</th>
                <th>Contact</th>
                <th>Guardian Details</th>
                <th>Admission Date</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: 'center', padding: '24px', color: '#64748b' }}>
                    Loading student records from MySQL...
                  </td>
                </tr>
              ) : filtered.length === 0 ? (
                <tr>
                  <td colSpan="8" style={{ textAlign: 'center', padding: '24px', color: '#94a3b8' }}>
                    No matching student records found.
                  </td>
                </tr>
              ) : (
                filtered.map((s) => (
                  <tr key={s.student_id}>
                    <td><code>{s.reg_no}</code></td>
                    <td style={{ fontWeight: '600' }}>{s.full_name}</td>
                    <td>
                      <span className="badge badge-neutral">
                        {s.programme_code || 'N/A'}
                      </span>
                    </td>
                    <td>
                      <div style={{ fontSize: '0.8rem' }}>{s.email}</div>
                      <div style={{ fontSize: '0.75rem', color: '#64748b' }}>{s.phone}</div>
                    </td>
                    <td>
                      {s.guardian_name ? (
                        <div>
                          <div style={{ fontWeight: '500', fontSize: '0.8rem' }}>
                            {s.guardian_name} ({s.guardian_relation})
                          </div>
                          <div style={{ fontSize: '0.75rem', color: '#64748b' }}>{s.guardian_phone}</div>
                        </div>
                      ) : (
                        <span style={{ color: '#94a3b8', fontSize: '0.8rem' }}>Not registered</span>
                      )}
                    </td>
                    <td>{s.admission_date?.split('T')[0] || s.admission_date}</td>
                    <td>
                      <span className={`badge ${s.status === 'Active' ? 'badge-success' : 'badge-warning'}`}>
                        {s.status}
                      </span>
                    </td>
                    <td>
                      <Link to={`/students/${s.student_id}`} className="btn btn-secondary btn-sm">
                        View Profile
                      </Link>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Admission Modal */}
      {showModal && (
        <div className="modal-backdrop">
          <div className="modal-content">
            <div className="card-header">
              <h3>Student Admission Form (MySQL Stored Procedure)</h3>
              <button
                type="button"
                onClick={() => setShowModal(false)}
                style={{ background: 'none', border: 'none', fontSize: '1.2rem', cursor: 'pointer' }}
              >
                ✕
              </button>
            </div>
            <form onSubmit={handleSubmit} style={{ padding: '20px' }}>
              <div style={{ marginBottom: '16px', fontWeight: '600', color: '#1e40af', borderBottom: '1px solid #e2e8f0', paddingBottom: '6px' }}>
                1. Academic & Personal Information
              </div>

              <div className="form-grid">
                <div className="form-group">
                  <label className="form-label">Degree Programme *</label>
                  <select
                    className="form-control"
                    value={formData.programme_id}
                    onChange={(e) => setFormData({ ...formData, programme_id: e.target.value })}
                    required
                  >
                    {programmes.map((p) => (
                      <option key={p.programme_id} value={p.programme_id}>
                        {p.programme_code} - {p.programme_name}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Registration Number *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. 26BCS099"
                    value={formData.reg_no}
                    onChange={(e) => setFormData({ ...formData, reg_no: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Student Full Name *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Ishan Sharma"
                    value={formData.full_name}
                    onChange={(e) => setFormData({ ...formData, full_name: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Date of Birth *</label>
                  <input
                    type="date"
                    className="form-control"
                    value={formData.dob}
                    onChange={(e) => setFormData({ ...formData, dob: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Institutional Email *</label>
                  <input
                    type="email"
                    className="form-control"
                    placeholder="ishan.sharma@students.scms.edu.in"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Mobile Contact *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="9876543210"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    required
                  />
                </div>
              </div>

              <div style={{ margin: '20px 0 16px 0', fontWeight: '600', color: '#1e40af', borderBottom: '1px solid #e2e8f0', paddingBottom: '6px' }}>
                2. Guardian Information (Parent/Guardian)
              </div>

              <div className="form-grid">
                <div className="form-group">
                  <label className="form-label">Guardian Name *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="e.g. Ramesh Sharma"
                    value={formData.guardian_name}
                    onChange={(e) => setFormData({ ...formData, guardian_name: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Relationship *</label>
                  <select
                    className="form-control"
                    value={formData.guardian_relation}
                    onChange={(e) => setFormData({ ...formData, guardian_relation: e.target.value })}
                  >
                    <option value="Father">Father</option>
                    <option value="Mother">Mother</option>
                    <option value="Guardian">Guardian</option>
                    <option value="Sibling">Sibling</option>
                  </select>
                </div>

                <div className="form-group">
                  <label className="form-label">Guardian Phone *</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="9822000000"
                    value={formData.guardian_phone}
                    onChange={(e) => setFormData({ ...formData, guardian_phone: e.target.value })}
                    required
                  />
                </div>

                <div className="form-group">
                  <label className="form-label">Residential Address</label>
                  <input
                    type="text"
                    className="form-control"
                    placeholder="City, State"
                    value={formData.guardian_address}
                    onChange={(e) => setFormData({ ...formData, guardian_address: e.target.value })}
                  />
                </div>
              </div>

              <div style={{ marginTop: '24px', display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setShowModal(false)}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={submitting}
                >
                  {submitting ? 'Executing MySQL Transaction...' : 'Confirm Admission'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
