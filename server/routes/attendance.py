from flask import Blueprint, request, jsonify
from db import query, get_db

attendance_bp = Blueprint('attendance', __name__)

@attendance_bp.route('/sections', methods=['GET'])
def get_attendance_sections():
    try:
        sections = query("""
            SELECT s.section_id, s.section_code, s.room_no,
                   c.course_code, c.course_name,
                   f.full_name AS faculty_name,
                   CONCAT(sm.academic_year, ' ', sm.term) AS semester_label
            FROM section s
            JOIN course c ON c.course_id = s.course_id
            JOIN faculty f ON f.faculty_id = s.faculty_id
            JOIN semester sm ON sm.semester_id = s.semester_id
            ORDER BY c.course_code, s.section_code
        """)
        return jsonify(sections)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@attendance_bp.route('/roster', methods=['GET'])
def get_attendance_roster():
    section_id = request.args.get('section_id')
    date_val = request.args.get('date')

    if not section_id:
        return jsonify({'error': 'section_id query parameter is required.'}), 400

    try:
        roster = query("""
            SELECT r.registration_id, r.student_id, st.reg_no, st.full_name
            FROM registration r
            JOIN student st ON st.student_id = r.student_id
            WHERE r.section_id = %s AND r.status != 'Dropped'
            ORDER BY st.reg_no
        """, (section_id,))

        attendance_records = []
        if date_val:
            attendance_records = query("""
                SELECT a.registration_id, a.status, a.attendance_date
                FROM attendance a
                JOIN registration r ON r.registration_id = a.registration_id
                WHERE r.section_id = %s AND a.attendance_date = %s
            """, (section_id, date_val))

        summary = query("""
            SELECT * FROM v_attendance_summary
            WHERE section_id = %s
            ORDER BY reg_no
        """, (section_id,))

        return jsonify({
            'roster': roster,
            'attendanceRecords': attendance_records,
            'summary': summary
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@attendance_bp.route('/save', methods=['POST'])
def save_attendance():
    data = request.get_json() or {}
    section_id = data.get('section_id')
    attendance_date = data.get('attendance_date')
    records = data.get('records', [])

    if not attendance_date or not records:
        return jsonify({'error': 'attendance_date and records are required.'}), 400

    conn = get_db()
    cursor = conn.cursor()
    try:
        for rec in records:
            reg_id = rec.get('registration_id')
            status = rec.get('status', 'Present')
            # Trigger trg_attendance_before_insert will validate:
            # - registration not dropped
            # - not future date
            # - inside semester start and end dates
            cursor.execute("""
                INSERT INTO attendance (registration_id, attendance_date, status)
                VALUES (%s, %s, %s)
                ON DUPLICATE KEY UPDATE status = VALUES(status)
            """, (reg_id, attendance_date, status))

        return jsonify({'message': f'Attendance for {len(records)} students recorded successfully.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 400
    finally:
        cursor.close()
        conn.close()
