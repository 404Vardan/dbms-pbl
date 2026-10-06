from flask import Blueprint, request, jsonify
from db import query, get_db

examinations_bp = Blueprint('examinations', __name__)

@examinations_bp.route('/data', methods=['GET'])
def get_exam_data():
    section_id = request.args.get('section_id')
    exam_type = request.args.get('exam_type', 'Mid-Term')

    if not section_id:
        return jsonify({'error': 'section_id query parameter is required.'}), 400

    try:
        students = query("""
            SELECT r.registration_id, r.student_id, st.reg_no, st.full_name
            FROM registration r
            JOIN student st ON st.student_id = r.student_id
            WHERE r.section_id = %s AND r.status != 'Dropped'
            ORDER BY st.reg_no
        """, (section_id,))

        records = query("""
            SELECT * FROM v_exam_details
            WHERE section_id = %s AND exam_type = %s
            ORDER BY reg_no
        """, (section_id, exam_type))

        return jsonify({
            'students': students,
            'records': records
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@examinations_bp.route('/record', methods=['POST'])
def record_exam_marks():
    data = request.get_json() or {}
    reg_id = data.get('registration_id')
    exam_type = data.get('exam_type')
    exam_date = data.get('exam_date')
    marks = data.get('marks')
    max_marks = data.get('max_marks', 100)

    if reg_id is None or not exam_type or marks is None:
        return jsonify({'error': 'registration_id, exam_type, and marks are required.'}), 400

    conn = get_db()
    cursor = conn.cursor()
    try:
        # Call MySQL Stored Procedure sp_record_exam_result
        args = [
            int(reg_id),
            str(exam_type),
            str(exam_date),
            float(marks),
            float(max_marks) if max_marks else 100.0,
            0  # OUT parameter placeholder
        ]
        res = cursor.callproc('sp_record_exam_result', args)
        exam_id = res[-1]

        # Fetch resulting grade letter and point computed by trigger
        grade_info = query("SELECT grade_letter, grade_point FROM grade WHERE exam_id = %s", (exam_id,), fetchone=True)

        return jsonify({
            'exam_id': exam_id,
            'grade': grade_info,
            'message': 'Marks recorded successfully! Deterministic grade computed by MySQL trigger.'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400
    finally:
        cursor.close()
        conn.close()
