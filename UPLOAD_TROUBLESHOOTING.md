# Image Upload Troubleshooting Guide

## Problem: Images show 404 error after upload

This means the app created a URL for the image, but the file doesn't exist on the server.

## Step 1: Verify Server Setup

1. **Check if the upload script exists:**
   - The script should be at: `https://akhele.com/api/upload.php`
   - Test by visiting it in a browser (should show an error about missing file, not 404)

2. **Check upload directory:**
   - Directory should exist: `/uploads/reports/` (relative to your web root)
   - Permissions should be: `chmod 755 uploads/reports`
   - The web server user (usually `www-data` or `apache`) needs write permissions

3. **Check PHP configuration:**
   - `upload_max_filesize` in `php.ini` should be at least 5MB
   - `post_max_size` should be at least 5MB
   - `file_uploads` should be `On`

## Step 2: Test the Upload Endpoint

You can test the endpoint using curl:

```bash
curl -X POST https://akhele.com/api/upload.php \
  -F "image=@/path/to/test-image.jpg" \
  -F "userId=test123" \
  -F "timestamp=1234567890"
```

Expected response:
```json
{
  "success": true,
  "filename": "test123_1234567890_abc123.jpg",
  "url": "https://akhele.com/uploads/reports/test123_1234567890_abc123.jpg",
  "path": "/uploads/reports/test123_1234567890_abc123.jpg"
}
```

## Step 3: Check App Logs

After the improved error handling, when you try to upload an image, check the Flutter logs for:
- `Upload response status: XXX`
- `Upload response body: ...`

These will tell you exactly what the server is returning.

## Step 4: Common Issues

### Issue: Server returns 404 for upload endpoint
**Solution:** The PHP script doesn't exist at that path. Upload `server_upload_example.php` to `/api/upload.php` on your server.

### Issue: Server returns 500 error
**Solution:** Check PHP error logs. Common causes:
- Upload directory doesn't exist or isn't writable
- PHP `upload_max_filesize` is too small
- File permissions are incorrect

### Issue: Server returns 200 but file doesn't exist
**Solution:** The script might be returning success but failing to save the file. Check:
- Directory permissions
- Disk space
- PHP error logs

### Issue: CORS errors
**Solution:** Make sure the PHP script includes CORS headers (already in the example):
```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');
```

## Step 5: Verify File Upload

After uploading, check if the file exists:
- Visit: `https://akhele.com/uploads/reports/` (if directory listing is enabled)
- Or try accessing the specific file URL directly

## Next Steps

1. Set up the PHP script on your server
2. Test the upload endpoint using curl
3. Try uploading from the app again
4. Check the Flutter logs for detailed error messages
5. Verify the file exists on the server

