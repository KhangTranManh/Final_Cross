import sys
import os

# Add UTF-8 encoding fixes at the top, before other imports
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
if sys.stderr.encoding != 'utf-8':
    sys.stderr.reconfigure(encoding='utf-8')

# Set default encoding environment variable
os.environ['PYTHONIOENCODING'] = 'utf-8'

from firebase_functions import https_fn, options
from firebase_admin import initialize_app, credentials
from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import firebase_admin

# Get the absolute path to the config file
current_dir = os.path.dirname(os.path.abspath(__file__))
service_account_path = os.path.join(current_dir, "config", "firebase-service-account.json")

# Initialize Firebase Admin with service account - only if not already initialized
if not firebase_admin._apps:
    try:
        # Try to use service account file if it exists
        if os.path.exists(service_account_path):
            cred = credentials.Certificate(service_account_path)
            initialize_app(cred)
        else:
            # For local development, use default credentials
            print("Service account file not found, using default credentials for local development")
            initialize_app()
    except Exception as e:
        print(f"Firebase initialization error: {e}")
        # For local development, try to initialize without credentials
        try:
            initialize_app()
        except Exception as e2:
            print(f"Failed to initialize Firebase: {e2}")

# Import your route handlers AFTER Firebase is initialized
from routes.auth import auth_bp
from routes.categories import categories_bp
from routes.courses import courses_bp
from routes.enrollments import enrollments_bp

# Create Flask app for routing
app = Flask(__name__)
app.url_map.strict_slashes = False

# Configure CORS with UTF-8 support
CORS(app, origins=["*"], supports_credentials=True)

# Add UTF-8 response headers globally
@app.after_request
def after_request(response):
    response.headers['Content-Type'] = 'application/json; charset=utf-8'
    return response

# Register blueprints (route modules)
app.register_blueprint(auth_bp, url_prefix='/auth')
app.register_blueprint(categories_bp, url_prefix='/categories')
app.register_blueprint(courses_bp, url_prefix='/courses')
app.register_blueprint(enrollments_bp, url_prefix='/enrollments')

@app.route('/')
def hello():
    return jsonify({
        'message': 'API is working',
        'status': 'success',
        'endpoints': {
            'auth': '/auth',
            'categories': '/categories', 
            'courses': '/courses',
            'enrollments': '/enrollments'
        }
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

# Simple Cloud Function export - avoid complex Flask integration
@https_fn.on_request(cors=options.CorsOptions(cors_origins=["*"], cors_methods=["get", "post", "put", "delete", "options"]))
def api(req):
    try:
        # Handle the request directly without Flask's full_dispatch_request
        path = req.path
        method = req.method.upper()
        
        print(f"Request: {method} {path}")
        
        # Route to courses
        if path == '/courses' or path == '/courses/':
            if method == 'GET':
                from models.course import Course
                courses = Course.find_all({'isPublished': True})
                course_list = [course.to_dict() for course in courses]
                
                return jsonify({
                    'success': True,
                    'data': course_list,
                    'count': len(course_list)
                })
        
        # Route to specific course by ID
        elif path.startswith('/courses/') and len(path.split('/')) == 3:
            course_id = path.split('/')[2]
            if method == 'GET':
                from models.course import Course
                course = Course.get_by_id(course_id)
                if course:
                    return jsonify({
                        'success': True,
                        'data': course.to_dict()
                    })
                else:
                    return jsonify({
                        'success': False,
                        'error': 'Course not found'
                    }), 404
        
        # Route to root
        elif path == '/' or path == '':
            return jsonify({
                'message': 'API is working',
                'status': 'success',
                'endpoints': {
                    'courses': '/courses',
                    'categories': '/categories'
                }
            })
        
        # Route to health
        elif path == '/health':
            return jsonify({'status': 'healthy'})
        
        # Route to categories
        elif path == '/categories' or path == '/categories/':
            if method == 'GET':
                from firebase_admin import firestore
                
                try:
                    db = firestore.client()
                    categories_ref = db.collection('categories')
                    docs = categories_ref.stream()
                    
                    categories = []
                    for doc in docs:
                        category_data = doc.to_dict()
                        category_data['id'] = doc.id
                        categories.append(category_data)
                    
                    return jsonify({
                        'success': True,
                        'data': categories,
                        'count': len(categories)
                    }), 200
                    
                except Exception as e:
                    return jsonify({
                        'success': False,
                        'error': str(e)
                    }), 500
        
        # Route to enrollment endpoints
        elif path.startswith('/enrollments'):
            if method == 'POST' and path == '/enrollments/enroll':
                from models.enrollment import Enrollment
                from models.course import Course
                
                try:
                    from firebase_admin import auth
                    auth_header = req.headers.get('Authorization')
                    if not auth_header or not auth_header.startswith('Bearer '):
                        return jsonify({'error': 'No token provided'}), 401
                    
                    token = auth_header.split(' ')[1]
                    decoded_token = auth.verify_id_token(token)
                    user_id = decoded_token['uid']
                    
                    data = req.get_json()
                    course_id = data.get('course_id')
                    
                    if not course_id:
                        return jsonify({'success': False, 'error': 'course_id is required'}), 400
                    
                    # Check if course exists
                    course = Course.get_by_id(course_id)
                    if not course:
                        return jsonify({'success': False, 'error': 'Course not found'}), 404
                    
                    # Check if already enrolled
                    existing = Enrollment.get_user_course_enrollment(user_id, course_id)
                    if existing:
                        return jsonify({
                            'success': False, 
                            'error': 'Already enrolled in this course',
                            'enrollment': existing.to_dict()
                        }), 400
                    
                    # Create enrollment
                    enrollment = Enrollment.create_enrollment(user_id, course_id)
                    if enrollment:
                        return jsonify({
                            'success': True,
                            'message': f'Successfully enrolled in {course.title}',
                            'enrollment': enrollment.to_dict()
                        }), 201
                    else:
                        return jsonify({'success': False, 'error': 'Failed to create enrollment'}), 500
                        
                except Exception as e:
                    return jsonify({'success': False, 'error': str(e)}), 500
            
            elif method == 'GET' and path == '/enrollments':
                from models.enrollment import Enrollment
                from models.course import Course
                
                try:
                    from firebase_admin import auth
                    auth_header = req.headers.get('Authorization')
                    if not auth_header or not auth_header.startswith('Bearer '):
                        return jsonify({'error': 'No token provided'}), 401
                    
                    token = auth_header.split(' ')[1]
                    decoded_token = auth.verify_id_token(token)
                    user_id = decoded_token['uid']
                    
                    enrollments = Enrollment.get_user_enrollments(user_id)
                    
                    # Get course details for each enrollment
                    enrollment_data = []
                    for enrollment in enrollments:
                        course = Course.get_by_id(enrollment.course_id)
                        enrollment_dict = enrollment.to_dict()
                        enrollment_dict['course'] = course.to_dict() if course else None
                        enrollment_data.append(enrollment_dict)
                    
                    return jsonify({
                        'success': True,
                        'enrollments': enrollment_data,
                        'count': len(enrollment_data)
                    }), 200
                        
                except Exception as e:
                    return jsonify({'success': False, 'error': str(e)}), 500
            
            elif method == 'GET' and path == '/enrollments/all':
                from models.enrollment import Enrollment
                from models.course import Course
                
                try:
                    enrollments = Enrollment.find_all()
                    
                    # Get course details for each enrollment
                    enrollment_data = []
                    for enrollment in enrollments:
                        course = Course.get_by_id(enrollment.course_id)
                        enrollment_dict = enrollment.to_dict()
                        enrollment_dict['course'] = course.to_dict() if course else None
                        enrollment_data.append(enrollment_dict)
                    
                    return jsonify({
                        'success': True,
                        'data': enrollment_data,
                        'count': len(enrollment_data)
                    }), 200
                    
                except Exception as e:
                    return jsonify({'success': False, 'error': str(e)}), 500
            
            elif method == 'GET' and path.startswith('/enrollments/check/'):
                from models.enrollment import Enrollment
                
                try:
                    from firebase_admin import auth
                    auth_header = req.headers.get('Authorization')
                    if not auth_header or not auth_header.startswith('Bearer '):
                        return jsonify({'error': 'No token provided'}), 401
                    
                    token = auth_header.split(' ')[1]
                    decoded_token = auth.verify_id_token(token)
                    user_id = decoded_token['uid']
                    
                    course_id = path.split('/')[3]  # /enrollments/check/{course_id}
                    enrollment = Enrollment.get_user_course_enrollment(user_id, course_id)
                    
                    return jsonify({
                        'success': True,
                        'enrolled': enrollment is not None,
                        'enrollment': enrollment.to_dict() if enrollment else None
                    }), 200
                        
                except Exception as e:
                    return jsonify({'success': False, 'error': str(e)}), 500
        
        # Route to auth register
        elif path == '/auth/register' and method == 'POST':
            from controllers.auth_controller import create_user_profile
            
            try:
                from firebase_admin import auth
                auth_header = req.headers.get('Authorization')
                if not auth_header or not auth_header.startswith('Bearer '):
                    return jsonify({'error': 'No token provided'}), 401
                
                token = auth_header.split(' ')[1]
                decoded_token = auth.verify_id_token(token)
                
                data = req.get_json()
                email = data.get('email')
                display_name = data.get('display_name')
                phone = data.get('phone')
                bio = data.get('bio')
                
                # Create user profile in Firestore
                profile_data = create_user_profile(
                    decoded_token['uid'], 
                    email, 
                    display_name,
                    {
                        'phone': phone,
                        'bio': bio,
                        'profile_complete': bool(display_name and phone)
                    }
                )
                
                if profile_data:
                    return jsonify({
                        'success': True,
                        'message': 'User registered successfully',
                        'user': profile_data
                    }), 201
                else:
                    return jsonify({
                        'success': False,
                        'error': 'Failed to create user profile'
                    }), 500
                        
            except Exception as e:
                return jsonify({'success': False, 'error': str(e)}), 400
        
        # Route to auth profile
        elif path == '/auth/profile':
            if method == 'GET':
                from controllers.auth_controller import verify_token, get_user_profile
                
                # Manually verify token
                try:
                    from firebase_admin import auth
                    auth_header = req.headers.get('Authorization')
                    if not auth_header or not auth_header.startswith('Bearer '):
                        return jsonify({'error': 'No token provided'}), 401
                    
                    token = auth_header.split(' ')[1]
                    decoded_token = auth.verify_id_token(token)
                    
                    # Create a mock request object for compatibility
                    class MockRequest:
                        def __init__(self, user):
                            self.user = user
                    
                    # Temporarily set request.user for the controller function
                    import controllers.auth_controller
                    original_request = getattr(controllers.auth_controller, 'request', None)
                    controllers.auth_controller.request = MockRequest(decoded_token)
                    
                    try:
                        user_profile = get_user_profile()
                        if user_profile:
                            return jsonify({'user': user_profile}), 200
                        else:
                            return jsonify({'error': 'Profile not found'}), 404
                    finally:
                        # Restore original request
                        controllers.auth_controller.request = original_request
                        
                except Exception as e:
                    return jsonify({'error': 'Invalid token'}), 401
            
            elif method == 'PUT':
                from controllers.auth_controller import update_user_profile
                
                try:
                    from firebase_admin import auth
                    import json
                    
                    auth_header = req.headers.get('Authorization')
                    if not auth_header or not auth_header.startswith('Bearer '):
                        return jsonify({'error': 'No token provided'}), 401
                    
                    token = auth_header.split(' ')[1]
                    decoded_token = auth.verify_id_token(token)
                    
                    # Parse request data
                    data = req.get_json()
                    uid = decoded_token['uid']
                    
                    # Filter allowed fields
                    allowed_fields = ['display_name', 'phone', 'bio', 'profile_picture_url']
                    update_data = {k: v for k, v in data.items() if k in allowed_fields}
                    
                    if update_user_profile(uid, update_data):
                        return jsonify({'message': 'Profile updated successfully'}), 200
                    else:
                        return jsonify({'error': 'Failed to update profile'}), 500
                        
                except Exception as e:
                    return jsonify({'error': str(e)}), 500
        
        # Default - not found
        return jsonify({
            'success': False,
            'error': 'Route not found',
            'path': path,
            'method': method
        }), 404
        
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500