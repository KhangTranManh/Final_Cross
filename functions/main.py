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
    cred = credentials.Certificate(service_account_path)
    initialize_app(cred)

# Import your route handlers AFTER Firebase is initialized
from routes.auth import auth_bp
from routes.categories import categories_bp
from routes.courses import courses_bp
from routes.enrollments import enrollments_bp

# Create Flask app for routing
app = Flask(__name__)
app.url_map.strict_slashes = False

# Configure CORS
CORS(app, origins=["*"], supports_credentials=True)

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
        
        # Route to courses manually
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
        
        # Route to specific course
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