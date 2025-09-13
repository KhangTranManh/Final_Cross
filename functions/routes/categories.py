from flask import Blueprint, jsonify

categories_bp = Blueprint('categories', __name__)

@categories_bp.route('/', methods=['GET'])
def get_categories():
    # Implement your categories logic here
    return jsonify({'message': 'Categories endpoint'})