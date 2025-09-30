from flask import Blueprint, jsonify, request
from controllers.auth_controller import verify_token, get_user_profile, update_user_profile, create_user_profile
from firebase_admin import auth

auth_bp = Blueprint('auth', __name__)

@auth_bp.route('/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        display_name = data.get('display_name')
        
        # Create user in Firebase Auth
        user_record = auth.create_user(
            email=email,
            password=password,
            display_name=display_name
        )
        
        # Create user profile in Firestore
        profile_data = create_user_profile(
            user_record.uid, 
            email, 
            display_name,
            {
                'phone': data.get('phone'),
                'bio': data.get('bio'),
                'profile_complete': bool(display_name and data.get('phone'))
            }
        )
        
        return jsonify({
            'message': 'User registered successfully',
            'user': profile_data
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@auth_bp.route('/login', methods=['POST'])
def login():
    return jsonify({'message': 'Auth login endpoint'})

@auth_bp.route('/profile', methods=['GET'])
@verify_token
def profile():
    try:
        user_profile = get_user_profile()
        if user_profile:
            return jsonify({'user': user_profile}), 200
        else:
            return jsonify({'error': 'Profile not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/profile', methods=['PUT'])
@verify_token
def update_profile():
    try:
        data = request.get_json()
        uid = request.user['uid']
        
        # Filter allowed fields
        allowed_fields = ['display_name', 'phone', 'bio', 'profile_picture_url']
        update_data = {k: v for k, v in data.items() if k in allowed_fields}
        
        if update_user_profile(uid, update_data):
            return jsonify({'message': 'Profile updated successfully'}), 200
        else:
            return jsonify({'error': 'Failed to update profile'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500