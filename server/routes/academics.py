from flask import Blueprint, request, jsonify
from db import query

academics_bp = Blueprint('academics', __name__)

@academics_bp.route('/departments', methods=['GET'])
def get_departments():
    try:
        departments = query("SELECT * FROM department ORDER BY dept_code")
        programmes = query("""
            SELECT p.*, d.dept_name, d.dept_code
            FROM programme p
            JOIN department d ON d.dept_id = p.dept_id
            ORDER BY p.programme_code
        """)
        return jsonify({
            'departments': departments,
            'programmes': programmes
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@academics_bp.route('/faculty', methods=['GET'])
def get_faculty():
    try:
        faculty = query("""
            SELECT f.*, d.dept_name, d.dept_code
            FROM faculty f
            JOIN department d ON d.dept_id = f.dept_id
            ORDER BY f.full_name
        """)
        return jsonify(faculty)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@academics_bp.route('/courses', methods=['GET'])
def get_courses():
    try:
        courses = query("""
            SELECT c.*, d.dept_name, d.dept_code
            FROM course c
            JOIN department d ON d.dept_id = c.dept_id
            ORDER BY c.course_code
        """)
        departments = query("SELECT * FROM department ORDER BY dept_code")
        return jsonify({
            'courses': courses,
            'departments': departments
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@academics_bp.route('/courses', methods=['POST'])
def create_course():
    data = request.get_json() or {}
    dept_id = data.get('dept_id')
    course_code = data.get('course_code')
    course_name = data.get('course_name')
    credits = data.get('credits', 4)
    course_type = data.get('course_type', 'Core')

    if not dept_id or not course_code or not course_name:
        return jsonify({'error': 'dept_id, course_code, and course_name are required.'}), 400

    try:
        course_id = query("""
            INSERT INTO course (dept_id, course_code, course_name, credits, course_type, status)
            VALUES (%s, %s, %s, %s, %s, 'Active')
        """, (dept_id, course_code.strip().upper(), course_name.strip(), credits, course_type), commit=True)

        return jsonify({
            'course_id': course_id,
            'message': f'Course {course_code} created successfully in MySQL!'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@academics_bp.route('/semesters', methods=['GET'])
def get_semesters():
    try:
        semesters = query("SELECT * FROM semester ORDER BY start_date DESC")
        return jsonify(semesters)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@academics_bp.route('/sections', methods=['GET'])
def get_sections():
    try:
        sections = query("""
            SELECT s.*, c.course_code, c.course_name, c.credits,
                   f.full_name AS faculty_name,
                   CONCAT(sm.academic_year, ' ', sm.term) AS semester_label,
                   (SELECT COUNT(*) FROM registration r WHERE r.section_id = s.section_id AND r.status != 'Dropped') AS enrolled
            FROM section s
            JOIN course c ON c.course_id = s.course_id
            JOIN faculty f ON f.faculty_id = s.faculty_id
            JOIN semester sm ON sm.semester_id = s.semester_id
            ORDER BY c.course_code, s.section_code
        """)
        courses = query("SELECT course_id, course_code, course_name FROM course WHERE status = 'Active' ORDER BY course_code")
        faculty = query("SELECT faculty_id, full_name, employee_code FROM faculty WHERE status = 'Active' ORDER BY full_name")
        semesters = query("SELECT semester_id, CONCAT(academic_year, ' ', term) AS semester_label FROM semester ORDER BY start_date DESC")

        return jsonify({
            'sections': sections,
            'courses': courses,
            'faculty': faculty,
            'semesters': semesters
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@academics_bp.route('/sections', methods=['POST'])
def create_section():
    data = request.get_json() or {}
    course_id = data.get('course_id')
    faculty_id = data.get('faculty_id')
    semester_id = data.get('semester_id')
    section_code = data.get('section_code')
    room_no = data.get('room_no')
    capacity = data.get('capacity', 60)

    if not course_id or not faculty_id or not semester_id or not section_code or not room_no:
        return jsonify({'error': 'All section fields are required.'}), 400

    try:
        section_id = query("""
            INSERT INTO section (course_id, faculty_id, semester_id, section_code, room_no, capacity)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (course_id, faculty_id, semester_id, section_code.strip().upper(), room_no.strip(), capacity), commit=True)

        return jsonify({
            'section_id': section_id,
            'message': f'Section {section_code} created successfully in MySQL!'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 400
