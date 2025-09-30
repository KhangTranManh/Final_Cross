from firebase_admin import auth, firestore
from flask import request, jsonify
import functools
from datetime import datetime

def get_db():
    """Get Firestore client instance"""
    return firestore.client()

def verify_token(f):
    @functools.wraps(f)
    def decorated_function(*args, **kwargs):
        try:
            auth_header = request.headers.get('Authorization')
            if not auth_header or not auth_header.startswith('Bearer '):
                return jsonify({'error': 'No token provided'}), 401
            
            token = auth_header.split(' ')[1]
            decoded_token = auth.verify_id_token(token)
            request.user = decoded_token
            return f(*args, **kwargs)
        except Exception as e:
            print(f'Token verification error: {e}')
            return jsonify({'error': 'Invalid token'}), 401
    
    return decorated_function

def create_user_profile(uid, email, display_name=None, additional_data=None):
    """Create user profile in Firestore using enhanced User model"""
    try:
        from models.user import User
        
        # Create User object with enhanced data
        user = User(
            uid=uid,
            email=email,
            display_name=display_name or email.split('@')[0],
            phone=additional_data.get('phone') if additional_data else None,
            bio=additional_data.get('bio') if additional_data else None,
            profile_complete=additional_data.get('profile_complete', False) if additional_data else False
        )
        
        # Validate and save
        validation_errors = user.validate()
        if validation_errors:
            print(f'User validation errors: {validation_errors}')
            return None
        
        success = user.save()
        if success:
            return user.to_dict()
        else:
            return None
            
    except Exception as e:
        print(f'Error creating user profile: {e}')
        return None

def get_user_profile():
    """Get user profile from Firestore using enhanced User model"""
    try:
        uid = request.user['uid']
        from models.user import User
        
        # Try to get existing user
        user = User.get_by_id(uid)
        
        if user:
            return user.to_dict()
        else:
            # Create profile if doesn't exist (for existing Firebase Auth users)
            user_record = auth.get_user(uid)
            return create_user_profile(uid, user_record.email, user_record.display_name)
    except Exception as e:
        print(f'Error getting user profile: {e}')
        return None

def update_user_profile(uid, update_data):
    """Update user profile in Firestore using enhanced User model"""
    try:
        from models.user import User
        
        user = User.get_by_id(uid)
        if user:
            return user.update(update_data)
        else:
            print(f'User not found: {uid}')
            return False
    except Exception as e:
        print(f'Error updating user profile: {e}')
        return False

def register_user():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        user_record = auth.create_user(
            email=email,
            password=password,
            email_verified=False
        )

        create_user_profile(user_record.uid, email)

        return jsonify({
            'success': True,
            'message': 'User registered successfully',
            'uid': user_record.uid
        }), 201

    except Exception as e:
        print(f'Registration error: {e}')
        return jsonify({
            'success': False,
            'message': str(e)
        }), 400

def login_user():
    try:
        return jsonify({
            'success': True,
            'message': 'Use Firebase Auth SDK for authentication'
        })
    except Exception as e:
        print(f'Login error: {e}')
        return jsonify({'error': 'Login failed'}), 500