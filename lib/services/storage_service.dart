// lib/core/services/storage_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

/// Service class that handles image storage operations using Cloudinary
/// Provides functionality to upload images to cloud storage and retrieve their URLs
class StorageService {
  // Cloudinary configuration constants
  final String _cloudName = ''; // Your Cloudinary cloud name
  final String _uploadPreset = ''; // Your upload preset
  final String _uploadUrl = ''; // URL link

  /// Uploads an image file to Cloudinary cloud storage
  ///
  /// Takes a local image file and uploads it to Cloudinary using their REST API.
  /// The upload uses a predefined upload preset for consistent image handling.
  ///
  /// @param imageFile - The local File object containing the image to upload
  /// @return String - The secure HTTPS URL of the uploaded image
  /// @throws Exception if the upload fails or returns an error
  Future<String> uploadImage(File imageFile) async {
    log("Attempting to upload image to Cloudinary...");
    try {
      // Create a multipart HTTP request for file upload
      var request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Add the upload preset to specify upload configuration
      request.fields['upload_preset'] = _uploadPreset;

      // Attach the image file to the request
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Send the request and wait for response
      final response = await request.send();

      // Convert the response stream to a string for JSON parsing
      final responseBody = await response.stream.bytesToString();
      final decodedJson = json.decode(responseBody);

      // Check if upload was successful (HTTP 200)
      if (response.statusCode == 200) {
        // Extract the secure URL from the response
        final imageUrl = decodedJson['secure_url'];
        log("Image uploaded successfully: $imageUrl");
        return imageUrl;
      } else {
        // Handle upload failure by extracting error message from response
        log("Failed to upload image: ${decodedJson['error']['message']}");
        throw Exception("Failed to upload image: ${decodedJson['error']['message']}");
      }
    } catch (e) {
      // Log any exceptions that occur during the upload process
      log("Error during Cloudinary upload: $e");
      rethrow; // Re-throw the exception to let calling code handle it
    }
  }
}
