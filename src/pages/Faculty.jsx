import React, { useEffect, useState } from 'react';
import { api } from '../lib/api';
import { formatDbError } from '../lib/errors';

export default function Faculty() {
  const [faculty, setFaculty] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadFaculty();
  }, []);

  async function loadFaculty() {
    setLoading(true);
    try {
      const data = await api.getFaculty();
      setFaculty(data || []);
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '1.35rem', fontWeight: '700' }}>Faculty Directory & Academic Staff</h2>
        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
          Teaching staff profiles, employee codes, and department affiliations stored in MySQL.
        </p>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      <div className="card">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Emp Code</th>
                <th>Full Name</th>
                <th>Designation</th>
                <th>Department</th>
                <th>Institutional Email</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {faculty.map(f => (
                <tr key={f.faculty_id}>
                  <td><code>{f.employee_code}</code></td>
                  <td style={{ fontWeight: '600' }}>{f.full_name}</td>
                  <td>{f.designation}</td>
                  <td><span className="badge badge-neutral">{f.dept_code}</span></td>
                  <td>{f.email}</td>
                  <td><span className="badge badge-success">{f.status}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
