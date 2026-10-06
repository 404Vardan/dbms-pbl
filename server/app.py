import os
from flask import Flask, jsonify
from flask_cors import CORS
from dotenv import load_dotenv

# Import route blueprints
from routes.auth import auth_bp
from routes.dashboard import dashboard_bp
from routes.students import students_bp
from routes.registration import registration_bp
from routes.attendance import attendance_bp
from routes.examinations import examinations_bp
from routes.fees import fees_bp
from routes.reports import reports_bp
from routes.academics import academics_bp

load_dotenv()

app = Flask(__name__)
CORS(app)

# Register route blueprints
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(dashboard_bp, url_prefix='/api/dashboard')
app.register_blueprint(students_bp, url_prefix='/api/students')
app.register_blueprint(registration_bp, url_prefix='/api/registration')
app.register_blueprint(attendance_bp, url_prefix='/api/attendance')
app.register_blueprint(examinations_bp, url_prefix='/api/examinations')
app.register_blueprint(fees_bp, url_prefix='/api/fees')
app.register_blueprint(reports_bp, url_prefix='/api/reports')
app.register_blueprint(academics_bp, url_prefix='/api')

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'backend': 'Python / Flask',
        'database': 'MySQL 8.0+',
        'connector': 'mysql-connector-python',
        'application': 'Student & College Management System (SCMS)'
    })

@app.errorhandler(404)
def not_found(error):
    return jsonify({'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def server_error(error):
    return jsonify({'error': 'Internal server error'}), 500

if __name__ == '__main__':
    port = int(os.getenv("PORT", 5000))
    debug = os.getenv("FLASK_ENV", "development") == "development"
    print(f"============================================================")
    print(f" SCMS Backend Server (Python / Flask)")
    print(f" Database Engine   : MySQL (scms_db)")
    print(f" Connector         : mysql-connector-python")
    print(f" Listening Address : http://localhost:{port}")
    print(f"============================================================")
    app.run(host='0.0.0.0', port=port, debug=debug)
