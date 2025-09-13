# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn, options
from firebase_admin import initialize_app
import json
from flask import Flask, request, jsonify
from flask_cors import CORS

# Import your route handlers
from routes.auth import auth_bp
from routes.categories import categories_bp
from routes.courses import courses_bp
from routes.enrollments import enrollments_bp

# Initialize Firebase Admin
initialize_app()

# Create Flask app for routing
app = Flask(__name__)

# Configure CORS
CORS(app, origins=[
    "http://localhost:*",
    "http://127.0.0.1:*",
    "https://localhost:*",
    "https://127.0.0.1:*"
], supports_credentials=True)

# Register blueprints (route modules)
app.register_blueprint(auth_bp, url_prefix='/auth')
app.register_blueprint(categories_bp, url_prefix='/categories')
app.register_blueprint(courses_bp, url_prefix='/courses')
app.register_blueprint(enrollments_bp, url_prefix='/enrollments')

# Health check route
@app.route('/')
def health_check():
    return jsonify({
        "message": "Final Cross API is running on Cloud Functions!",
        "status": "OK",
        "timestamp": "2024-01-01T00:00:00Z"
    })

# Error handlers
@app.errorhandler(404)
def not_found(error):
    return jsonify({
        "success": False,
        "message": f"Route {request.path} not found"
    }), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({
        "success": False,
        "message": "Internal server error"
    }), 500

# Export as Cloud Function
@https_fn.on_request(
    cors=options.CorsOptions(
        cors_origins=["*"],
        cors_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    ),
    max_instances=10
)
def api(req: https_fn.Request) -> https_fn.Response:
    with app.request_context(req.environ):
        return app.full_dispatch_request()