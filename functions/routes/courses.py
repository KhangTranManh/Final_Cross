from flask import Blueprint, request, jsonify
from models.course import Course
from controllers.auth_controller import verify_token

courses_bp = Blueprint('courses', __name__)

@courses_bp.route('/', methods=['GET'])
def get_courses():
    try:
        courses = Course.find_all({'is_published': True})
        course_list = [course.to_dict() for course in courses]
        
        return jsonify({
            'success': True,
            'data': course_list,
            'count': len(course_list)
        })
    except Exception as e:
        print(f'Get courses error: {e}')
        return jsonify({'error': 'Failed to fetch courses'}), 500

@courses_bp.route('/<course_id>', methods=['GET'])
def get_course(course_id):
    try:
        course = Course.find_by_id(course_id)
        
        if not course:
            return jsonify({'error': 'Course not found'}), 404
        
        return jsonify({
            'success': True,
            'data': course.to_dict()
        })
    except Exception as e:
        print(f'Get course error: {e}')
        return jsonify({'error': 'Failed to fetch course'}), 500

@courses_bp.route('/', methods=['POST'])
@verify_token
def create_course():
    try:
        data = request.get_json()
        course = Course(data)
        course.save()
        
        return jsonify({
            'success': True,
            'message': 'Course created successfully',
            'data': course.to_dict()
        }), 201
    except Exception as e:
        print(f'Create course error: {e}')
        return jsonify({'error': 'Failed to create course'}), 500