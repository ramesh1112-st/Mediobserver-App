import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isUploading = false;
  bool _isDisposed = false; // ✅ track widget disposal

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _isDisposed = true; // ✅ mark as disposed
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? {};

      final name =
          data['name'] ?? data['username'] ?? user.displayName ?? 'No name';

      if (!mounted || _isDisposed) return; // ✅ safety check
      setState(() {
        userData = {
          ...data,
          'name': name,
          'email': data['email'] ?? user.email,
        };
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _updateUserData(String age, String gender) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'age': age,
      'gender': gender,
    }, SetOptions(merge: true));

    await _loadUserData();
  }

  void _showEditDialog() {
    final TextEditingController ageController = TextEditingController(
      text: userData?['age'] ?? '',
    );
    final TextEditingController genderController = TextEditingController(
      text: userData?['gender'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: genderController,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () async {
              await _updateUserData(ageController.text, genderController.text);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    if (!mounted || _isDisposed) return;
    setState(() {
      isUploading = true;
    });

    try {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance.ref().child(
        'profile_photos/${user.uid}.jpg',
      );

      await storageRef.putFile(file);
      final imageUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoUrl': imageUrl,
      }, SetOptions(merge: true));

      await _loadUserData();
    } catch (e) {
      debugPrint('Image upload failed: $e');
    }

    if (!mounted || _isDisposed) return;
    setState(() {
      isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal,
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[300],
                                    backgroundImage:
                                        userData?['photoUrl'] != null
                                        ? NetworkImage(userData!['photoUrl'])
                                        : null,
                                    child: userData?['photoUrl'] == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  if (isUploading)
                                    const Positioned.fill(
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: _pickAndUploadImage,
                                child: const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.teal,
                                  child: Icon(
                                    Icons.add,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                userData?['name'] ?? 'No name',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                userData?['email'] ?? 'No email',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                "Age: ${userData?['age'] ?? 'N/A'}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                "Gender: ${userData?['gender'] ?? 'N/A'}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                              FloatingActionButton(
                                mini: true,
                                backgroundColor: Colors.teal,
                                onPressed: _showEditDialog,
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
