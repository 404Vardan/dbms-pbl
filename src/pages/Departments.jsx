import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { formatDbError } from '../lib/errors';

export default function Departments() {
  const [departments, setDepartments] = useState([]);
  const [programmes, setProgrammes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [
        { data: dList, error: dErr },
        { data: pList, error: pErr }
      ] = await Promise.all([
        supabase.from('department').select('*').order('dept_id'),
        supabase
          .from('programme')
          .select(`
            programme_id, programme_code, programme_name, duration_years, status,
            department:dept_id (dept_code, dept_name)
          `)
          .order('programme_id')
      ]);

      if (dErr) throw dErr;
      if (pErr) throw pErr;

      setDepartments(dList || []);
      setProgrammes(pList || []);
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '1.35rem', fontWeight: '700' }}>Departments & Degree Programmes</h2>
        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
          Organizational structure defining academic schools, departments, and certified degree curriculums.
        </p>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(320px, 1fr))', gap: '24px', marginBottom: '24px' }}>
        {/* Departments Panel */}
        <div className="card">
          <div className="card-header">
            <h3>Academic Departments</h3>
            <span className="badge badge-neutral">{departments.length} Depts</span>
          </div>
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Code</th>
                  <th>Department Name</th>
                  <th>Office Email</th>
                </tr>
              </thead>
              <tbody>
                {departments.map(d => (
                  <tr key={d.dept_id}>
                    <td><code>{d.dept_code}</code></td>
                    <td style={{ fontWeight: '500' }}>{d.dept_name}</td>
                    <td style={{ fontSize: '0.8rem' }}>{d.office_email || '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        {/* Programmes Panel */}
        <div className="card">
          <div className="card-header">
            <h3>Degree Programmes</h3>
            <span className="badge badge-neutral">{programmes.length} Programmes</span>
          </div>
          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Code</th>
                  <th>Programme Title</th>
                  <th>Dept</th>
                  <th>Duration</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {programmes.map(p => (
                  <tr key={p.programme_id}>
                    <td><code>{p.programme_code}</code></td>
                    <td style={{ fontWeight: '500' }}>{p.programme_name}</td>
                    <td><span className="badge badge-neutral">{p.department?.dept_code}</span></td>
                    <td>{p.duration_years} Years</td>
                    <td>
                      <span className={`badge ${p.status === 'Active' ? 'badge-success' : 'badge-warning'}`}>
                        {p.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}
