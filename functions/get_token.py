#!/usr/bin/env python3
"""
Get Firebase Authentication Token
Usage: python get_token.py
"""

import os
import sys
import json

# Add UTF-8 encoding support
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
if sys.stderr.encoding != 'utf-8':
    sys.stderr.reconfigure(encoding='utf-8')
os.environ['PYTHONIOENCODING'] = 'utf-8'

try:
    import firebase_admin
    from firebase_admin import credentials, auth
    import requests
except ImportError:
    print("✗ Error: Required packages not installed")
    print("  Run: pip install firebase-admin requests")
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
                return True
            else:
                print("\n✗ ERROR: Firebase service account file not found")
                print(f"  Expected: {service_account_path}")
                return False
        except Exception as e:
            print(f"\n✗ Firebase initialization error: {e}")
            return False
    return True


def get_firebase_api_key():
    """Get Firebase API key"""
    return "AIzaSyAOxhBRPl1PmE4zTT1McNH6ONwbtqKoK2Y"


def sign_in_with_email_password(email, password):
    """Sign in with email and password to get ID token"""
    try:
        api_key = get_firebase_api_key()
        url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={api_key}"
        
        payload = {
            "email": email,
            "password": password,
            "returnSecureToken": True
        }
        
        response = requests.post(url, json=payload)
        
        if response.status_code == 200:
            data = response.json()
            return {
                'idToken': data.get('idToken'),
                'refreshToken': data.get('refreshToken'),
                'expiresIn': data.get('expiresIn'),
                'localId': data.get('localId'),
                'email': data.get('email')
            }
        else:
            error_data = response.json()
            error_msg = error_data.get('error', {}).get('message', 'Unknown error')
            print(f"✗ Authentication failed: {error_msg}")
            return None
            
    except Exception as e:
        print(f"✗ Error signing in: {e}")
        return None


def get_user_by_email(email):
    """Get user by email"""
    try:
        user = auth.get_user_by_email(email)
        return user
    except Exception as e:
        print(f"✗ Error getting user: {e}")
        return None


def list_users():
    """List all users"""
    try:
        page = auth.list_users()
        users = []
        for user in page.users:
            users.append({
                'uid': user.uid,
                'email': user.email,
                'display_name': user.display_name or 'N/A'
            })
        return users
    except Exception as e:
        print(f"✗ Error listing users: {e}")
        return []


def main():
    """Main function"""
    print("=" * 60)
    print("  FIREBASE AUTHENTICATION TOKEN GENERATOR")
    print("=" * 60)
    
    # Initialize Firebase
    if not initialize_firebase():
        print("\n✗ Failed to initialize Firebase. Exiting.")
        return
    
    print("\nOptions:")
    print("  1. Sign in with Email & Password (Get ID Token)")
    print("  2. List all users")
    print("  0. Exit")
    
    choice = input("\nSelect option: ").strip()
    
    if choice == '1':
        email = input("\nEnter Email: ").strip()
        password = input("Enter Password: ").strip()
        
        if email and password:
            print(f"\n🔑 Signing in as {email}...")
            
            result = sign_in_with_email_password(email, password)
            if result:
                print("\n" + "=" * 60)
                print("  ✅ AUTHENTICATION SUCCESSFUL")
                print("=" * 60)
                print(f"\nUser ID: {result['localId']}")
                print(f"Email: {result['email']}")
                print(f"Token expires in: {result['expiresIn']} seconds (1 hour)")
                
                print("\n" + "=" * 60)
                print("  🎫 ID TOKEN FOR POSTMAN")
                print("=" * 60)
                print(f"\n{result['idToken']}\n")
                print("=" * 60)
                
                print("\n📋 How to use in Postman:")
                print("  1. Copy the token above")
                print("  2. Open Postman collection 'Final Cross - E-Learning API'")
                print("  3. Click on collection name → Variables tab")
                print("  4. Paste token in 'auth_token' Current Value field")
                print("  5. Click Save (Ctrl+S)")
                print("  6. Test your API requests!")
                print("\n⏱️  Token expires in 1 hour - generate new token if expired")
                print("=" * 60)
        else:
            print("\n✗ Email and password are required")
    
    elif choice == '2':
        print("\n👥 Listing all users...")
        users = list_users()
        if users:
            print("\n" + "=" * 60)
            print(f"  TOTAL USERS: {len(users)}")
            print("=" * 60)
            for i, user in enumerate(users, 1):
                print(f"\n{i}. Email: {user['email']}")
                print(f"   UID: {user['uid']}")
                print(f"   Name: {user['display_name']}")
        else:
            print("\n✗ No users found")
    
    elif choice == '0':
        print("\n👋 Goodbye!")
    
    else:
        print("\n✗ Invalid option")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n✗ Cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

