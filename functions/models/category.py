from datetime import datetime
from firebase_admin import firestore


def get_db():
	"""Get Firestore client instance"""
	try:
		return firestore.client()
	except Exception as e:
		print(f"Error getting Firestore client: {e}")
		return None


class Category:
	def __init__(self, data=None):
		self.data = data or {}
		# Common fields based on exported database structure
		self.id = self.data.get('id', '')
		self.name = self.data.get('name', '')
		self.description = self.data.get('description', '')
		self.icon = self.data.get('icon', '')
		# Keep camelCase to match existing JSON (e.g., courses.json uses studentsCount)
		self.coursesCount = self.data.get('coursesCount', 0)
		self.createdAt = self.data.get('createdAt', datetime.utcnow())
		self.updatedAt = self.data.get('updatedAt', datetime.utcnow())

	def to_dict(self):
		return self.data or {
			'id': self.id,
			'name': self.name,
			'description': self.description,
			'icon': self.icon,
			'coursesCount': self.coursesCount,
			'createdAt': self.createdAt,
			'updatedAt': self.updatedAt,
		}

	def save(self):
		"""Create a new category document."""
		db = get_db()
		if not db:
			return None
		doc_ref = db.collection('categories').document()
		# Ensure ids are consistent
		self.data['id'] = doc_ref.id
		self.data['createdAt'] = self.data.get('createdAt', datetime.utcnow())
		self.data['updatedAt'] = datetime.utcnow()
		doc_ref.set(self.data)
		self.id = doc_ref.id
		return self

	def update(self, updates):
		"""Update category fields in Firestore and local cache."""
		db = get_db()
		if not db or not self.id:
			return False
		updates = dict(updates or {})
		updates['updatedAt'] = datetime.utcnow()
		db.collection('categories').document(self.id).update(updates)
		self.data.update(updates)
		# also update attributes if present
		for key, value in updates.items():
			setattr(self, key, value)
		return True

	def increment_course_count(self, delta=1):
		"""Atomically increment coursesCount."""
		db = get_db()
		if not db or not self.id:
			return False
		try:
			db.collection('categories').document(self.id).update({
				'coursesCount': firestore.Increment(delta),
				'updatedAt': datetime.utcnow(),
			})
			self.coursesCount = (self.coursesCount or 0) + delta
			self.updatedAt = datetime.utcnow()
			self.data['coursesCount'] = self.coursesCount
			self.data['updatedAt'] = self.updatedAt
			return True
		except Exception as e:
			print(f"Error incrementing coursesCount: {e}")
			return False

	@classmethod
	def get_by_id(cls, category_id):
		"""Fetch single category by id."""
		db = get_db()
		if not db:
			return None
		doc = db.collection('categories').document(category_id).get()
		if doc.exists:
			data = doc.to_dict()
			data['id'] = doc.id
			return cls(data)
		return None

	@classmethod
	def find_all(cls, filters=None):
		"""Return list of categories, with optional equality filters."""
		db = get_db()
		if not db:
			return []
		collection_ref = db.collection('categories')
		if filters:
			for key, value in filters.items():
				collection_ref = collection_ref.where(key, '==', value)
		docs = collection_ref.stream()
		categories = []
		for doc in docs:
			data = doc.to_dict()
			data['id'] = doc.id
			categories.append(cls(data))
		return categories
