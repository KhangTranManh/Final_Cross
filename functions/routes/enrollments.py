from flask import Blueprint, jsonify

enrollments_bp = Blueprint('enrollments', __name__)

@enrollments_bp.route('/', methods=['GET'])
def get_enrollments():
    # Implement your enrollments logic here
    return jsonify({'message': 'Enrollments endpoint'})