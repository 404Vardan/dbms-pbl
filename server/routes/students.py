from flask import Blueprint, request, jsonify
from db import query, get_db

students_bp = Blueprint('students', __name__)

@students_bp.route('', methods=['GET'])
def get_students():
    try:
        sql = """
            SELECT s.*, p.programme_code, p.programme_name,
                   g.name AS guardian_name, g.relation AS guardian_relation, g.phone AS guardian_phone
            FROM student s
            JOIN programme p ON p.programme_id = s.programme_id
            LEFT JOIN guardian g ON g.student_id = s.student_id
            ORDER BY s.student_id DESC
        """
        students = query(sql)
        # Format dates to string
        for s in students:
            if s.get('dob'):
                s['dob'] = str(s['dob'])
            if s.get('admission_date'):
                s['admission_date'] = str(s['admission_date'])
        return jsonify(students)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@students_bp.route('/<int:student_id>', methods=['GET'])
def get_student_details(student_id):
    try:
        sql_st = """
            SELECT s.*, p.programme_code, p.programme_name,
                   g.name AS guardian_name, g.relation AS guardian_relation, g.phone AS guardian_phone,
                   g.email AS guardian_email, g.address AS guardian_address
            FROM student s
            JOIN programme p ON p.programme_id = s.programme_id
            LEFT JOIN guardian g ON g.student_id = s.student_id
            WHERE s.student_id = %s
        """
        student = query(sql_st, (student_id,), fetchone=True)
        if not student:
            return jsonify({'error': 'Student not found.'}), 404

        if student.get('dob'):
            student['dob'] = str(student['dob'])
        if student.get('admission_date'):
            student['admission_date'] = str(student['admission_date'])

        history = query("SELECT * FROM v_student_academic_history WHERE student_id = %s", (student_id,))
        bills = query("SELECT * FROM v_fee_dues WHERE student_id = %s", (student_id,))
        for b in bills:
            if b.get('bill_date'):
                b['bill_date'] = str(b['bill_date'])
            if b.get('due_date'):
                b['due_date'] = str(b['due_date'])
            if b.get('last_payment_date'):
                b['last_payment_date'] = str(b['last_payment_date'])

        return jsonify({'student': student, 'history': history, 'bills': bills})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@students_bp.route('/admit', methods=['POST'])
def admit_student():
    data = request.get_json() or {}
    st = data.get('student', {})
    g = data.get('guardian', {})

    conn = get_db()
    cursor = conn.cursor()
    try:
        # Call MySQL Stored Procedure sp_admit_student
        args = [
            int(st.get('programme_id')),
            st.get('reg_no', '').strip(),
            st.get('full_name', '').strip(),
            st.get('dob'),
            st.get('email', '').strip(),
            st.get('phone', '').strip(),
            st.get('admission_date') or None,
            g.get('name', '').strip() if g else None,
            g.get('relation', 'Father') if g else None,
            g.get('phone', '').strip() if g else None,
            g.get('email', '').strip() if g and g.get('email') else None,
            g.get('address', '').strip() if g and g.get('address') else None,
            0  # OUT parameter placeholder
        ]
        res = cursor.callproc('sp_admit_student', args)
        student_id = res[-1]
        return jsonify({'student_id': student_id, 'message': 'Student admitted successfully via MySQL transaction.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 400
    finally:
        cursor.close()
        conn.close()

@students_bp.route('/<int:student_id>', methods=['PUT'])
def update_student(student_id):
    data = request.get_json() or {}
    try:
        query("""
            UPDATE student
            SET full_name = %s, phone = %s, email = %s, status = %s
            WHERE student_id = %s
        """, (data.get('full_name'), data.get('phone'), data.get('email'), data.get('status', 'Active'), student_id), commit=True)
        return jsonify({'message': 'Student updated successfully.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@students_bp.route('/<int:student_id>', methods=['DELETE'])
def deactivate_student(student_id):
    try:
        # Controlled soft-delete / status update
        query("UPDATE student SET status = 'Withdrawn' WHERE student_id = %s", (student_id,), commit=True)
        return jsonify({'message': 'Student marked as Withdrawn.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 400
