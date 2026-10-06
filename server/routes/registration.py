from flask import Blueprint, request, jsonify
from db import query

registration_bp = Blueprint('registration', __name__)

@registration_bp.route('/options', methods=['GET'])
def get_registration_options():
    try:
        students = query("""
            SELECT student_id, reg_no, full_name, email
            FROM student
            WHERE status = 'Active'
            ORDER BY full_name
        """)

        sections = query("""
            SELECT s.section_id, s.section_code, s.room_no, s.capacity,
                   c.course_code, c.course_name, c.credits,
                   f.full_name AS faculty_name,
                   CONCAT(sm.academic_year, ' ', sm.term) AS semester_label,
                   (SELECT COUNT(*) FROM registration r WHERE r.section_id = s.section_id AND r.status != 'Dropped') AS enrolled
            FROM section s
            JOIN course c ON c.course_id = s.course_id
            JOIN faculty f ON f.faculty_id = s.faculty_id
            JOIN semester sm ON sm.semester_id = s.semester_id
            ORDER BY c.course_code, s.section_code
        """)

        registrations = query("""
            SELECT r.registration_id, r.student_id, st.reg_no, st.full_name AS student_name,
                   r.section_id, s.section_code, c.course_code, c.course_name,
                   r.registered_on, r.status
            FROM registration r
            JOIN student st ON st.student_id = r.student_id
            JOIN section s ON s.section_id = r.section_id
            JOIN course c ON c.course_id = s.course_id
            ORDER BY r.registration_id DESC
            LIMIT 100
        """)

        return jsonify({
            'students': students,
            'sections': sections,
            'registrations': registrations
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@registration_bp.route('', methods=['POST'])
def register_course():
    data = request.get_json() or {}
    student_id = data.get('student_id')
    section_id = data.get('section_id')

    if not student_id or not section_id:
        return jsonify({'error': 'student_id and section_id are required.'}), 400

    try:
        # INSERT will trigger trg_registration_before_insert which enforces:
        # 1. Student Active check
        # 2. Duplicate enrolment in same course in same semester
        # 3. Maximum section capacity
        reg_id = query("""
            INSERT INTO registration (student_id, section_id, registered_on, status)
            VALUES (%s, %s, NOW(), 'Registered')
        """, (student_id, section_id), commit=True)

        return jsonify({
            'registration_id': reg_id,
            'message': 'Course Section Registration confirmed by MySQL database!'
        })
    except Exception as e:
        # Cleanly extract trigger error message if SQLSTATE 45000
        err_msg = str(e)
        return jsonify({'error': err_msg}), 400

@registration_bp.route('/<int:registration_id>', methods=['DELETE'])
def drop_registration(registration_id):
    try:
        query("UPDATE registration SET status = 'Dropped' WHERE registration_id = %s", (registration_id,), commit=True)
        return jsonify({'message': 'Registration status updated to Dropped.'})
    except Exception as e:
        return jsonify({'error': str(e)}), 400
