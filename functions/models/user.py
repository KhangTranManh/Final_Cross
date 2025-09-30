from datetime import datetime
from firebase_admin import firestore

class User:
    def __init__(self, uid=None, email=None, display_name=None, phone=None, bio=None, 
                 role='student', profile_picture_url=None, enrollment_count=0, 
                 created_at=None, updated_at=None, profile_complete=False, **kwargs):
        self.uid = uid
        self.email = email
        self.display_name = display_name
        self.phone = phone
        self.bio = bio
        self.role = role  # 'student', 'instructor', 'admin'
        self.profile_picture_url = profile_picture_url
        self.enrollment_count = enrollment_count
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()
        self.profile_complete = profile_complete
        
        # Learning preferences
        self.preferences = kwargs.get('preferences', {
            'notifications': True,
            'email_updates': True,
            'difficulty_preference': 'beginner'
        })
        
        # Learning stats
        self.stats = kwargs.get('stats', {
            'courses_completed': 0,
            'total_learning_time': 0,  # in minutes
            'certificates_earned': 0,
            'current_streak': 0
        })

    @classmethod
    def from_dict(cls, data):
        """Create User object from dictionary"""
        return cls(**data)

    def to_dict(self):
        """Convert User object to dictionary"""
        return {
            'uid': self.uid,
            'email': self.email,
            'display_name': self.display_name,
            'phone': self.phone,
            'bio': self.bio,
            'role': self.role,
            'profile_picture_url': self.profile_picture_url,
            'enrollment_count': self.enrollment_count,
            'created_at': self.created_at,
            'updated_at': self.updated_at,
            'profile_complete': self.profile_complete,
            'preferences': self.preferences,
            'stats': self.stats
        }

    @classmethod
    def get_by_id(cls, uid):
        """Get user by UID from Firestore"""
        try:
            db = firestore.client()
            doc = db.collection('users').document(uid).get()
            if doc.exists:
                return cls.from_dict(doc.to_dict())
            return None
        except Exception as e:
            print(f'Error getting user: {e}')
            return None

    def save(self):
        """Save user to Firestore"""
        try:
            db = firestore.client()
            self.updated_at = datetime.utcnow()
            db.collection('users').document(self.uid).set(self.to_dict())
            return True
        except Exception as e:
            print(f'Error saving user: {e}')
            return False

    def update(self, data):
        """Update user fields"""
        allowed_fields = [
            'display_name', 'phone', 'bio', 'profile_picture_url', 
            'preferences', 'profile_complete'
        ]
        
        for key, value in data.items():
            if key in allowed_fields:
                setattr(self, key, value)
        
        self.updated_at = datetime.utcnow()
        return self.save()

    def increment_enrollment_count(self):
        """Increment user's enrollment count"""
        self.enrollment_count += 1
        self.updated_at = datetime.utcnow()
        return self.save()

    def update_learning_stats(self, course_completed=False, learning_time=0):
        """Update user learning statistics"""
        if course_completed:
            self.stats['courses_completed'] += 1
        
        self.stats['total_learning_time'] += learning_time
        self.updated_at = datetime.utcnow()
        return self.save()

    def validate(self):
        """Validate user data"""
        errors = []
        
        if not self.email:
            errors.append('Email is required')
        
        if self.role not in ['student', 'instructor', 'admin']:
            errors.append('Invalid role')
            
        return errors