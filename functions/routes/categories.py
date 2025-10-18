from flask import Blueprint, jsonify
from firebase_admin import firestore

categories_bp = Blueprint('categories', __name__)

@categories_bp.route('/', methods=['GET'])
def get_categories():
    """Get all categories from Firestore"""
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
        print(f'Error getting categories: {e}')
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500