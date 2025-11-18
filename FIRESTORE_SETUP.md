# Firestore Security Rules Setup

## Important: Deploy Firestore Security Rules

The app requires Firestore security rules to be deployed. The rules file is located at `firestore.rules` in the project root.

### Steps to Deploy:

1. **Using Firebase Console:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Go to **Firestore Database** → **Rules** tab
   - Copy the contents of `firestore.rules` file
   - Paste into the rules editor
   - Click **Publish**

2. **Using Firebase CLI:**
   ```bash
   # Install Firebase CLI if not already installed
   npm install -g firebase-tools
   
   # Login to Firebase
   firebase login
   
   # Initialize Firebase (if not already done)
   firebase init firestore
   
   # Deploy rules
   firebase deploy --only firestore:rules
   ```

### What the Rules Do:

- **Read**: Any authenticated user can read reports
- **Create**: Only authenticated users can create reports (must match their userId)
- **Update**: Users can update their own reports, or update confirmations/fixed status on any report
- **Delete**: Users can only delete their own reports

### Testing:

After deploying, test by:
1. Creating a report (should work)
2. Viewing reports on the map (should work)
3. Confirming a report (should work)

If you see "Permission denied" errors, make sure:
- The rules are deployed correctly
- The user is authenticated
- The rules match your Firebase project structure

