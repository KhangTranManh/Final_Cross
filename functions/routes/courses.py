from flask import Blueprint, request, jsonify
from models.course import Course  # Import from models, don't redefine
from controllers.auth_controller import verify_token
from firebase_admin import firestore
from datetime import datetime

courses_bp = Blueprint('courses', __name__)

def get_db():
    """Get Firestore client instance"""
    return firestore.client()

# Fix: Add strict_slashes=False to handle both /courses and /courses/
@courses_bp.route('', methods=['GET'], strict_slashes=False)
@courses_bp.route('/', methods=['GET'], strict_slashes=False)
def get_courses():
    try:
        print("Getting courses...")  # Debug print
        courses = Course.find_all({'isPublished': True})  # Note: check the field name
        course_list = [course.to_dict() for course in courses]
        
        print(f"Found {len(course_list)} courses")  # Debug print
        
        return jsonify({
            'success': True,
            'data': course_list,
            'count': len(course_list)
        })
    except Exception as e:
        print(f'Get courses error: {e}')
        return jsonify({
            'success': False,
            'error': 'Failed to fetch courses',
            'message': str(e)
        }), 500

@courses_bp.route('/<course_id>', methods=['GET'], strict_slashes=False)
def get_course_by_id(course_id):
    try:
        print(f"Getting course by ID: {course_id}")  # Debug print
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
            
    except Exception as e:
        print(f'Get course by ID error: {e}')
        return jsonify({
            'success': False,
            'error': 'Failed to fetch course',
            'message': str(e)
        }), 500

@courses_bp.route('/', methods=['POST'])
@verify_token
def create_course():
    try:
        data = request.get_json()
        
        # Add timestamps
        data['createdAt'] = datetime.now()
        data['updatedAt'] = datetime.now()
        
        course = Course(data)
        course.save()
        
        return jsonify({
            'success': True,
            'data': course.to_dict(),
            'message': 'Course created successfully'
        }), 201
        
    except Exception as e:
        print(f'Create course error: {e}')
        return jsonify({
            'success': False,
            'error': 'Failed to create course',
            'message': str(e)
        }), 500