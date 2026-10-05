import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { formatDbError } from '../lib/errors';

export default function Fees() {
  const [bills, setBills] = useState([]);
  const [students, setStudents] = useState([]);
  const [semesters, setSemesters] = useState([]);
  const [payments, setPayments] = useState([]);
  
  // New Bill Form
  const [newBill, setNewBill] = useState({
    student_id: '',
    semester_id: '',
    amount_due: '',
    due_date: new Date(Date.now() + 30 * 86400000).toISOString().split('T')[0]
  });

  // Record Payment Modal
  const [paymentModal, setPaymentModal] = useState({
    open: false,
    bill: null,
    amount: '',
    mode: 'UPI',
    ref: ''
  });

  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [
        { data: fbList, error: fbErr },
        { data: stList, error: stErr },
        { data: smList, error: smErr },
        { data: pyList, error: pyErr }
      ] = await Promise.all([
        supabase.from('v_fee_dues').select('*').order('bill_id', { ascending: false }),
        supabase.from('student').select('student_id, reg_no, full_name').eq('status', 'Active').order('full_name'),
        supabase.from('semester').select('semester_id, academic_year, term').order('start_date', { ascending: false }),
        supabase
          .from('payment')
          .select(`
            payment_id, payment_date, amount_paid, payment_mode, reference_no,
            fee_bill:bill_id (
              bill_id,
              student:student_id (full_name, reg_no)
            )
          `)
          .order('payment_id', { ascending: false })
          .limit(15)
      ]);

      if (fbErr) throw fbErr;
      if (stErr) throw stErr;
      if (smErr) throw smErr;
      if (pyErr) throw pyErr;

      setBills(fbList || []);
      setStudents(stList || []);
      setSemesters(smList || []);
      setPayments(pyList || []);

      if (stList && stList.length > 0 && !newBill.student_id) {
        setNewBill(prev => ({ ...prev, student_id: stList[0].student_id }));
      }
      if (smList && smList.length > 0 && !newBill.semester_id) {
        setNewBill(prev => ({ ...prev, semester_id: smList[0].semester_id }));
      }
    } catch (err) {
      setError(formatDbError(err));
    } finally {
      setLoading(false);
    }
  }

  const handleCreateBill = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const { data, error: billErr } = await supabase
        .from('fee_bill')
        .insert([{
          student_id: Number(newBill.student_id),
          semester_id: Number(newBill.semester_id),
          amount_due: Number(newBill.amount_due),
          due_date: newBill.due_date,
          status: 'Unpaid'
        }])
        .select()
        .single();

      if (billErr) throw billErr;

      setSuccess('Fee bill generated successfully!');
      setNewBill(prev => ({ ...prev, amount_due: '' }));
      await loadData();
    } catch (err) {
      console.error(err);
      setError(formatDbError(err));
    } finally {
      setSubmitting(false);
    }
  };

  const handleRecordPayment = async (e) => {
    e.preventDefault();
    if (!paymentModal.bill) return;

    setSubmitting(true);
    setError(null);
    setSuccess(null);

    try {
      const { data, error: pyErr } = await supabase
        .from('payment')
        .insert([{
          bill_id: paymentModal.bill.bill_id,
          amount_paid: Number(paymentModal.amount),
          payment_mode: paymentModal.mode,
          reference_no: paymentModal.ref || `TXN${Date.now()}`
        }])
        .select()
        .single();

      if (pyErr) throw pyErr;

      setSuccess(`Payment of ₹${paymentModal.amount} recorded! Bill status updated.`);
      setPaymentModal({ open: false, bill: null, amount: '', mode: 'UPI', ref: '' });
      await loadData();
    } catch (err) {
      console.error('Payment rejected by database:', err);
      setError(formatDbError(err));
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div>
      <div style={{ marginBottom: '20px' }}>
        <h2 style={{ fontSize: '1.35rem', fontWeight: '700' }}>Student Accounts, Invoicing & Receipts</h2>
        <p style={{ color: '#64748b', fontSize: '0.875rem' }}>
          Manage fee billing and payments with strict PostgreSQL overpayment rejection and automated status derivation.
        </p>
      </div>

      {error && <div className="alert alert-danger"><span>⚠️</span> {error}</div>}
      {success && <div className="alert alert-success"><span>✅</span> {success}</div>}

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(340px, 1fr))', gap: '24px', marginBottom: '28px' }}>
        {/* Create Bill Card */}
        <div className="card">
          <div className="card-header">
            <h3>Generate Semester Fee Bill</h3>
          </div>
          <form onSubmit={handleCreateBill} className="card-body">
            <div className="form-group" style={{ marginBottom: '14px' }}>
              <label className="form-label">Student Recipient *</label>
              <select
                className="form-control"
                value={newBill.student_id}
                onChange={(e) => setNewBill({ ...newBill, student_id: e.target.value })}
                required
              >
                {students.map(s => (
                  <option key={s.student_id} value={s.student_id}>
                    {s.full_name} ({s.reg_no})
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group" style={{ marginBottom: '14px' }}>
              <label className="form-label">Academic Semester *</label>
              <select
                className="form-control"
                value={newBill.semester_id}
                onChange={(e) => setNewBill({ ...newBill, semester_id: e.target.value })}
                required
              >
                {semesters.map(sm => (
                  <option key={sm.semester_id} value={sm.semester_id}>
                    {sm.academic_year} {sm.term}
                  </option>
                ))}
              </select>
            </div>

            <div className="form-group" style={{ marginBottom: '14px' }}>
              <label className="form-label">Tuition / Fee Amount (₹) *</label>
              <input
                type="number"
                step="0.01"
                className="form-control"
                placeholder="e.g. 92500"
                value={newBill.amount_due}
                onChange={(e) => setNewBill({ ...newBill, amount_due: e.target.value })}
                required
              />
            </div>

            <div className="form-group" style={{ marginBottom: '18px' }}>
              <label className="form-label">Due Date *</label>
              <input
                type="date"
                className="form-control"
                value={newBill.due_date}
                onChange={(e) => setNewBill({ ...newBill, due_date: e.target.value })}
                required
              />
            </div>

            <button
              type="submit"
              className="btn btn-primary"
              style={{ width: '100%', padding: '10px' }}
              disabled={submitting}
            >
              {submitting ? 'Creating Invoice...' : 'Generate Fee Bill'}
            </button>
          </form>
        </div>

        {/* Recent Transactions Feed */}
        <div className="card">
          <div className="card-header">
            <h3>Recent Receipt Transactions</h3>
          </div>
          <div className="table-responsive" style={{ maxHeight: '350px', overflowY: 'auto' }}>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Ref No</th>
                  <th>Student</th>
                  <th>Date</th>
                  <th>Amount</th>
                  <th>Mode</th>
                </tr>
              </thead>
              <tbody>
                {payments.map(p => (
                  <tr key={p.payment_id}>
                    <td><code>{p.reference_no}</code></td>
                    <td style={{ fontSize: '0.8rem' }}>{p.fee_bill?.student?.full_name}</td>
                    <td>{p.payment_date}</td>
                    <td style={{ fontWeight: '600', color: '#15803d' }}>
                      ₹{Number(p.amount_paid).toLocaleString('en-IN')}
                    </td>
                    <td><span className="badge badge-neutral">{p.payment_mode}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* Outstanding Bills Table */}
      <div className="card">
        <div className="card-header">
          <h3>Semester Fee Invoices & Recovery Status</h3>
          <span className="badge badge-neutral">{bills.length} Bills Total</span>
        </div>
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th>Bill #</th>
                <th>Student Name</th>
                <th>Reg No</th>
                <th>Semester</th>
                <th>Due Date</th>
                <th>Amount Due</th>
                <th>Paid</th>
                <th>Balance Outstanding</th>
                <th>Status</th>
                <th>Action</th>
              </tr>
            </thead>
            <tbody>
              {bills.map(b => (
                <tr key={b.bill_id}>
                  <td>#{b.bill_id}</td>
                  <td style={{ fontWeight: '500' }}>{b.student_name}</td>
                  <td><code>{b.reg_no}</code></td>
                  <td>{b.semester_label}</td>
                  <td>{b.due_date}</td>
                  <td>₹{Number(b.amount_due).toLocaleString('en-IN')}</td>
                  <td style={{ color: '#15803d', fontWeight: '500' }}>
                    ₹{Number(b.amount_paid).toLocaleString('en-IN')}
                  </td>
                  <td style={{ fontWeight: '600', color: Number(b.balance) > 0 ? '#b91c1c' : '#64748b' }}>
                    ₹{Number(b.balance).toLocaleString('en-IN')}
                  </td>
                  <td>
                    <span className={`badge ${
                      b.status === 'Paid'
                        ? 'badge-success'
                        : b.status === 'Partially Paid'
                        ? 'badge-warning'
                        : 'badge-danger'
                    }`}>
                      {b.status}
                    </span>
                  </td>
                  <td>
                    {Number(b.balance) > 0 ? (
                      <button
                        className="btn btn-secondary btn-sm"
                        onClick={() => setPaymentModal({
                          open: true,
                          bill: b,
                          amount: b.balance,
                          mode: 'UPI',
                          ref: ''
                        })}
                      >
                        💳 Record Payment
                      </button>
                    ) : (
                      <span style={{ fontSize: '0.75rem', color: '#15803d' }}>Cleared</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Record Payment Modal */}
      {paymentModal.open && (
        <div className="modal-backdrop">
          <div className="modal-content" style={{ maxWidth: '440px' }}>
            <div className="card-header">
              <h3>Record Payment for Bill #{paymentModal.bill?.bill_id}</h3>
              <button
                type="button"
                onClick={() => setPaymentModal({ open: false, bill: null, amount: '', mode: 'UPI', ref: '' })}
                style={{ background: 'none', border: 'none', fontSize: '1.2rem', cursor: 'pointer' }}
              >
                ✕
              </button>
            </div>
            <form onSubmit={handleRecordPayment} style={{ padding: '20px' }}>
              <div style={{ marginBottom: '14px', fontSize: '0.85rem' }}>
                <div>Student: <strong>{paymentModal.bill?.student_name} ({paymentModal.bill?.reg_no})</strong></div>
                <div>Remaining Balance: <strong style={{ color: '#b91c1c' }}>₹{Number(paymentModal.bill?.balance).toLocaleString('en-IN')}</strong></div>
              </div>

              <div className="form-group" style={{ marginBottom: '14px' }}>
                <label className="form-label">Payment Amount (₹) *</label>
                <input
                  type="number"
                  step="0.01"
                  className="form-control"
                  value={paymentModal.amount}
                  onChange={(e) => setPaymentModal({ ...paymentModal, amount: e.target.value })}
                  required
                />
                <span style={{ fontSize: '0.72rem', color: '#64748b' }}>
                  Overpayment test: Entering an amount higher than ₹{paymentModal.bill?.balance} will be blocked by PostgreSQL.
                </span>
              </div>

              <div className="form-group" style={{ marginBottom: '14px' }}>
                <label className="form-label">Payment Mode *</label>
                <select
                  className="form-control"
                  value={paymentModal.mode}
                  onChange={(e) => setPaymentModal({ ...paymentModal, mode: e.target.value })}
                  required
                >
                  <option value="UPI">UPI</option>
                  <option value="NEFT">NEFT / NetBanking</option>
                  <option value="Card">Debit / Credit Card</option>
                  <option value="Cash">Cash</option>
                  <option value="Cheque">Cheque</option>
                  <option value="DD">Demand Draft (DD)</option>
                </select>
              </div>

              <div className="form-group" style={{ marginBottom: '20px' }}>
                <label className="form-label">Transaction Reference Number</label>
                <input
                  type="text"
                  className="form-control"
                  placeholder="e.g. UPI-TXN-2026-99"
                  value={paymentModal.ref}
                  onChange={(e) => setPaymentModal({ ...paymentModal, ref: e.target.value })}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
                <button
                  type="button"
                  className="btn btn-secondary"
                  onClick={() => setPaymentModal({ open: false, bill: null, amount: '', mode: 'UPI', ref: '' })}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn btn-primary"
                  disabled={submitting}
                >
                  {submitting ? 'Verifying with DB...' : 'Confirm Receipt'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
