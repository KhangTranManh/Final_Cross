from datetime import datetime
from firebase_admin import firestore
import uuid

class Enrollment:
    def __init__(self, enrollment_id=None, user_id=None, course_id=None,
                 enrolled_at=None, **kwargs):
        self.enrollment_id = enrollment_id or str(uuid.uuid4())
        self.user_id = user_id
        self.course_id = course_id
        self.enrolled_at = enrolled_at or datetime.utcnow()
        
        # Progress tracking
        self.progress = kwargs.get('progress', {
            'completed_lessons': [],
            'current_lesson': 0,
            'completion_percentage': 0.0,
            'total_time_spent': 0,  # in minutes
            'last_accessed': None
        })
        
        # Status
        self.status = kwargs.get('status', 'active')  # 'active', 'completed', 'dropped'
        self.completed_at = kwargs.get('completed_at')
        self.certificate_issued = kwargs.get('certificate_issued', False)
        
        # Rating and feedback
        self.rating = kwargs.get('rating')  # 1-5 stars
        self.review = kwargs.get('review')
        self.reviewed_at = kwargs.get('reviewed_at')

    @classmethod
    def from_dict(cls, data):
        """Create Enrollment object from dictionary"""
        return cls(**data)

    def to_dict(self):
        """Convert Enrollment object to dictionary"""
        return {
            'enrollment_id': self.enrollment_id,
            'user_id': self.user_id,
            'course_id': self.course_id,
            'enrolled_at': self.enrolled_at,
            'progress': self.progress,
            'status': self.status,
            'completed_at': self.completed_at,
            'certificate_issued': self.certificate_issued,
            'rating': self.rating,
            'review': self.review,
            'reviewed_at': self.reviewed_at
        }

    @classmethod
    def create_enrollment(cls, user_id, course_id):
        """Create new enrollment"""
        try:
            # Check if enrollment already exists
            existing = cls.get_user_course_enrollment(user_id, course_id)
            if existing:
                return existing
            
            # Create new enrollment
            enrollment = cls(user_id=user_id, course_id=course_id)
            
            # Save to Firestore
            db = firestore.client()
            db.collection('enrollments').document(enrollment.enrollment_id).set(enrollment.to_dict())
            
            # Update user enrollment count
            from models.user import User
            user = User.get_by_id(user_id)
            if user:
                user.increment_enrollment_count()
            
            return enrollment
        except Exception as e:
            print(f'Error creating enrollment: {e}')
            return None

    @classmethod
    def get_user_course_enrollment(cls, user_id, course_id):
        """Check if user is already enrolled in course"""
        try:
            db = firestore.client()
            enrollments = db.collection('enrollments')\
                           .where('user_id', '==', user_id)\
                           .where('course_id', '==', course_id)\
                           .limit(1)\
                           .stream()
            
            for enrollment in enrollments:
                return cls.from_dict(enrollment.to_dict())
            
            return None
        except Exception as e:
            print(f'Error checking enrollment: {e}')
            return None

    @classmethod
    def get_user_enrollments(cls, user_id):
        """Get all enrollments for a user"""
        try:
            db = firestore.client()
            enrollments = []
            
            docs = db.collection('enrollments')\
                    .where('user_id', '==', user_id)\
                    .order_by('enrolled_at', direction=firestore.Query.DESCENDING)\
                    .stream()
            
            for doc in docs:
                enrollments.append(cls.from_dict(doc.to_dict()))
            
            return enrollments
        except Exception as e:
            print(f'Error getting user enrollments: {e}')
            return []

    @classmethod
    def get_course_enrollments(cls, course_id):
        """Get all enrollments for a course"""
        try:
            db = firestore.client()
            enrollments = []
            
            docs = db.collection('enrollments')\
                    .where('course_id', '==', course_id)\
                    .stream()
            
            for doc in docs:
                enrollments.append(cls.from_dict(doc.to_dict()))
            
            return enrollments
        except Exception as e:
            print(f'Error getting course enrollments: {e}')
            return []

    def update_progress(self, lesson_id, time_spent=0):
        """Update learning progress"""
        try:
            # Add lesson to completed if not already there
            if lesson_id not in self.progress['completed_lessons']:
                self.progress['completed_lessons'].append(lesson_id)
            
            # Update time spent
            self.progress['total_time_spent'] += time_spent
            self.progress['last_accessed'] = datetime.utcnow()
            
            # Update current lesson (next lesson)
            self.progress['current_lesson'] = len(self.progress['completed_lessons'])
            
            # Save to Firestore
            db = firestore.client()
            db.collection('enrollments').document(self.enrollment_id).update({
                'progress': self.progress
            })
            
            return True
        except Exception as e:
            print(f'Error updating progress: {e}')
            return False

    def complete_course(self):
        """Mark course as completed"""
        try:
            self.status = 'completed'
            self.completed_at = datetime.utcnow()
            self.progress['completion_percentage'] = 100.0
            
            # Update user stats
            from models.user import User
            user = User.get_by_id(self.user_id)
            if user:
                user.update_learning_stats(
                    course_completed=True, 
                    learning_time=self.progress['total_time_spent']
                )
            
            # Save to Firestore
            db = firestore.client()
            db.collection('enrollments').document(self.enrollment_id).update({
                'status': self.status,
                'completed_at': self.completed_at,
                'progress': self.progress
            })
            
            return True
        except Exception as e:
            print(f'Error completing course: {e}')
            return False

    def add_review(self, rating, review_text):
        """Add rating and review"""
        try:
            self.rating = rating
            self.review = review_text
            self.reviewed_at = datetime.utcnow()
            
            # Save to Firestore
            db = firestore.client()
            db.collection('enrollments').document(self.enrollment_id).update({
                'rating': self.rating,
                'review': self.review,
                'reviewed_at': self.reviewed_at
            })
            
            return True
        except Exception as e:
            print(f'Error adding review: {e}')
            return False
