# Server Setup Guide for Image Uploads

This guide explains how to set up your server to handle image uploads from the Hofra app.

## Server Requirements

- PHP 7.0+ (or Node.js, Python, etc. - adjust script accordingly)
- Web server (Apache, Nginx, etc.)
- Write permissions for upload directory
- At least 5MB max upload size configured

## Quick Setup (PHP)

1. **Upload the PHP script** (`server_upload_example.php`) to your server
   - Recommended location: `/api/upload.php` or `/upload.php`
   - Make sure it's accessible via HTTP/HTTPS

2. **Create upload directory**
   ```bash
   mkdir -p uploads/reports
   chmod 755 uploads/reports
   ```

3. **Configure PHP settings** (if needed)
   - Edit `php.ini`:
     ```ini
     upload_max_filesize = 5M
     post_max_size = 10M
     max_execution_time = 300
     ```

4. **Update app configuration**
   - Edit `lib/config/server_config.dart`
   - Set `baseUrl` to your domain (e.g., `https://yourdomain.com`)
   - Set `uploadEndpoint` to your upload script path (e.g., `/api/upload.php`)

## Configuration in App

Edit `lib/config/server_config.dart`:

```dart
class ServerConfig {
  // Your server domain
  static const String baseUrl = 'https://yourdomain.com';
  
  // Path to your upload endpoint
  static const String uploadEndpoint = '/api/upload.php';
  
  // Path where images are served (for building image URLs)
  static String getImageUrl(String filename) {
    return '$baseUrl/uploads/reports/$filename';
  }
}
```

## Server Response Format

Your server should return JSON in one of these formats:

**Option 1: Full URL**
```json
{
  "success": true,
  "url": "https://yourdomain.com/uploads/reports/filename.jpg"
}
```

**Option 2: Filename only**
```json
{
  "success": true,
  "filename": "filename.jpg"
}
```

**Option 3: Path only**
```json
{
  "success": true,
  "path": "/uploads/reports/filename.jpg"
}
```

The app will handle all these formats automatically.

## Security Considerations

1. **Authentication**: Consider adding authentication headers
   - Uncomment the authorization line in `image_upload_service.dart`
   - Add token validation in your server script

2. **File validation**: The example script validates:
   - File size (max 5MB)
   - File type (JPEG, PNG, WebP)
   - Prevents directory traversal attacks

3. **Rate limiting**: Consider adding rate limiting to prevent abuse

4. **HTTPS**: Always use HTTPS for production

## Alternative Server Implementations

### Node.js/Express Example

```javascript
const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
const upload = multer({
  dest: 'uploads/reports/',
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|webp/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new Error('Invalid file type'));
  }
});

app.post('/api/upload.php', upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }
  
  const filename = req.file.filename;
  const url = `https://yourdomain.com/uploads/reports/${filename}`;
  
  res.json({
    success: true,
    filename: filename,
    url: url
  });
});
```

### Python/Flask Example

```python
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import os

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 5 * 1024 * 1024  # 5MB
UPLOAD_FOLDER = 'uploads/reports'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/api/upload.php', methods=['POST'])
def upload_file():
    if 'image' not in request.files:
        return jsonify({'error': 'No file uploaded'}), 400
    
    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400
    
    if file and allowed_file(file.filename):
        filename = secure_filename(file.filename)
        filepath = os.path.join(UPLOAD_FOLDER, filename)
        file.save(filepath)
        
        return jsonify({
            'success': True,
            'filename': filename,
            'url': f'https://yourdomain.com/uploads/reports/{filename}'
        })
    
    return jsonify({'error': 'Invalid file type'}), 400
```

## Testing

1. Test the upload endpoint directly:
   ```bash
   curl -X POST -F "image=@test.jpg" https://yourdomain.com/api/upload.php
   ```

2. Test from the app:
   - Try uploading an image when creating a report
   - Check that the image URL is saved correctly in Firestore
   - Verify the image displays correctly in the app

## Troubleshooting

- **403 Forbidden**: Check directory permissions
- **413 Payload Too Large**: Increase `upload_max_filesize` in PHP
- **CORS errors**: Add CORS headers (already included in example)
- **Images not displaying**: Check that the upload directory is web-accessible

