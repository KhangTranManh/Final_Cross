import json
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import os

# Initialize Firebase Admin (for emulator)
if not firebase_admin._apps:
    # Use the service account for real database
    cred = credentials.Certificate("../config/firebase-service-account.json")
    firebase_admin.initialize_app(cred)

db = firestore.client()

def test_data_read():
    """Test reading data from Firestore"""
    print("=== TESTING DATA READ ===")
    
    # Test courses
    print("\n--- Testing Courses ---")
    courses_ref = db.collection('courses')
    courses = courses_ref.stream()
    
    course_count = 0
    for course in courses:
        course_count += 1
        data = course.to_dict()
        print(f"Course {course_count}: ID={course.id}")
        print(f"  Title: {data.get('title', 'No title')}")
        print(f"  Published: {data.get('isPublished', 'Not set')}")
        print(f"  Fields: {list(data.keys())}")
        print()
    
    if course_count == 0:
        print("❌ No courses found in database!")
    else:
        print(f"✅ Found {course_count} courses")
    
    # Test categories
    print("\n--- Testing Categories ---")
    categories_ref = db.collection('categories')
    categories = categories_ref.stream()
    
    category_count = 0
    for category in categories:
        category_count += 1
        data = category.to_dict()
        print(f"Category {category_count}: ID={category.id}")
        print(f"  Name: {data.get('name', 'No name')}")
        print()
    
    if category_count == 0:
        print("❌ No categories found in database!")
    else:
        print(f"✅ Found {category_count} categories")

def import_data():
    """Import data from JSON export"""
    print("=== STARTING DATA IMPORT ===")
    
    # Check if the JSON file exists
    json_file = '../backend/scripts/firestore-export-2025-09-04T09-23-35-008Z.json'
    if not os.path.exists(json_file):
        print(f"❌ JSON file not found: {json_file}")
        return
    
    # Load your exported data
    with open(json_file, 'r') as f:
        data = json.load(f)
    
    print(f"✅ Loaded JSON file with keys: {list(data.keys())}")
    
    # Import categories first
    if 'categories' in data:
        print(f"\n--- Importing {len(data['categories'])} categories ---")
        for category in data['categories']:
            category_data = category['data'].copy()
            # Convert timestamp objects if needed
            if 'createdAt' in category_data and isinstance(category_data['createdAt'], dict):
                category_data['createdAt'] = datetime.fromtimestamp(category_data['createdAt']['_seconds'])
            
            db.collection('categories').document(category['id']).set(category_data)
            print(f"✅ Imported category: {category['id']} - {category_data.get('name', 'Unknown')}")
    
    # Import courses
    if 'courses' in data:
        print(f"\n--- Importing {len(data['courses'])} courses ---")
        for course in data['courses']:
            course_data = course['data'].copy()
            # Convert timestamp objects
            if 'createdAt' in course_data and isinstance(course_data['createdAt'], dict):
                course_data['createdAt'] = datetime.fromtimestamp(course_data['createdAt']['_seconds'])
            if 'updatedAt' in course_data and isinstance(course_data['updatedAt'], dict):
                course_data['updatedAt'] = datetime.fromtimestamp(course_data['updatedAt']['_seconds'])
            
            db.collection('courses').document(course['id']).set(course_data)
            print(f"✅ Imported course: {course['id']} - {course_data.get('title', 'Unknown')}")
            print(f"   Published: {course_data.get('isPublished', 'Not set')}")
    
    # Import enrollments
    if 'enrollments' in data:
        print(f"\n--- Importing {len(data['enrollments'])} enrollments ---")
        for enrollment in data['enrollments']:
            enrollment_data = enrollment['data'].copy()
            # Convert timestamp objects
            if 'enrolledAt' in enrollment_data and isinstance(enrollment_data['enrolledAt'], dict):
                enrollment_data['enrolledAt'] = datetime.fromtimestamp(enrollment_data['enrolledAt']['_seconds'])
            if 'lastAccessed' in enrollment_data and isinstance(enrollment_data['lastAccessed'], dict):
                enrollment_data['lastAccessed'] = datetime.fromtimestamp(enrollment_data['lastAccessed']['_seconds'])
            
            db.collection('enrollments').document(enrollment['id']).set(enrollment_data)
            print(f"✅ Imported enrollment: {enrollment['id']}")
    
    print("\n🎉 Data import completed!")

def add_sample_data():
    """Add sample data if import doesn't work"""
    print("=== ADDING SAMPLE DATA ===")
    
    # Add a sample course
    sample_course = {
        'title': 'Flutter Development Fundamentals',
        'description': 'Complete guide to building mobile apps with Flutter framework',
        'instructor': 'Tech Instructor',
        'duration': 180,
        'difficulty': 'Beginner',
        'thumbnailUrl': 'https://example.com/flutter-course.jpg',
        'price': 99.99,
        'rating': 4.5,
        'studentsCount': 0,
        'category': 'Mobile Development',
        'isPublished': True,  # Make sure this field is set
        'createdAt': datetime.now(),
        'updatedAt': datetime.now(),
        'lessons': []
    }
    
    db.collection('courses').document('sample-course-001').set(sample_course)
    print("✅ Added sample course")

def test_course_model():
    """Test the Course model logic"""
    print("=== TESTING COURSE MODEL ===")
    
    try:
        # Import the Course model
        import sys
        sys.path.append('..')  # Add parent directory to path
        from models.course import Course
        
        print("✅ Course model imported successfully")
        
        # Test find_all with filter
        print("\n--- Testing Course.find_all with isPublished filter ---")
        courses = Course.find_all({'isPublished': True})
        print(f"Found {len(courses)} published courses")
        
        for i, course in enumerate(courses, 1):
            data = course.to_dict()
            print(f"Course {i}: {data.get('title', 'No title')}")
            print(f"  ID: {data.get('id', 'No ID')}")
            print(f"  Published: {data.get('isPublished', 'Not set')}")
        
        # Test find_all without filter
        print("\n--- Testing Course.find_all without filter ---")
        all_courses = Course.find_all()
        print(f"Found {len(all_courses)} total courses")
        
        return True
        
    except Exception as e:
        print(f"❌ Error testing Course model: {e}")
        import traceback
        traceback.print_exc()
        return False

def test_api_endpoint():
    """Test the API endpoint logic"""
    print("=== TESTING API ENDPOINT LOGIC ===")
    
    try:
        # Import Flask and create test context
        import sys
        sys.path.append('..')
        from main import app
        
        with app.test_client() as client:
            print("✅ Flask app created successfully")
            
            # Test the courses endpoint
            print("\n--- Testing /courses endpoint ---")
            response = client.get('/courses')
            print(f"Response status: {response.status_code}")
            print(f"Response data: {response.get_json()}")
            
            if response.status_code == 200:
                data = response.get_json()
                if data and data.get('success'):
                    print(f"✅ API returned {data.get('count', 0)} courses")
                    return True
                else:
                    print("❌ API response format is incorrect")
                    return False
            else:
                print(f"❌ API returned error status: {response.status_code}")
                return False
                
    except Exception as e:
        print(f"❌ Error testing API endpoint: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    print("Choose an option:")
    print("1. Test reading existing data")
    print("2. Import data from JSON")
    print("3. Add sample data")
    print("4. Test Course model")
    print("5. Test API endpoint")
    print("6. Full test (data + model + API)")
    
    choice = input("Enter choice (1-6): ").strip()
    
    if choice == "1":
        test_data_read()
    elif choice == "2":
        import_data()
        print("\nTesting imported data...")
        test_data_read()
    elif choice == "3":
        add_sample_data()
        print("\nTesting sample data...")
        test_data_read()
    elif choice == "4":
        test_course_model()
    elif choice == "5":
        test_api_endpoint()
    elif choice == "6":
        print("Running full test...")
        test_data_read()
        if test_course_model():
            test_api_endpoint()
    else:
        print("Invalid choice")