# 🔥 Deploy Firestore Security Rules - REQUIRED

## ⚠️ IMPORTANT: Your app will NOT work until you deploy these rules!

The errors you're seeing (`PERMISSION_DENIED`) are because Firestore security rules haven't been deployed yet.

## Quick Fix (Choose ONE method):

### Method 1: Firebase Console (Easiest - No CLI needed)

1. **Go to Firebase Console:**
   - Open: https://console.firebase.google.com/
   - Select your project

2. **Navigate to Firestore Rules:**
   - Click **Firestore Database** in the left menu
   - Click the **Rules** tab at the top

3. **Copy and Paste Rules:**
   - Open the file `firestore.rules` in this project
   - Copy ALL the contents
   - Paste into the Firebase Console rules editor
   - Click **Publish** button

4. **Done!** Your app should now work.

---

### Method 2: Firebase CLI (For developers)

1. **Install Firebase CLI** (if not installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase:**
   ```bash
   firebase login
   ```

3. **Initialize Firebase** (if not already done):
   ```bash
   firebase init firestore
   ```
   - When asked, select your existing project
   - Use the existing `firestore.rules` file (don't overwrite)

4. **Deploy Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Done!** Your app should now work.

---

## Verify Deployment:

After deploying, test your app:
1. ✅ Create a new account
2. ✅ Submit a report with images
3. ✅ View reports on the map

If you still see permission errors:
- Wait 1-2 minutes for rules to propagate
- Make sure you're logged in
- Check Firebase Console → Firestore → Rules to confirm they're published

---

## What These Rules Do:

- ✅ **Read**: Authenticated users can view all reports
- ✅ **Create**: Authenticated users can create reports (must match their userId)
- ✅ **Update**: Users can update their own reports or confirm/fix any report
- ✅ **Delete**: Users can only delete their own reports

---

## Need Help?

If you're still having issues:
1. Check Firebase Console → Firestore → Rules to see if rules are published
2. Check Firebase Console → Authentication to ensure users are authenticated
3. Check the app logs for specific error messages

