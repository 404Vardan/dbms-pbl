from flask import Blueprint, jsonify
from db import query

reports_bp = Blueprint('reports', __name__)

@reports_bp.route('/<tab>', methods=['GET'])
def get_report(tab):
    try:
        if tab == 'occupancy':
            sql = "SELECT * FROM v_section_occupancy ORDER BY course_code, section_code"
        elif tab == 'attendance':
            sql = "SELECT * FROM v_attendance_summary ORDER BY course_code, reg_no"
        elif tab == 'results':
            sql = "SELECT * FROM v_result_analysis ORDER BY course_code, exam_type"
        elif tab == 'history':
            sql = "SELECT * FROM v_student_academic_history ORDER BY reg_no, course_code"
        elif tab == 'dues':
            sql = "SELECT * FROM v_fee_dues ORDER BY balance DESC, bill_id"
        elif tab == 'departments':
            sql = "SELECT * FROM v_department_summary ORDER BY dept_code"
        else:
            return jsonify({'error': f'Unknown report tab: {tab}'}), 400

        data = query(sql)
        return jsonify(data)
    except Exception as e:
        return jsonify({'error': str(e)}), 500
