<?php
/**
 * Example PHP upload script for Hofra app
 * Place this file on your server (e.g., in /api/upload.php)
 * 
 * Make sure to:
 * 1. Create the uploads directory: mkdir -p uploads/reports
 * 2. Set proper permissions: chmod 755 uploads/reports
 * 3. Configure max upload size in php.ini if needed
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Configuration
$uploadDir = __DIR__ . '/uploads/reports/';
$maxFileSize = 5 * 1024 * 1024; // 5MB
$allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];

// Create upload directory if it doesn't exist
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

// Check if file was uploaded
if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    echo json_encode(['error' => 'No file uploaded or upload error']);
    exit;
}

$file = $_FILES['image'];

// Validate file size
if ($file['size'] > $maxFileSize) {
    http_response_code(400);
    echo json_encode(['error' => 'File too large. Maximum size is 5MB']);
    exit;
}

// Validate file type
$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mimeType = finfo_file($finfo, $file['tmp_name']);
finfo_close($finfo);

if (!in_array($mimeType, $allowedTypes)) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid file type. Only JPEG, PNG, and WebP are allowed']);
    exit;
}

// Generate unique filename
$userId = $_POST['userId'] ?? 'anonymous';
$timestamp = $_POST['timestamp'] ?? time();
$extension = pathinfo($file['name'], PATHINFO_EXTENSION);
$filename = $userId . '_' . $timestamp . '_' . uniqid() . '.' . $extension;
$filepath = $uploadDir . $filename;

// Move uploaded file
if (move_uploaded_file($file['tmp_name'], $filepath)) {
    // Return success response
    // Option 1: Return full URL
    $baseUrl = (isset($_SERVER['HTTPS']) ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'];
    $url = $baseUrl . '/uploads/reports/' . $filename;
    
    echo json_encode([
        'success' => true,
        'filename' => $filename,
        'url' => $url,
        'path' => '/uploads/reports/' . $filename
    ]);
} else {
    http_response_code(500);
    echo json_encode(['error' => 'Failed to save file']);
}
?>

