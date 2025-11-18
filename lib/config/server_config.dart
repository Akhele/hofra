class ServerConfig {
  // TODO: Replace with your actual server URL
  // Example: 'https://yourdomain.com' or 'https://yourdomain.ifastnet.com'
  static const String baseUrl = 'https://yourdomain.com';
  
  // Image upload endpoint
  // This should be the path to your image upload script/API
  // Example: '/api/upload.php' or '/upload.php' or '/api/images/upload'
  static const String uploadEndpoint = '/api/upload.php';
  
  // Full upload URL
  static String get uploadUrl => '$baseUrl$uploadEndpoint';
  
  // Get image URL (for displaying uploaded images)
  // This should match how your server serves the uploaded images
  // Example: '/uploads/reports/' or '/images/reports/'
  static String getImageUrl(String filename) {
    return '$baseUrl/uploads/reports/$filename';
  }
}

