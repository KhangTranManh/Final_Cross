# Final Cross - E-Learning Platform

A complete Flutter e-learning platform with Firebase backend integration.

## Quick Start

### Prerequisites
- Flutter SDK 3.9.0+
- Python 3.11+
- Firebase CLI
- Node.js (for Firebase tools)

### 1. Clone & Setup
```bash
git clone <https://github.com/KhangTranManh/Final_Cross>
cd Final_Cross
```

### 2. Flutter App Setup
```bash
cd final_cross
flutter pub get
flutter run
```

## Firebase Setup

### Install CLI tools (once per machine)
```bash
# Install Firebase CLI
npm install -g firebase-tools
firebase login

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Ensure FlutterFire is on PATH
# Windows:
setx PATH "%PATH%;%APPDATA%\Pub\Cache\bin"
# macOS/Linux (add to shell rc):
export PATH="$HOME/.pub-cache/bin:$PATH"
```

### Configure this project
```bash
# Select Firebase project
firebase use <your-project-id>

# Generate Flutter config (creates/updates final_cross/lib/firebase_options.dart)
flutterfire configure --project=<your-project-id> --platforms=android,ios,web,windows,macos
```

### Platform configuration files
- Android: place `google-services.json` in `final_cross/android/app/`
- iOS: place `GoogleService-Info.plist` in `final_cross/ios/Runner/`
- Web is handled via `firebase_options.dart` by FlutterFire


### 3. Backend Setup
```bash
cd functions

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Start Firebase emulators
firebase emulators:start
```



## Architecture

### Frontend (Flutter)
- **Authentication**: Firebase Auth with JWT tokens
- **State Management**: Riverpod + StreamBuilder
- **UI**: Material Design 3
- **Real-time**: Firestore listeners

### Backend (Python)
- **Cloud Functions**: Serverless API endpoints
- **Database**: Cloud Firestore (NoSQL)
- **Authentication**: Firebase Admin SDK
- **Architecture**: MVC pattern with Flask

## Development

### Local Development
```bash
# Activate virtual environment first
cd functions
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Start emulators
firebase emulators:start

# In another terminal, run Flutter app
cd final_cross
flutter run



### Add Sample Data
```bash
cd functions

# Activate virtual environment
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Run seed script
python seed_courses.py  # Add more courses
```

## Tech Stack

### Frontend
- Flutter 3.9.0
- Dart
- Firebase Auth
- Riverpod
- Material Design 3

### Backend
- Python 3.11
- Firebase Cloud Functions
- Cloud Firestore
- Flask
- Firebase Admin SDK

## Demo Flow

1. **Register/Login** → Firebase Auth
2. **Browse Courses** → Firestore real-time data
3. **Enroll in Course** → Cloud Function + Firestore
4. **Track Progress** → Real-time updates


## Deployment

### Flutter App
```bash
flutter build web
# Deploy to Firebase Hosting
```

### Backend
```bash
# Activate virtual environment first
cd functions
# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate

# Deploy functions
firebase deploy --only functions
```

## Troubleshooting

### Virtual Environment Issues
```bash
# If venv activation fails on Windows:
# Make sure you're in the functions directory
cd functions

# Create venv if it doesn't exist
python -m venv venv

# Try different activation methods:
venv\Scripts\activate.bat
# OR
venv\Scripts\activate
# OR
.\venv\Scripts\Activate.ps1
```

### Firebase Emulator Issues
```bash
# If emulator fails to start:
# Make sure virtual environment is activated
# Check if port 5001 is available
# Try running with specific emulators:
firebase emulators:start --only functions,firestore
```

### Python Dependencies
```bash
# If pip install fails:
# Upgrade pip first
python -m pip install --upgrade pip

# Then install requirements
pip install -r requirements.txt
```
