import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { formatDbError } from '../lib/errors';

export default function Faculty() {
  const [faculty, setFaculty] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadFaculty();
  }, []);

  async function loadFaculty() {
    setLoading(true);
    try {
      const [
        { data: fList, error: fErr },
        { data: dList, error: dErr }
      ] = await Promise.all([
        supabase
          .from('faculty')
          .select(`
            faculty_id, employee_code, full_name, email, designation, status,
            department:dept_id (dept_code, dept_name)
          `)
          .order('employee_code'),
        supabase.from('department').select('*')
      ]);

      if (fErr) throw fErr;
      if (dErr) throw dErr;

      setFaculty(fList || []);
      setDepartments(dList || []);
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
          Teaching staff profiles, employee codes, and department affiliations.
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
                  <td><span className="badge badge-neutral">{f.department?.dept_code}</span></td>
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
