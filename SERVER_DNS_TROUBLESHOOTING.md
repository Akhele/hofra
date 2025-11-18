# Server DNS Troubleshooting Guide

## Problem: "Failed host lookup: 'akhele.com'"

The app cannot resolve the domain name `akhele.com`. This means either:
1. The domain doesn't exist or isn't configured
2. The server is down
3. There's a DNS configuration issue
4. The domain name in the app is incorrect

## Step 1: Verify Your Domain

1. **Check if the domain exists:**
   - Open a web browser and visit: `https://akhele.com`
   - If it doesn't load, the domain may not be configured or the server is down

2. **Check DNS resolution:**
   - On your computer, run: `ping akhele.com` or `nslookup akhele.com`
   - If it fails, the domain isn't resolving

## Step 2: Verify Server Configuration

### If using ifastnet hosting:

1. **Check your actual domain:**
   - Log into your ifastnet control panel
   - Find your actual domain name (it might be something like `yourdomain.ifastnet.com` or a custom domain)
   - The domain might be different from `akhele.com`

2. **Update the app configuration:**
   - Open `lib/config/server_config.dart`
   - Update `baseUrl` to match your actual server domain:
     ```dart
     static const String baseUrl = 'https://your-actual-domain.com';
     ```

## Step 3: Verify Upload Endpoint

1. **Check if the upload script exists:**
   - Visit: `https://your-domain.com/api/upload.php` in a browser
   - You should see an error about missing file (not 404)
   - If you see 404, the file doesn't exist at that path

2. **Verify the file path:**
   - The upload script should be at: `/api/upload.php` (relative to your web root)
   - Or adjust the path in `lib/config/server_config.dart`:
     ```dart
     static const String uploadEndpoint = '/your/path/to/upload.php';
     ```

## Step 4: Test Server Setup

### Test 1: Upload Script Exists
```bash
curl -I https://your-domain.com/api/upload.php
```
Should return HTTP 200 or 405 (method not allowed), not 404.

### Test 2: Upload Directory Exists
```bash
# SSH into your server and check:
ls -la uploads/reports/
```
The directory should exist and be writable.

### Test 3: Test Upload Manually
```bash
curl -X POST https://your-domain.com/api/upload.php \
  -F "image=@/path/to/test-image.jpg" \
  -F "userId=test123" \
  -F "timestamp=1234567890"
```

Should return JSON with `success: true` and a URL.

## Step 5: Common Issues

### Issue 1: Domain Not Configured
**Solution:** Make sure your domain is properly configured in your hosting control panel.

### Issue 2: Wrong Domain Name
**Solution:** Update `lib/config/server_config.dart` with the correct domain.

### Issue 3: Upload Script Not Uploaded
**Solution:** Upload `server_upload_example.php` to your server at `/api/upload.php`

### Issue 4: Directory Permissions
**Solution:** Set correct permissions:
```bash
mkdir -p uploads/reports
chmod 755 uploads/reports
chown www-data:www-data uploads/reports  # Adjust user/group as needed
```

### Issue 5: PHP Configuration
**Solution:** Check `php.ini`:
- `upload_max_filesize = 5M`
- `post_max_size = 5M`
- `file_uploads = On`

## Step 6: Update App Configuration

Once you've verified your server setup, update the app:

1. **Update server URL:**
   ```dart
   // lib/config/server_config.dart
   static const String baseUrl = 'https://your-actual-domain.com';
   ```

2. **Update upload endpoint (if different):**
   ```dart
   static const String uploadEndpoint = '/api/upload.php';
   ```

3. **Update image URL path (if different):**
   ```dart
   static String getImageUrl(String filename) {
     return '$baseUrl/uploads/reports/$filename';
   }
   ```

4. **Hot restart the app** to apply changes.

## Still Having Issues?

1. Check server error logs (usually in `/var/log/apache2/error.log` or similar)
2. Verify PHP is working: Create a test file `test.php` with `<?php phpinfo(); ?>` and visit it
3. Check firewall settings - port 443 (HTTPS) should be open
4. Verify SSL certificate is valid (if using HTTPS)

