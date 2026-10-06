from flask import Blueprint, request, jsonify
from db import query

fees_bp = Blueprint('fees', __name__)

@fees_bp.route('/data', methods=['GET'])
def get_fees_data():
    try:
        bills = query("SELECT * FROM v_fee_dues ORDER BY bill_id DESC")
        
        students = query("""
            SELECT student_id, reg_no, full_name
            FROM student
            WHERE status = 'Active'
            ORDER BY full_name
        """)

        semesters = query("""
            SELECT semester_id, CONCAT(academic_year, ' ', term) AS semester_label
            FROM semester
            ORDER BY start_date DESC
        """)

        payments = query("""
            SELECT p.payment_id, p.bill_id, p.payment_date, p.amount_paid,
                   p.payment_mode, p.reference_no,
                   st.reg_no, st.full_name AS student_name
            FROM payment p
            JOIN fee_bill b ON b.bill_id = p.bill_id
            JOIN student st ON st.student_id = b.student_id
            ORDER BY p.payment_id DESC
            LIMIT 50
        """)

        return jsonify({
            'bills': bills,
            'students': students,
            'semesters': semesters,
            'payments': payments
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@fees_bp.route('/bill', methods=['POST'])
def create_bill():
    data = request.get_json() or {}
    student_id = data.get('student_id')
    semester_id = data.get('semester_id')
    amount_due = data.get('amount_due')
    due_date = data.get('due_date')

    if not student_id or not semester_id or amount_due is None or not due_date:
        return jsonify({'error': 'student_id, semester_id, amount_due, and due_date are required.'}), 400

    try:
        bill_id = query("""
            INSERT INTO fee_bill (student_id, semester_id, bill_date, amount_due, due_date, status)
            VALUES (%s, %s, CURRENT_DATE(), %s, %s, 'Unpaid')
        """, (student_id, semester_id, amount_due, due_date), commit=True)

        return jsonify({
            'bill_id': bill_id,
            'message': 'Fee bill generated successfully!'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@fees_bp.route('/payment', methods=['POST'])
def record_payment():
    data = request.get_json() or {}
    bill_id = data.get('bill_id')
    amount_paid = data.get('amount_paid')
    payment_mode = data.get('payment_mode', 'UPI')
    reference_no = data.get('reference_no')

    if not bill_id or amount_paid is None:
        return jsonify({'error': 'bill_id and amount_paid are required.'}), 400

    try:
        # Trigger trg_payment_before_insert will validate against overpayment
        # Trigger trg_payment_after_insert will automatically update fee_bill status
        payment_id = query("""
            INSERT INTO payment (bill_id, payment_date, amount_paid, payment_mode, reference_no)
            VALUES (%s, CURRENT_DATE(), %s, %s, %s)
        """, (bill_id, amount_paid, payment_mode, reference_no or None), commit=True)

        return jsonify({
            'payment_id': payment_id,
            'message': f'Payment of ₹{amount_paid} recorded! Bill status updated.'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400
