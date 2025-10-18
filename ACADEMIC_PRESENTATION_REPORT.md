# 🎓 ACADEMIC PRESENTATION REPORT
## Firebase Integration in Flutter Applications: A Complete E-Learning Platform Implementation

---

### 📋 **PROJECT OVERVIEW**

**Topic**: Firebase Services Integration in Flutter Applications  
**Focus**: Authentication, Real-time Databases (Firestore), and Cloud Functions  
**Demo Project**: Final_Cross E-Learning Platform  
**Team**: [Your Team Names]  
**Date**: October 9, 2025  

---

## 🎯 **OBJECTIVE**

**Primary Objective**: Explore the comprehensive integration of Firebase services into Flutter applications, focusing on:
- Firebase Authentication for secure user management
- Firestore real-time database for data persistence and retrieval
- Firebase Cloud Functions for serverless backend logic

**Secondary Objectives**:
- Demonstrate practical implementation of Firebase services in a real-world application
- Analyze best practices for Firebase-Flutter integration
- Evaluate performance and scalability of Firebase-based architecture
- Document challenges and solutions encountered during development

---

## 📚 **THEORETICAL BACKGROUND & RESEARCH**

### **1. Firebase Authentication**
**Research Sources**:
- Firebase Official Documentation: Authentication Overview
- Flutter Firebase Auth Plugin Documentation
- Google Cloud Identity & Access Management Best Practices
- Academic Papers on Mobile Authentication Security

**Key Concepts Explored**:
- **JWT Token-Based Authentication**: Secure token exchange between client and server
- **Multi-Factor Authentication**: Enhanced security layers
- **OAuth Integration**: Social login capabilities
- **Session Management**: Token refresh and lifecycle management

**Theoretical Foundation**:
```
Firebase Authentication provides a complete identity solution with:
- Client-side authentication SDKs
- Server-side verification capabilities
- Integration with other Firebase services
- Support for multiple authentication providers
```

### **2. Firestore Real-Time Database**
**Research Sources**:
- Firestore Documentation: Data Model and Queries
- NoSQL Database Design Principles
- Real-time Synchronization Architecture Papers
- Firebase Performance Best Practices Guide

**Key Concepts Explored**:
- **NoSQL Document Model**: Flexible schema design
- **Real-time Listeners**: Live data synchronization
- **Offline Capabilities**: Local caching and sync
- **Security Rules**: Database-level access control
- **Composite Indexes**: Query optimization

**Theoretical Foundation**:
```
Firestore provides a scalable NoSQL database with:
- Real-time synchronization across clients
- Offline support with automatic sync
- ACID transactions for data consistency
- Automatic multi-region replication
```

### **3. Firebase Cloud Functions**
**Research Sources**:
- Firebase Cloud Functions Documentation
- Serverless Architecture Patterns
- Google Cloud Functions Runtime Environment
- Microservices Architecture Research

**Key Concepts Explored**:
- **Event-Driven Architecture**: Function triggers and responses
- **Serverless Computing**: No server management required
- **HTTP Triggers**: RESTful API endpoint creation
- **Background Triggers**: Database and storage event handling
- **Cold Start Optimization**: Performance considerations

**Theoretical Foundation**:
```
Firebase Cloud Functions enable serverless backend logic with:
- Automatic scaling based on demand
- Pay-per-execution pricing model
- Integration with Firebase and Google Cloud services
- Support for multiple programming languages
```

---

## 🏗️ **DEMO APPLICATION ARCHITECTURE**

### **Application Overview: Final_Cross E-Learning Platform**

**Purpose**: A comprehensive mobile e-learning platform demonstrating Firebase integration
**Target Users**: Students, instructors, and administrators
**Platform**: Cross-platform mobile application (iOS/Android)

### **Architecture Diagram**
```
┌─────────────────┐    HTTP/HTTPS     ┌──────────────────────┐
│  Flutter App    │ ◄──────────────► │ Firebase Cloud       │
│  (Frontend)     │                   │ Functions (Backend)  │
│                 │                   │                      │
│ ┌─────────────┐ │                   │ ┌──────────────────┐ │
│ │ Auth Pages  │ │                   │ │ Authentication   │ │
│ │ Course List │ │                   │ │ Logic            │ │
│ │ Enrollment  │ │                   │ │                  │ │
│ │ Profile     │ │                   │ │ Course           │ │
│ └─────────────┘ │                   │ │ Management       │ │
└─────────────────┘                   │ │                  │ │
         │                             │ │ Enrollment       │ │
         │ Firebase SDKs               │ │ Processing       │ │
         ▼                             │ └──────────────────┘ │
┌─────────────────┐                   └──────────────────────┘
│ Firebase Auth   │                            │
│                 │                            │ Admin SDK
└─────────────────┘                            ▼
         │                             ┌──────────────────────┐
         │                             │ Firestore Database   │
         ▼                             │                      │
┌─────────────────┐                   │ ┌──────────────────┐ │
│ Firestore DB    │ ◄─────────────────┤ │ Collections:     │ │
│                 │                   │ │ • users          │ │
│ Real-time Sync  │                   │ │ • courses        │ │
│ Offline Support │                   │ │ • enrollments    │ │
└─────────────────┘                   │ │ • categories     │ │
                                      │ └──────────────────┘ │
                                      └──────────────────────┘
```

### **Technology Stack**
| Layer | Technology | Purpose |
|-------|------------|---------|
| **Frontend** | Flutter 3.x | Cross-platform mobile development |
| **Authentication** | Firebase Auth | User identity management |
| **Database** | Firestore | Real-time NoSQL database |
| **Backend Logic** | Cloud Functions (Python) | Serverless API endpoints |
| **Hosting** | Firebase Hosting | Web deployment |
| **Storage** | Firebase Storage | File and media storage |

---

## 💻 **IMPLEMENTATION DETAILS**

### **1. Firebase Authentication Implementation**

**Code Example - Registration Process**:
```dart
// Flutter Client-Side Implementation
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<UserCredential?> register(String email, String password, String displayName, String phone) async {
    try {
      // Firebase Auth Registration
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create detailed user profile via Cloud Function
      await _createUserProfile(credential.user!, displayName, phone);
      return credential;
      
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  Future<void> _createUserProfile(User user, String displayName, String phone) async {
    final idToken = await user.getIdToken();
    
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': user.email,
        'display_name': displayName,
        'phone': phone,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to create user profile');
    }
  }
  
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
```

**Authentication State Management**:
```dart
// Reactive Authentication State Provider
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;
  
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  
  AuthProvider() {
    // Listen to authentication state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    });
  }
  
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
      notifyListeners();
    }
  }
}
```

**Cloud Function - Server-Side Verification**:
```python
# functions/routes/auth.py
from firebase_functions import https_fn, options
from firebase_admin import auth, firestore
from models.user import User
import json

@https_fn.on_request(cors=options.CorsOptions(
    cors_origins=["*"],
    cors_methods=["post", "options"]
))
def handle_auth_register(req):
    if req.method == 'OPTIONS':
        return ('', 204, {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        })
    
    try:
        # Extract and verify Firebase ID token
        auth_header = req.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return {'error': 'No valid authorization header'}, 401
        
        token = auth_header.replace('Bearer ', '')
        decoded_token = auth.verify_id_token(token)
        
        # Get request data
        data = req.get_json()
        
        # Create enhanced user profile in Firestore
        user_data = {
            'uid': decoded_token['uid'],
            'email': data.get('email'),
            'display_name': data.get('display_name'),
            'phone': data.get('phone', ''),
            'role': 'student',
            'enrollment_count': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'preferences': {
                'notifications': True,
                'theme': 'light',
                'language': 'en'
            },
            'stats': {
                'courses_completed': 0,
                'total_learning_time': 0,
                'certificates_earned': 0
            }
        }
        
        # Save to Firestore
        db = firestore.client()
        db.collection('users').document(decoded_token['uid']).set(user_data)
        
        return {
            'success': True, 
            'message': 'User profile created successfully',
            'user': user_data
        }
        
    except Exception as e:
        return {'error': f'Registration failed: {str(e)}'}, 500
```

**Key Implementation Features**:
- ✅ Secure token-based authentication
- ✅ Enhanced user profile creation
- ✅ Client-server token verification
- ✅ Comprehensive error handling and validation
- ✅ Real-time authentication state management
- ✅ Role-based access control preparation

### **2. Firestore Database Implementation**

**Data Model Design**:
```dart
// lib/models/user.dart
class User {
  final String uid;
  final String email;
  final String displayName;
  final String phone;
  final String role;
  final int enrollmentCount;
  final DateTime createdAt;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> stats;
  
  User({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.phone,
    required this.role,
    required this.enrollmentCount,
    required this.createdAt,
    required this.preferences,
    required this.stats,
  });
  
  factory User.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['display_name'] ?? '',
      phone: data['phone'] ?? '',
      role: data['role'] ?? 'student',
      enrollmentCount: data['enrollment_count'] ?? 0,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      preferences: data['preferences'] ?? {},
      stats: data['stats'] ?? {},
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'display_name': displayName,
      'phone': phone,
      'role': role,
      'enrollment_count': enrollmentCount,
      'created_at': Timestamp.fromDate(createdAt),
      'preferences': preferences,
      'stats': stats,
    };
  }
}
```

```dart
// lib/models/course.dart
class Course {
  final String id;
  final String title;
  final String description;
  final String instructor;
  final int duration; // in minutes
  final double price;
  final double rating;
  final int studentsCount;
  final List<Lesson> lessons;
  final bool isPublished;
  final DateTime createdAt;
  final String category;
  final String difficulty;
  final String imageUrl;
  
  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.instructor,
    required this.duration,
    required this.price,
    required this.rating,
    required this.studentsCount,
    required this.lessons,
    required this.isPublished,
    required this.createdAt,
    required this.category,
    required this.difficulty,
    required this.imageUrl,
  });
  
  factory Course.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Course(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      instructor: data['instructor'] ?? '',
      duration: data['duration'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      rating: (data['rating'] ?? 0.0).toDouble(),
      studentsCount: data['students_count'] ?? 0,
      lessons: (data['lessons'] as List<dynamic>? ?? [])
          .map((lesson) => Lesson.fromMap(lesson))
          .toList(),
      isPublished: data['isPublished'] ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      difficulty: data['difficulty'] ?? 'beginner',
      imageUrl: data['image_url'] ?? '',
    );
  }
}

class Lesson {
  final String title;
  final int duration;
  final String videoUrl;
  final String description;
  
  Lesson({
    required this.title,
    required this.duration,
    required this.videoUrl,
    required this.description,
  });
  
  factory Lesson.fromMap(Map<String, dynamic> map) {
    return Lesson(
      title: map['title'] ?? '',
      duration: map['duration'] ?? 0,
      videoUrl: map['video_url'] ?? '',
      description: map['description'] ?? '',
    );
  }
}
```

**Real-time Data Synchronization**:
```dart
// lib/repositories/course_repository.dart
class CourseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Real-time course list stream
  Stream<List<Course>> getCoursesStream({
    String? category,
    String? difficulty,
    String? searchQuery,
  }) {
    Query query = _firestore
        .collection('courses')
        .where('isPublished', isEqualTo: true);
    
    // Apply filters
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    
    if (difficulty != null && difficulty.isNotEmpty) {
      query = query.where('difficulty', isEqualTo: difficulty);
    }
    
    // Order by rating
    query = query.orderBy('rating', descending: true);
    
    return query.snapshots().map((snapshot) {
      List<Course> courses = snapshot.docs
          .map((doc) => Course.fromFirestore(doc))
          .toList();
      
      // Apply search filter locally
      if (searchQuery != null && searchQuery.isNotEmpty) {
        courses = courses.where((course) {
          return course.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
                 course.instructor.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }
      
      return courses;
    });
  }
  
  // Get specific course with real-time updates
  Stream<Course?> getCourseStream(String courseId) {
    return _firestore
        .collection('courses')
        .doc(courseId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return Course.fromFirestore(snapshot);
      }
      return null;
    });
  }
  
  // User's enrolled courses stream
  Stream<List<Course>> getUserEnrolledCoursesStream(String userId) {
    return _firestore
        .collection('enrollments')
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((enrollmentSnapshot) async {
      
      List<Course> courses = [];
      
      for (var enrollmentDoc in enrollmentSnapshot.docs) {
        String courseId = enrollmentDoc.data()['course_id'];
        
        DocumentSnapshot courseDoc = await _firestore
            .collection('courses')
            .doc(courseId)
            .get();
        
        if (courseDoc.exists) {
          courses.add(Course.fromFirestore(courseDoc));
        }
      }
      
      return courses;
    });
  }
}
```

**Enrollment Repository with Real-time Progress**:
```dart
// lib/repositories/enrollment_repository.dart
class EnrollmentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Enroll in course
  Future<bool> enrollInCourse(String userId, String courseId) async {
    try {
      // Check if already enrolled
      QuerySnapshot existingEnrollment = await _firestore
          .collection('enrollments')
          .where('user_id', isEqualTo: userId)
          .where('course_id', isEqualTo: courseId)
          .limit(1)
          .get();
      
      if (existingEnrollment.docs.isNotEmpty) {
        throw Exception('Already enrolled in this course');
      }
      
      // Create enrollment record
      await _firestore.collection('enrollments').add({
        'user_id': userId,
        'course_id': courseId,
        'enrolled_at': FieldValue.serverTimestamp(),
        'status': 'active',
        'progress': {
          'completed_lessons': [],
          'completion_percentage': 0.0,
          'total_time_spent': 0,
          'last_accessed': FieldValue.serverTimestamp(),
        }
      });
      
      // Update course student count
      await _firestore.collection('courses').doc(courseId).update({
        'students_count': FieldValue.increment(1)
      });
      
      // Update user enrollment count
      await _firestore.collection('users').doc(userId).update({
        'enrollment_count': FieldValue.increment(1)
      });
      
      return true;
    } catch (e) {
      print('Enrollment error: $e');
      return false;
    }
  }
  
  // Real-time enrollment progress stream
  Stream<EnrollmentProgress?> getEnrollmentProgressStream(String userId, String courseId) {
    return _firestore
        .collection('enrollments')
        .where('user_id', isEqualTo: userId)
        .where('course_id', isEqualTo: courseId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var data = snapshot.docs.first.data();
        return EnrollmentProgress.fromMap(data['progress'] ?? {});
      }
      return null;
    });
  }
  
  // Update lesson completion
  Future<void> updateLessonProgress(
    String userId, 
    String courseId, 
    String lessonId,
    int timeSpent
  ) async {
    try {
      QuerySnapshot enrollmentQuery = await _firestore
          .collection('enrollments')
          .where('user_id', isEqualTo: userId)
          .where('course_id', isEqualTo: courseId)
          .limit(1)
          .get();
      
      if (enrollmentQuery.docs.isNotEmpty) {
        String enrollmentId = enrollmentQuery.docs.first.id;
        
        await _firestore.collection('enrollments').doc(enrollmentId).update({
          'progress.completed_lessons': FieldValue.arrayUnion([lessonId]),
          'progress.total_time_spent': FieldValue.increment(timeSpent),
          'progress.last_accessed': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Progress update error: $e');
    }
  }
}

class EnrollmentProgress {
  final List<String> completedLessons;
  final double completionPercentage;
  final int totalTimeSpent;
  final DateTime? lastAccessed;
  
  EnrollmentProgress({
    required this.completedLessons,
    required this.completionPercentage,
    required this.totalTimeSpent,
    this.lastAccessed,
  });
  
  factory EnrollmentProgress.fromMap(Map<String, dynamic> map) {
    return EnrollmentProgress(
      completedLessons: List<String>.from(map['completed_lessons'] ?? []),
      completionPercentage: (map['completion_percentage'] ?? 0.0).toDouble(),
      totalTimeSpent: map['total_time_spent'] ?? 0,
      lastAccessed: map['last_accessed'] != null 
          ? (map['last_accessed'] as Timestamp).toDate()
          : null,
    );
  }
}
```

**UI Implementation with Real-time Streams**:
```dart
// lib/screens/courses_screen.dart
class CoursesScreen extends StatefulWidget {
  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final CourseRepository _courseRepository = CourseRepository();
  String? _selectedCategory;
  String? _selectedDifficulty;
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Courses'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Course list with real-time updates
          Expanded(
            child: StreamBuilder<List<Course>>(
              stream: _courseRepository.getCoursesStream(
                category: _selectedCategory,
                difficulty: _selectedDifficulty,
                searchQuery: _searchQuery,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error loading courses'),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No courses found'),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Course course = snapshot.data![index];
                    return CourseCard(
                      course: course,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseDetailScreen(courseId: course.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        selectedCategory: _selectedCategory,
        selectedDifficulty: _selectedDifficulty,
        onApplyFilters: (category, difficulty) {
          setState(() {
            _selectedCategory = category;
            _selectedDifficulty = difficulty;
          });
        },
      ),
    );
  }
}
```

**Key Implementation Features**:
- ✅ Real-time data synchronization across all components
- ✅ Offline data caching and automatic sync
- ✅ Complex queries with filtering and sorting
- ✅ Document relationship management
- ✅ Transaction support for data consistency
- ✅ Optimized performance with proper indexing
- ✅ Error handling and retry mechanisms

### **3. Firebase Cloud Functions Implementation**

**Main API Handler**:
```python
# functions/main.py
from firebase_functions import https_fn, options
from firebase_admin import initialize_app
from routes import auth, courses, enrollments, categories
import logging

# Initialize Firebase Admin SDK
initialize_app()

# Configure CORS for cross-origin requests
cors_options = options.CorsOptions(
    cors_origins=["*"],
    cors_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    cors_allow_headers=["Content-Type", "Authorization"]
)

@https_fn.on_request(cors=cors_options, memory=512, timeout_sec=60)
def api(req):
    """Main API entry point for all HTTP requests"""
    try:
        path = req.path
        method = req.method.upper()
        
        # Log request for monitoring
        logging.info(f"{method} {path} - User Agent: {req.headers.get('User-Agent', 'Unknown')}")
        
        # Handle preflight OPTIONS requests
        if method == 'OPTIONS':
            return ('', 204, {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
                'Access-Control-Max-Age': '3600'
            })
        
        # Route to appropriate handlers
        if path.startswith('/auth'):
            return auth.handle_auth_routes(req, path, method)
        elif path.startswith('/courses'):
            return courses.handle_course_routes(req, path, method)
        elif path.startswith('/enrollments'):
            return enrollments.handle_enrollment_routes(req, path, method)
        elif path.startswith('/categories'):
            return categories.handle_category_routes(req, path, method)
        else:
            return {'error': 'Route not found'}, 404
            
    except Exception as e:
        logging.error(f"API Error: {str(e)}")
        return {'error': f'Internal server error: {str(e)}'}, 500
```

**Authentication Routes**:
```python
# functions/routes/auth.py
from firebase_admin import auth, firestore
from firebase_functions import https_fn
import json
import logging

db = firestore.client()

def handle_auth_routes(req, path, method):
    """Handle all authentication-related routes"""
    
    if path == '/auth/register' and method == 'POST':
        return register_user(req)
    elif path == '/auth/profile' and method == 'GET':
        return get_user_profile(req)
    elif path == '/auth/profile' and method == 'PUT':
        return update_user_profile(req)
    else:
        return {'error': 'Auth route not found'}, 404

def register_user(req):
    """Register a new user with enhanced profile"""
    try:
        # Verify Firebase ID token
        token = extract_bearer_token(req)
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
        
        # Get request data
        data = req.get_json()
        if not data:
            return {'error': 'No data provided'}, 400
        
        # Validate required fields
        required_fields = ['email', 'display_name']
        for field in required_fields:
            if not data.get(field):
                return {'error': f'{field} is required'}, 400
        
        # Create user profile
        user_profile = {
            'uid': uid,
            'email': data['email'],
            'display_name': data['display_name'],
            'phone': data.get('phone', ''),
            'role': 'student',  # Default role
            'enrollment_count': 0,
            'created_at': firestore.SERVER_TIMESTAMP,
            'preferences': {
                'notifications': True,
                'theme': 'light',
                'language': 'en',
                'difficulty_preference': 'beginner'
            },
            'stats': {
                'courses_completed': 0,
                'total_learning_time': 0,
                'certificates_earned': 0,
                'lessons_completed': 0
            },
            'profile_completed': True
        }
        
        # Save to Firestore
        db.collection('users').document(uid).set(user_profile)
        
        logging.info(f"User registered successfully: {uid}")
        
        return {
            'success': True,
            'message': 'User registered successfully',
            'user': user_profile
        }
        
    except Exception as e:
        logging.error(f"Registration error: {str(e)}")
        return {'error': f'Registration failed: {str(e)}'}, 500

def get_user_profile(req):
    """Get user profile by UID"""
    try:
        token = extract_bearer_token(req)
        decoded_token = auth.verify_id_token(token)
        uid = decoded_token['uid']
        
        # Get user document
        user_doc = db.collection('users').document(uid).get()
        
        if not user_doc.exists:
            return {'error': 'User profile not found'}, 404
        