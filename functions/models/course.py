from firebase_admin import firestore
from datetime import datetime

db = firestore.client()

class Course:
    def __init__(self, data=None):
        if data is None:
            data = {}
        
        self.id = data.get('id')
        self.title = data.get('title')
        self.description = data.get('description')
        self.instructor = data.get('instructor')
        self.duration = data.get('duration')
        self.difficulty = data.get('difficulty')
        self.thumbnail = data.get('thumbnail')
        self.price = data.get('price')
        self.rating = data.get('rating', 0)
        self.students_count = data.get('students_count', 0)
        self.category = data.get('category')
        self.lessons = data.get('lessons', [])
        self.is_published = data.get('is_published', False)
        self.created_at = data.get('created_at', firestore.SERVER_TIMESTAMP)
        self.updated_at = data.get('updated_at', firestore.SERVER_TIMESTAMP)

    def save(self):
        course_data = {
            'title': self.title,
            'description': self.description,
            'instructor': self.instructor,
            'duration': self.duration,
            'difficulty': self.difficulty,
            'thumbnail': self.thumbnail,
            'price': self.price,
            'rating': self.rating,
            'students_count': self.students_count,
            'category': self.category,
            'lessons': self.lessons,
            'is_published': self.is_published,
            'updated_at': firestore.SERVER_TIMESTAMP
        }

        if self.id:
            course_ref = db.collection('courses').document(self.id)
        else:
            course_ref = db.collection('courses').document()
            self.id = course_ref.id
            course_data['created_at'] = firestore.SERVER_TIMESTAMP

        course_ref.set(course_data)
        return self

    @staticmethod
    def find_by_id(course_id):
        course_doc = db.collection('courses').document(course_id).get()
        
        if not course_doc.exists:
            return None
        
        data = course_doc.to_dict()
        data['id'] = course_doc.id
        return Course(data)

    @staticmethod
    def find_all(filters=None):
        if filters is None:
            filters = {}
        
        query = db.collection('courses')

        if 'is_published' in filters:
            query = query.where('is_published', '==', filters['is_published'])

        courses = []
        for doc in query.stream():
            data = doc.to_dict()
            data['id'] = doc.id
            courses.append(Course(data))
        
        return courses

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'instructor': self.instructor,
            'duration': self.duration,
            'difficulty': self.difficulty,
            'thumbnail': self.thumbnail,
            'price': self.price,
            'rating': self.rating,
            'students_count': self.students_count,
            'category': self.category,
            'lessons': self.lessons,
            'is_published': self.is_published,
            'created_at': self.created_at,
            'updated_at': self.updated_at
        }