import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { formatDbError } from '../lib/errors';

export default function Semesters() {
  const [semesters, setSemesters] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadSemesters();
  }, []);

  async function loadSemesters() {
    setLoading(true);
    try {
      const { data, error: err } = await supabase
        .from('semester')
        .select('*')
        .order('start_date', { ascending: false });

      if (err) throw err;
      setSemesters(data || []);
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '1.35rem', fontWeight: '700' }}>Academic Calendar & Semesters</h2>
        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
          Schedule of academic terms, semester start and end dates with date-integrity validation.
        </p>
      </div>

      {error && <div className="alert alert-danger">{error}</div>}

      <div className="card">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Semester ID</th>
                <th>Academic Year</th>
                <th>Term</th>
                <th>Start Date</th>
                <th>End Date</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {semesters.map(s => {
                const isCurrent = s.academic_year === '2026-27' && s.term === 'Odd';
                return (
                  <tr key={s.semester_id}>
                    <td>#{s.semester_id}</td>
                    <td style={{ fontWeight: '600' }}>{s.academic_year}</td>
                    <td><span className="badge badge-neutral">{s.term} Term</span></td>
                    <td>{s.start_date}</td>
                    <td>{s.end_date}</td>
                    <td>
                      {isCurrent ? (
                        <span className="badge badge-success">Current Active Term</span>
                      ) : (
                        <span className="badge badge-neutral">Archived / Scheduled</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
