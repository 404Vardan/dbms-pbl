from flask import Blueprint, jsonify
from db import query

dashboard_bp = Blueprint('dashboard', __name__)

@dashboard_bp.route('/stats', methods=['GET'])
def get_dashboard_stats():
    try:
        total_students = query("SELECT COUNT(*) AS c FROM student WHERE status = 'Active'", fetchone=True)['c']
        active_programmes = query("SELECT COUNT(*) AS c FROM programme WHERE status = 'Active'", fetchone=True)['c']
        active_sections = query("SELECT COUNT(*) AS c FROM section", fetchone=True)['c']
        current_registrations = query("SELECT COUNT(*) AS c FROM registration WHERE status != 'Dropped'", fetchone=True)['c']
        
        # Check low attendance count (< 75%) from analytical view
        att_shortage = query("SELECT COUNT(*) AS c FROM v_attendance_summary WHERE is_shortage = 1", fetchone=True)['c']
        
        # Outstanding fees from view
        dues = query("SELECT COALESCE(SUM(balance), 0) AS total_outstanding FROM v_fee_dues WHERE balance > 0", fetchone=True)['total_outstanding']
        
        # Recent payments
        payments_sql = """
            SELECT p.payment_id, p.payment_date, p.amount_paid, p.payment_mode,
                   st.full_name AS student_name, st.reg_no
            FROM payment p
            JOIN fee_bill b ON b.bill_id = p.bill_id
            JOIN student st ON st.student_id = b.student_id
            ORDER BY p.payment_id DESC
            LIMIT 5
        """
        recent_payments = query(payments_sql)
        
        return jsonify({
            'total_students': total_students,
            'active_programmes': active_programmes,
            'active_sections': active_sections,
            'current_registrations': current_registrations,
            'attendance_shortage': att_shortage,
            'outstanding_fees': dues,
            'recent_payments': recent_payments
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500
