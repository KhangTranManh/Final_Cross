from firebase_admin import auth, firestore
from flask import request, jsonify
import functools

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

def get_user_profile():
    try:
        uid = request.user['uid']
        
        user_doc = get_db().collection('users').document(uid).get()
        
        if not user_doc.exists:
            firebase_user = auth.get_user(uid)
            user_data = {
                'uid': firebase_user.uid,
                'email': firebase_user.email,
                'display_name': firebase_user.display_name,
                'photo_url': firebase_user.photo_url,
                'email_verified': firebase_user.email_verified,
                'created_at': firebase_user.user_metadata.creation_timestamp
            }
            
            get_db().collection('users').document(uid).set(user_data)
            
            return jsonify({
                'success': True,
                'user': user_data
            })
        
        user_data = user_doc.to_dict()
        return jsonify({
            'success': True,
            'user': user_data
        })
    except Exception as e:
        print(f'Get profile error: {e}')
        return jsonify({'error': 'Failed to get user profile'}), 500

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

        db = get_db()  # Get client when needed
        db.collection('users').document(user_record.uid).set({
            'uid': user_record.uid,
            'email': email,
            'email_verified': False,
            'created_at': firestore.SERVER_TIMESTAMP
        })

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