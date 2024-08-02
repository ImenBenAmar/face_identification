import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  CameraController? _controller;
  late List<CameraDescription> _cameras;
  String _result = "Press capture to start";
  bool _showForm = false; // New flag to manage form visibility
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _cinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _controller = CameraController(_cameras[0], ResolutionPreset.high);
    await _controller!.initialize();
    setState(() {});
  }

  Future<void> _captureAndSend() async {
    try {
      final image = await _controller!.takePicture();
      final imageBytes = await image.readAsBytes();

      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/recognize'),
        headers: {'Content-Type': 'application/octet-stream'},
        body: imageBytes,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _result = '''
          Name: ${responseData['name']}
          Surname: ${responseData['surname']}
          ID: ${responseData['id']}
          Confidence: ${responseData['confidence']}
          CIN: ${responseData['cin']}
          Phone Number: ${responseData['phone_number']}
          ''';
          _showForm = false; // Hide form if person is found
        });
      } else {
        setState(() {
          _result =
              "Person not found in database. Please fill the form and capture your face.";
          _showForm = true; // Show form if person is not found
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final surname = _surnameController.text;
      final phoneNumber = _phoneController.text;
      final cin = _cinController.text;

      try {
        final image = await _controller!.takePicture();
        final imageBytes = await image.readAsBytes();

        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/create_folder'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'surname': surname,
            'phone_number': phoneNumber,
            'cin': cin,
            'image': base64Encode(imageBytes),
          }),
        );

        final responseData = jsonDecode(response.body);

        if (response.statusCode == 200) {
          final personId =
              responseData['id'].toString(); // Convert ID to string
          setState(() {
            _result =
                'Person added successfully with ID $personId. Please wait to capture your face.';
          });

          // Wait for 5 seconds
          await Future.delayed(Duration(seconds: 5));

          // Capture 170 images
          List<http.MultipartFile> imageFiles = [];
          for (int i = 0; i < 100; i++) {
            try {
              final image = await _controller!.takePicture();
              final imageBytes = await image.readAsBytes();
              final multipartFile = http.MultipartFile.fromBytes(
                'images',
                imageBytes,
                filename: 'image_$i.jpg',
              );
              imageFiles.add(multipartFile);

              setState(() {
                _result = 'Captured image $i/100';
              });
            } catch (e) {
              setState(() {
                _result = 'Error capturing image $i: $e';
              });
            }
          }

          // Upload images
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('http://127.0.0.1:5000/upload_images'),
          )
            ..fields['id'] = personId // Ensure ID is sent as a string
            ..files.addAll(imageFiles);

          final response = await request.send();
          final responseBody = await response.stream.bytesToString();

          if (response.statusCode == 200) {
            setState(() {
              _result = 'Images uploaded successfully.';
            });

            // Notify user that the model update is starting
            setState(() {
              _result = 'Wait until the model is updated.';
            });

            // Update the model
            final updateResponse = await http.post(
              Uri.parse('http://127.0.0.1:5000/update_model'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'id': personId}),
            );

            if (updateResponse.statusCode == 200) {
              setState(() {
                _result =
                    'Model updated successfully. Person added successfully to the database. You can check it.';
              });
            } else {
              setState(() {
                _result =
                    'Error updating the model: ${jsonDecode(updateResponse.body)['error']}';
              });
            }
          } else {
            setState(() {
              _result =
                  'Error uploading images: ${jsonDecode(responseBody)['error']}';
            });
          }
        } else {
          setState(() {
            _result = responseData['error'];
          });
        }
      } catch (e) {
        setState(() {
          _result = 'Error: $e';
        });
      }
    }
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildResultCard(String result) {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          result,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Get the size of the screen
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Recognition',
            style:
                TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Container(
                width: 300, // Set the desired width
                height: 400, // Set the desired height
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _captureAndSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Button color
                foregroundColor: Colors.white, // Text color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              ),
              child: Text('Capture'),
            ),
            SizedBox(height: 20),
            _buildResultCard(_result),
            if (_showForm) // Display the form if needed
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextFormField(
                        controller: _nameController,
                        label: 'Name',
                        hint: 'Enter your name',
                      ),
                      _buildTextFormField(
                        controller: _surnameController,
                        label: 'Surname',
                        hint: 'Enter your surname',
                      ),
                      _buildTextFormField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                      ),
                      _buildTextFormField(
                        controller: _cinController,
                        label: 'CIN',
                        hint: 'Enter your CIN',
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal, // Button color
                          foregroundColor: Colors.white, // Text color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 30),
                        ),
                        child: Text('Submit'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
