from flask import Blueprint, jsonify, request
from firebase_admin import firestore
from controllers.auth_controller import verify_token
from models.enrollment import Enrollment
from models.course import Course

enrollments_bp = Blueprint('enrollments', __name__)

@enrollments_bp.route('/all', methods=['GET'])
def get_all_enrollments():
    """Get all enrollments (admin endpoint for export)"""
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
        print(f'Error getting all enrollments: {e}')
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@enrollments_bp.route('/', methods=['GET'])
@verify_token
def get_user_enrollments():
    """Get all enrollments for the current user"""
    try:
        user_id = request.user['uid']
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
        print(f'Error getting enrollments: {e}')
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@enrollments_bp.route('/enroll', methods=['POST'])
@verify_token
def enroll_in_course():
    """Enroll current user in a course"""
    try:
        data = request.get_json()
        course_id = data.get('course_id')
        
        if not course_id:
            return jsonify({
                'success': False,
                'error': 'course_id is required'
            }), 400
        
        user_id = request.user['uid']
        
        # Check if course exists
        course = Course.get_by_id(course_id)
        if not course:
            return jsonify({
                'success': False,
                'error': 'Course not found'
            }), 404
        
        # Check if user is already enrolled
        existing_enrollment = Enrollment.get_user_course_enrollment(user_id, course_id)
        if existing_enrollment:
            return jsonify({
                'success': False,
                'error': 'Already enrolled in this course',
                'enrollment': existing_enrollment.to_dict()
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
            return jsonify({
                'success': False,
                'error': 'Failed to create enrollment'
            }), 500
            
    except Exception as e:
        print(f'Error enrolling in course: {e}')
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@enrollments_bp.route('/<enrollment_id>/progress', methods=['PUT'])
@verify_token
def update_enrollment_progress():
    """Update progress for an enrollment"""
    try:
        enrollment_id = request.view_args['enrollment_id']
        data = request.get_json()
        
        lesson_id = data.get('lesson_id')
        time_spent = data.get('time_spent', 0)
        
        if not lesson_id:
            return jsonify({
                'success': False,
                'error': 'lesson_id is required'
            }), 400
        
        # Get enrollment and verify ownership
        user_id = request.user['uid']
        db = firestore.client()
        enrollment_doc = db.collection('enrollments').document(enrollment_id).get()
        
        if not enrollment_doc.exists:
            return jsonify({
                'success': False,
                'error': 'Enrollment not found'
            }), 404
        
        enrollment_data = enrollment_doc.to_dict()
        if enrollment_data['user_id'] != user_id:
            return jsonify({
                'success': False,
                'error': 'Unauthorized'
            }), 403
        
        # Update progress
        enrollment = Enrollment.from_dict(enrollment_data)
        success = enrollment.update_progress(lesson_id, time_spent)
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Progress updated successfully',
                'progress': enrollment.progress
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to update progress'
            }), 500
            
    except Exception as e:
        print(f'Error updating progress: {e}')
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@enrollments_bp.route('/<enrollment_id>/complete', methods=['PUT'])
@verify_token
def complete_course():
    """Mark a course as completed"""
    try:
        enrollment_id = request.view_args['enrollment_id']
        user_id = request.user['uid']
        
        # Get enrollment and verify ownership
        db = firestore.client()
        enrollment_doc = db.collection('enrollments').document(enrollment_id).get()
        
        if not enrollment_doc.exists:
            return jsonify({
                'success': False,
                'error': 'Enrollment not found'
            }), 404
        
        enrollment_data = enrollment_doc.to_dict()
        if enrollment_data['user_id'] != user_id:
            return jsonify({
                'success': False,
                'error': 'Unauthorized'
            }), 403
        
        # Complete course
        enrollment = Enrollment.from_dict(enrollment_data)
        success = enrollment.complete_course()
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Course completed successfully!',
                'enrollment': enrollment.to_dict()
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to complete course'
            }), 500
            
    except Exception as e:
        print(f'Error completing course: {e}')
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@enrollments_bp.route('/<enrollment_id>/review', methods=['PUT'])
@verify_token
def add_course_review():
    """Add rating and review for a completed course"""
    try:
        enrollment_id = request.view_args['enrollment_id']
        data = request.get_json()
        
        rating = data.get('rating')
        review_text = data.get('review')
        
        if not rating or not (1 <= rating <= 5):
            return jsonify({
                'success': False,
                'error': 'Rating must be between 1 and 5'
            }), 400
        
        user_id = request.user['uid']
        
        # Get enrollment and verify ownership
        db = firestore.client()
        enrollment_doc = db.collection('enrollments').document(enrollment_id).get()
        
        if not enrollment_doc.exists:
            return jsonify({
                'success': False,
                'error': 'Enrollment not found'
            }), 404
        
        enrollment_data = enrollment_doc.to_dict()
        if enrollment_data['user_id'] != user_id:
            return jsonify({
                'success': False,
                'error': 'Unauthorized'
            }), 403
        
        # Add review
        enrollment = Enrollment.from_dict(enrollment_data)
        success = enrollment.add_review(rating, review_text)
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Review added successfully',
                'enrollment': enrollment.to_dict()
            }), 200
        else:
            return jsonify({
                'success': False,
                'error': 'Failed to add review'
            }), 500
            
    except Exception as e:
        print(f'Error adding review: {e}')
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@enrollments_bp.route('/check/<course_id>', methods=['GET'])
@verify_token
def check_enrollment_status():
    """Check if user is enrolled in a specific course"""
    try:
        course_id = request.view_args['course_id']
        user_id = request.user['uid']
        
        enrollment = Enrollment.get_user_course_enrollment(user_id, course_id)
        
        return jsonify({
            'success': True,
            'enrolled': enrollment is not None,
            'enrollment': enrollment.to_dict() if enrollment else None
        }), 200
        
    except Exception as e:
        print(f'Error checking enrollment: {e}')
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500