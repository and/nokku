package com.safegallery

import android.app.Activity
import android.app.KeyguardManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.view.View
import android.view.WindowManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val LOCK_CHANNEL = "com.safegallery/lock"
    private val INTENT_CHANNEL = "com.safegallery/intent"
    private val PERMISSION_REQUEST_CODE = 1001
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var componentName: ComponentName
    private var sharedFiles: List<String> = emptyList()
    private var hasSharedContent: Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        componentName = ComponentName(this, DeviceAdminReceiver::class.java)

        // Handle lock functionality
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LOCK_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPresentationMode" -> {
                    enterPresentationMode()
                    result.success(null)
                }
                "exitPresentationMode" -> {
                    exitPresentationMode()
                    result.success(null)
                }
                "lockDevice" -> {
                    val locked = lockDevice()
                    result.success(locked)
                }
                "isDeviceAdminEnabled" -> {
                    val isEnabled = devicePolicyManager.isAdminActive(componentName)
                    result.success(isEnabled)
                }
                "requestDeviceAdmin" -> {
                    requestDeviceAdmin()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Handle intent functionality
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, INTENT_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSharedFiles" -> {
                    result.success(sharedFiles)
                }
                "hasSharedContent" -> {
                    result.success(hasSharedContent)
                }
                "clearSharedContent" -> {
                    sharedFiles = emptyList()
                    hasSharedContent = false
                    result.success(null)
                }
                "requestStoragePermission" -> {
                    requestStoragePermission()
                    result.success(null)
                }
                "hasStoragePermission" -> {
                    val hasPermission = hasStoragePermission()
                    result.success(hasPermission)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Process initial intent
        processIntent(intent)
    }

    private fun hasStoragePermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ requires specific media permissions
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_MEDIA_IMAGES) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_MEDIA_VIDEO) == PackageManager.PERMISSION_GRANTED
        } else {
            // Older Android versions use READ_EXTERNAL_STORAGE
            ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestStoragePermission() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                android.Manifest.permission.READ_MEDIA_IMAGES,
                android.Manifest.permission.READ_MEDIA_VIDEO
            )
        } else {
            arrayOf(android.Manifest.permission.READ_EXTERNAL_STORAGE)
        }
        
        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            android.util.Log.d("MainActivity", "Permission result: ${grantResults.contentToString()}")
            // Re-process intent if permissions were granted
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                processIntent(intent)
            }
        }
    }

    private fun enterPresentationMode() {
        activity?.runOnUiThread {
            // Enable immersive mode
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.setDecorFitsSystemWindows(false)
                window.insetsController?.let { controller ->
                    controller.hide(android.view.WindowInsets.Type.statusBars() or android.view.WindowInsets.Type.navigationBars())
                    controller.systemBarsBehavior = android.view.WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
                }
            } else {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = (
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_FULLSCREEN
                )
            }

            // Keep screen on during presentation
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun exitPresentationMode() {
        activity?.runOnUiThread {
            // Exit immersive mode
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                window.setDecorFitsSystemWindows(true)
                window.insetsController?.show(android.view.WindowInsets.Type.statusBars() or android.view.WindowInsets.Type.navigationBars())
            } else {
                @Suppress("DEPRECATION")
                window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_VISIBLE
            }

            // Allow screen to turn off
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    private fun lockDevice(): Boolean {
        return if (devicePolicyManager.isAdminActive(componentName)) {
            devicePolicyManager.lockNow()
            true
        } else {
            // Fallback: Try to lock using KeyguardManager (works on some devices)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                keyguardManager.requestDismissKeyguard(this, null)
            }
            false
        }
    }

    private fun requestDeviceAdmin() {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componentName)
        intent.putExtra(
            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
            "Safe Gallery needs device admin permission to lock your device when exiting presentation mode."
        )
        startActivityForResult(intent, 1)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        processIntent(intent)
    }

    private fun processIntent(intent: Intent?) {
        if (intent == null) return

        android.util.Log.d("MainActivity", "Processing intent: ${intent.action}, type: ${intent.type}")

        when (intent.action) {
            Intent.ACTION_SEND -> {
                // Accept any media type or null type, we'll validate the actual files later
                val mediaUri = intent.getParcelableExtra<android.net.Uri>(Intent.EXTRA_STREAM)
                mediaUri?.let { uri ->
                    android.util.Log.d("MainActivity", "Single media URI: $uri")
                    val path = getRealPathFromUri(uri)
                    if (path != null && isMediaFile(path)) {
                        android.util.Log.d("MainActivity", "Valid media file: $path")
                        sharedFiles = listOf(path)
                        hasSharedContent = true
                    } else {
                        android.util.Log.d("MainActivity", "Invalid or non-media file: $path")
                    }
                }
            }
            Intent.ACTION_SEND_MULTIPLE -> {
                // Accept any media type or null type, we'll validate the actual files later
                val mediaUris = intent.getParcelableArrayListExtra<android.net.Uri>(Intent.EXTRA_STREAM)
                mediaUris?.let { uris ->
                    android.util.Log.d("MainActivity", "Multiple media URIs: ${uris.size} items")
                    val paths = uris.mapNotNull { uri -> 
                        android.util.Log.d("MainActivity", "Processing URI: $uri")
                        val path = getRealPathFromUri(uri)
                        if (path != null && isMediaFile(path)) {
                            android.util.Log.d("MainActivity", "Valid media file: $path")
                            path
                        } else {
                            android.util.Log.d("MainActivity", "Invalid or non-media file: $path")
                            null
                        }
                    }
                    if (paths.isNotEmpty()) {
                        android.util.Log.d("MainActivity", "Setting ${paths.size} shared files")
                        sharedFiles = paths
                        hasSharedContent = true
                    } else {
                        android.util.Log.d("MainActivity", "No valid media files found")
                    }
                }
            }
        }
        
        android.util.Log.d("MainActivity", "Final state - hasSharedContent: $hasSharedContent, files: ${sharedFiles.size}")
    }

    private fun isMediaFile(path: String): Boolean {
        val extension = path.lowercase().substringAfterLast('.', "")
        val imageExtensions = setOf("jpg", "jpeg", "png", "gif", "bmp", "webp", "heic", "heif")
        val videoExtensions = setOf("mp4", "mov", "avi", "mkv", "wmv", "flv", "3gp", "webm", "m4v", "3gpp", "ts", "mts")
        
        val isMedia = imageExtensions.contains(extension) || videoExtensions.contains(extension)
        android.util.Log.d("MainActivity", "File: $path, Extension: $extension, IsMedia: $isMedia")
        return isMedia
    }

    private fun getRealPathFromUri(uri: android.net.Uri): String? {
        return try {
            android.util.Log.d("MainActivity", "Processing URI: $uri")
            
            // Check if we have storage permissions
            val hasPermissions = hasStoragePermission()
            android.util.Log.d("MainActivity", "Has storage permissions: $hasPermissions")
            
            when (uri.scheme) {
                "content" -> {
                    // Try to get path from MediaStore first if we have permissions
                    if (hasPermissions) {
                        val projection = arrayOf(
                            android.provider.MediaStore.MediaColumns.DATA,
                            android.provider.MediaStore.MediaColumns.DISPLAY_NAME
                        )
                        
                        val cursor = contentResolver.query(uri, projection, null, null, null)
                        cursor?.use {
                            if (it.moveToFirst()) {
                                val dataIndex = it.getColumnIndex(android.provider.MediaStore.MediaColumns.DATA)
                                if (dataIndex != -1) {
                                    val path = it.getString(dataIndex)
                                    if (path != null && java.io.File(path).exists()) {
                                        // Check if we can actually read the file
                                        try {
                                            java.io.FileInputStream(path).use { stream ->
                                                // Try to read first few bytes to verify access
                                                val buffer = ByteArray(1024)
                                                stream.read(buffer)
                                            }
                                            android.util.Log.d("MainActivity", "Found accessible direct path: $path")
                                            return path
                                        } catch (e: Exception) {
                                            android.util.Log.d("MainActivity", "Direct path not accessible: ${e.message}")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Fallback: copy to cache and return cache path
                    android.util.Log.d("MainActivity", "Using cache fallback for content URI")
                    copyUriToCache(uri)
                }
                "file" -> {
                    val path = uri.path
                    if (path != null && hasPermissions) {
                        try {
                            // Test if we can read the file
                            java.io.FileInputStream(path).use { stream ->
                                val buffer = ByteArray(1024)
                                stream.read(buffer)
                            }
                            android.util.Log.d("MainActivity", "File URI accessible: $path")
                            path
                        } catch (e: Exception) {
                            android.util.Log.d("MainActivity", "File URI not accessible: ${e.message}, copying to cache")
                            copyUriToCache(uri)
                        }
                    } else {
                        android.util.Log.d("MainActivity", "No permissions or null path, copying to cache")
                        copyUriToCache(uri)
                    }
                }
                else -> {
                    android.util.Log.d("MainActivity", "Unknown scheme, copying to cache")
                    copyUriToCache(uri)
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error processing URI", e)
            copyUriToCache(uri) // Last resort fallback
        }
    }

    private fun copyUriToCache(uri: android.net.Uri): String? {
        return try {
            android.util.Log.d("MainActivity", "Copying URI to cache: $uri")
            
            val inputStream = contentResolver.openInputStream(uri)
            if (inputStream == null) {
                android.util.Log.e("MainActivity", "Could not open input stream for URI: $uri")
                return null
            }
            
            val fileName = "shared_${System.currentTimeMillis()}.${getFileExtension(uri)}"
            val cacheFile = java.io.File(cacheDir, fileName)
            
            inputStream.use { input ->
                cacheFile.outputStream().use { output ->
                    val buffer = ByteArray(8192) // 8KB buffer for better performance
                    var bytesRead: Int
                    var totalBytes = 0L
                    
                    while (input.read(buffer).also { bytesRead = it } != -1) {
                        output.write(buffer, 0, bytesRead)
                        totalBytes += bytesRead
                    }
                    
                    android.util.Log.d("MainActivity", "Copied ${totalBytes} bytes to cache: ${cacheFile.absolutePath}")
                }
            }
            
            // Verify the file was created and has content
            if (cacheFile.exists() && cacheFile.length() > 0) {
                android.util.Log.d("MainActivity", "Cache file verified: ${cacheFile.absolutePath} (${cacheFile.length()} bytes)")
                cacheFile.absolutePath
            } else {
                android.util.Log.e("MainActivity", "Cache file creation failed or empty")
                null
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Error copying file to cache", e)
            null
        }
    }

    private fun getFileExtension(uri: android.net.Uri): String {
        return try {
            val mimeType = contentResolver.getType(uri)
            when {
                mimeType?.startsWith("video/") == true -> {
                    when (mimeType) {
                        "video/mp4" -> "mp4"
                        "video/quicktime" -> "mov"
                        "video/x-msvideo" -> "avi"
                        else -> "mp4" // default
                    }
                }
                mimeType?.startsWith("image/") == true -> {
                    when (mimeType) {
                        "image/jpeg" -> "jpg"
                        "image/png" -> "png"
                        "image/gif" -> "gif"
                        else -> "jpg" // default
                    }
                }
                else -> "tmp"
            }
        } catch (e: Exception) {
            "tmp"
        }
    }

    override fun onPause() {
        super.onPause()
        // Lock device when app goes to background during presentation mode
        // This is handled by Flutter's lifecycle observer
    }
}
