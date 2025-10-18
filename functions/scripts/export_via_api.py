#!/usr/bin/env python3
"""
Export Data via API
Uses your existing Cloud Functions API to export data
"""

import json
import requests
import os
from datetime import datetime

def export_via_api():
    """Export data using your existing API endpoints"""
    
    # API configuration
    base_url = "http://127.0.0.1:5001/elearning-5ac35/us-central1/api"
    
    print("Exporting data via API")
    print("=" * 40)
    
    # Create output directory
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_dir = f"api_export_{timestamp}"
    os.makedirs(output_dir, exist_ok=True)
    
    print(f"Exporting to: {output_dir}")
    
    # Test API connection
    try:
        health_response = requests.get(f"{base_url}/health", timeout=10)
        if health_response.status_code == 200:
            print("API is running")
        else:
            print("API health check failed")
    except Exception as e:
        print(f"Cannot connect to API: {e}")
        print("Make sure Firebase emulator is running:")
        print("   firebase emulators:start --only functions")
        return
    
    # Define all available endpoints
    endpoints = {
        'courses': '/courses',
        'categories': '/categories', 
        'enrollments': '/enrollments',  # Requires authentication
        'auth': '/auth/profile'  # Requires authentication
    }
    
    # Public endpoints (no authentication required)
    public_endpoints = {
        'courses': '/courses',
        'categories': '/categories',
        'enrollments': '/enrollments/all'  # Public endpoint for all enrollments
    }
    
    total_documents = 0
    successful_exports = 0
    
    # Export public collections first
    print("\nExporting public collections...")
    for collection_name, endpoint in public_endpoints.items():
        try:
            print(f"\nExporting {collection_name}...")
            response = requests.get(f"{base_url}{endpoint}", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                
                # Save data to JSON file
                file_path = os.path.join(output_dir, f"{collection_name}.json")
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                
                print(f"Exported {collection_name} to {file_path}")
                
                # Count documents
                doc_count = 0
                if isinstance(data, dict):
                    if 'data' in data and isinstance(data['data'], list):
                        doc_count = len(data['data'])
                    elif 'success' in data and data.get('success') and 'data' in data:
                        if isinstance(data['data'], list):
                            doc_count = len(data['data'])
                        else:
                            doc_count = 1
                elif isinstance(data, list):
                    doc_count = len(data)
                
                print(f"   Found {doc_count} documents")
                total_documents += doc_count
                successful_exports += 1
                
            else:
                print(f"Failed to export {collection_name}: {response.status_code}")
                
        except Exception as e:
            print(f"Error exporting {collection_name}: {e}")
    
    # Try authenticated endpoints (will likely fail without auth)
    print("\nAttempting authenticated collections...")
    auth_required = ['auth']  # Only auth profile requires authentication now
    
    for collection_name in auth_required:
        try:
            print(f"\nAttempting {collection_name}...")
            response = requests.get(f"{base_url}{endpoints[collection_name]}", timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                
                # Save data to JSON file
                file_path = os.path.join(output_dir, f"{collection_name}.json")
                with open(file_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
                
                print(f"Exported {collection_name} to {file_path}")
                
                # Count documents
                doc_count = 0
                if isinstance(data, dict):
                    if 'data' in data and isinstance(data['data'], list):
                        doc_count = len(data['data'])
                    elif 'success' in data and data.get('success') and 'data' in data:
                        if isinstance(data['data'], list):
                            doc_count = len(data['data'])
                        else:
                            doc_count = 1
                    elif collection_name == 'auth' and 'user' in data:
                        doc_count = 1
                elif isinstance(data, list):
                    doc_count = len(data)
                
                print(f"   Found {doc_count} documents")
                total_documents += doc_count
                successful_exports += 1
                
            elif response.status_code == 401:
                print(f"{collection_name} requires authentication (skipping)")
            else:
                print(f"Failed to export {collection_name}: {response.status_code}")
                
        except Exception as e:
            print(f"Error exporting {collection_name}: {e}")
    
    # Create summary
    summary = {
        "export_timestamp": datetime.now().isoformat(),
        "export_method": "API",
        "api_url": base_url,
        "output_directory": output_dir,
        "total_collections": len(endpoints),
        "successful_exports": successful_exports,
        "total_documents": total_documents,
        "collections_exported": list(endpoints.keys())
    }
    
    summary_file = os.path.join(output_dir, "summary.json")
    with open(summary_file, 'w', encoding='utf-8') as f:
        json.dump(summary, f, indent=2)
    
    print(f"\nExport complete!")
    print(f"Summary:")
    print(f"   Collections processed: {successful_exports}/{len(endpoints)}")
    print(f"   Total documents exported: {total_documents}")
    print(f"   Output directory: {output_dir}")
    print()
    print("Exported files:")
    for file in os.listdir(output_dir):
        file_path = os.path.join(output_dir, file)
        if os.path.isfile(file_path):
            size = os.path.getsize(file_path)
            print(f"   {file} ({size:,} bytes)")

if __name__ == "__main__":
    export_via_api()
