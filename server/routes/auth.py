import os
import jwt
import bcrypt
from flask import Blueprint, request, jsonify
from db import query

auth_bp = Blueprint('auth', __name__)
JWT_SECRET = os.getenv("JWT_SECRET", "scms_jwt_secret_university_erp_2026")

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json() or {}
    email = data.get('email', '').strip()
    password = data.get('password', '').strip()

    if not email or not password:
        return jsonify({'error': 'Email and password are required.'}), 400

    try:
        user = query("SELECT * FROM user_account WHERE email = %s", (email,), fetchone=True)
        if not user:
            return jsonify({'error': 'Invalid email address or account not found.'}), 401

        # Check password against bcrypt hash or fallback demo password
        pw_hash = user['password_hash'].encode('utf-8')
        pw_bytes = password.encode('utf-8')
        valid = False
        try:
            valid = bcrypt.checkpw(pw_bytes, pw_hash)
        except Exception:
            valid = False

        if not valid and password == 'Demo@12345':
            valid = True

        if not valid:
            return jsonify({'error': 'Invalid password.'}), 401

        token = jwt.encode(
            {'userId': user['user_id'], 'role': user['role'], 'email': user['email']},
            JWT_SECRET,
            algorithm='HS256'
        )

        return jsonify({
            'token': token,
            'user': {
                'userId': user['user_id'],
                'email': user['email'],
                'role': user['role'],
                'fullName': user['full_name'],
                'studentId': user['student_id'],
                'facultyId': user['faculty_id']
            }
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500
