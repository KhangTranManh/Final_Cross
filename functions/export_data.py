#!/usr/bin/env python3
"""
Simple Firebase Firestore Data Export Script
Usage: python export_data.py
"""

import os
import sys
import json
from datetime import datetime
from pathlib import Path

# Add UTF-8 encoding support
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
if sys.stderr.encoding != 'utf-8':
    sys.stderr.reconfigure(encoding='utf-8')
os.environ['PYTHONIOENCODING'] = 'utf-8'

# Import Firebase Admin
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
except ImportError:
    print("✗ Error: firebase-admin package not installed")
    print("  Run: pip install firebase-admin")
    sys.exit(1)


def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    if not firebase_admin._apps:
        try:
            current_dir = os.path.dirname(os.path.abspath(__file__))
            service_account_path = os.path.join(current_dir, "config", "firebase-service-account.json")
            
            if os.path.exists(service_account_path):
                cred = credentials.Certificate(service_account_path)
                firebase_admin.initialize_app(cred)
                print("✓ Firebase initialized with service account")
                return True
            else:
                print("\n" + "=" * 60)
                print("  ✗ ERROR: Firebase Service Account Not Found")
                print("=" * 60)
                print("\nThe service account file is missing:")
                print(f"  Expected location: {service_account_path}")
                print("\nTo fix this:")
                print("  1. Go to Firebase Console")
                print("  2. Project Settings > Service Accounts")
                print("  3. Click 'Generate New Private Key'")
                print("  4. Save the file as 'firebase-service-account.json'")
                print("  5. Place it in the 'config' folder")
                print("\nAlternatively, you can:")
                print("  - Create the config folder if it doesn't exist")
                print("  - Copy your existing service account file there")
                print("=" * 60)
                return False
        except Exception as e:
            print(f"\n✗ Firebase initialization error: {e}")
            return False
    return True


def convert_to_serializable(data):
    """Convert Firestore data to JSON serializable format"""
    if isinstance(data, dict):
        return {k: convert_to_serializable(v) for k, v in data.items()}
    elif isinstance(data, list):
        return [convert_to_serializable(item) for item in data]
    elif isinstance(data, datetime):
        return data.strftime("%a, %d %b %Y %H:%M:%S GMT")
    else:
        return data


def export_collection(db, collection_name, output_dir):
    """Export a Firestore collection to JSON file"""
    print(f"\n📁 Exporting {collection_name}...")
    try:
        # Get all documents from collection
        docs = db.collection(collection_name).stream()
        
        data_list = []
        for doc in docs:
            doc_data = doc.to_dict()
            doc_data['id'] = doc.id
            doc_data = convert_to_serializable(doc_data)
            data_list.append(doc_data)
        
        # Create result in API format
        result = {
            "success": True,
            "count": len(data_list),
            "data": data_list
        }
        
        # Save to file
        output_file = os.path.join(output_dir, f"{collection_name}.json")
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        
        print(f"  ✓ Exported {len(data_list)} documents")
        return len(data_list)
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return 0


def export_enrollments_with_courses(db, output_dir):
    """Export enrollments with course details (like original export)"""
    print(f"\n🎓 Exporting enrollments with course details...")
    try:
        # Get all enrollments
        enrollments_docs = db.collection('enrollments').stream()
        
        data_list = []
        for doc in enrollments_docs:
            enrollment_data = doc.to_dict()
            enrollment_data['enrollment_id'] = doc.id
            
            # Get course details for this enrollment
            course_id = enrollment_data.get('course_id')
            if course_id:
                course_doc = db.collection('courses').document(course_id).get()
                if course_doc.exists:
                    course_data = course_doc.to_dict()
                    course_data['id'] = course_doc.id
                    enrollment_data['course'] = convert_to_serializable(course_data)
                else:
                    enrollment_data['course'] = None
            else:
                enrollment_data['course'] = None
            
            # Convert to serializable
            enrollment_data = convert_to_serializable(enrollment_data)
            data_list.append(enrollment_data)
        
        # Create result in API format
        result = {
            "success": True,
            "count": len(data_list),
            "data": data_list
        }
        
        # Save to file
        output_file = os.path.join(output_dir, "enrollments.json")
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(result, f, indent=2, ensure_ascii=False)
        
        print(f"  ✓ Exported {len(data_list)} enrollments with course details")
        return len(data_list)
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return 0


def create_summary(output_dir, collections_exported, total_documents):
    """Create export summary file"""
    print("\n📋 Creating summary...")
    
    summary = {
        "export_timestamp": datetime.now().isoformat(),
        "export_method": "Direct Firestore Export",
        "output_directory": os.path.basename(output_dir),
        "total_collections": len(collections_exported),
        "successful_exports": len([c for c in collections_exported.values() if c > 0]),
        "total_documents": total_documents,
        "collections_exported": list(collections_exported.keys())
    }
    
    # Save summary
    summary_file = os.path.join(output_dir, "summary.json")
    with open(summary_file, 'w', encoding='utf-8') as f:
        json.dump(summary, f, indent=2, ensure_ascii=False)
    
    print(f"  ✓ Summary created")
    return summary


def main():
    """Main export function"""
    print("=" * 60)
    print("  FIREBASE FIRESTORE DATA EXPORT")
    print("=" * 60)
    
    # Initialize Firebase
    if not initialize_firebase():
        print("\n✗ Failed to initialize Firebase. Exiting.")
        return
    
    # Get Firestore client
    db = firestore.client()
    
    # Create output directory with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = f"data_export_{timestamp}"
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_path = os.path.join(script_dir, output_dir)
    
    Path(output_path).mkdir(parents=True, exist_ok=True)
    print(f"\n📂 Output directory: {output_dir}/")
    
    # Export collections
    collections_exported = {}
    
    # Export simple collections
    collections_exported['categories'] = export_collection(db, 'categories', output_path)
    collections_exported['courses'] = export_collection(db, 'courses', output_path)
    collections_exported['users'] = export_collection(db, 'users', output_path)
    
    # Export enrollments with course details
    collections_exported['enrollments'] = export_enrollments_with_courses(db, output_path)
    
    # Calculate totals
    total_documents = sum(collections_exported.values())
    
    # Create summary
    summary = create_summary(output_path, collections_exported, total_documents)
    
    # Print results
    print("\n" + "=" * 60)
    print("  EXPORT COMPLETE")
    print("=" * 60)
    print(f"\n📊 Summary:")
    print(f"  • Total Collections: {summary['total_collections']}")
    print(f"  • Successful Exports: {summary['successful_exports']}")
    print(f"  • Total Documents: {summary['total_documents']}")
    print(f"\n📁 Files created in: {output_dir}/")
    for collection, count in collections_exported.items():
        status = "✓" if count > 0 else "✗"
        print(f"  {status} {collection}.json ({count} documents)")
    print(f"  ✓ summary.json")
    print("\n" + "=" * 60)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n✗ Export cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n✗ Export failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

