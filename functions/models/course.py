from firebase_admin import firestore
from datetime import datetime

# Now we can initialize directly since Firebase is initialized in main.py
db = firestore.client()

class Course:
    def __init__(self, data=None):
        self.data = data or {}
    
    def save(self):
        doc_ref = db.collection('courses').document()
        doc_ref.set(self.data)
        self.data['id'] = doc_ref.id
        return self
    
    @classmethod
    def find_all(cls, filters=None):
        """Find all courses with optional filters"""
        collection_ref = db.collection('courses')
        
        if filters:
            for key, value in filters.items():
                collection_ref = collection_ref.where(key, '==', value)
        
        docs = collection_ref.stream()
        courses = []
        
        for doc in docs:
            course_data = doc.to_dict()
            course_data['id'] = doc.id
            courses.append(cls(course_data))
            
        return courses
    
    @classmethod
    def get_by_id(cls, course_id):
        doc_ref = db.collection('courses').document(course_id)
        doc = doc_ref.get()
        if doc.exists:
            course_data = doc.to_dict()
            course_data['id'] = doc.id
            return cls(course_data)
        return None
    
    def to_dict(self):
        return self.data