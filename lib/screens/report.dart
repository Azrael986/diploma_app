import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'dart:convert';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _descriptionController = TextEditingController();
  String _selectedType = 'Бие махбодын хүчирхийлэл';
  File? _image;
  Position? _currentPosition;

  final List<String> _reportTypes = [
    'Бие махбодын хүчирхийлэл',
    'Сэтгэл санааны дарамт',
    'Үл хайхрах байдал',
    'Бэлгийн хүчирхийлэл',
    'Цахим дарамт (Bullying)',
    'Яаралтай тусламж',
    'Бусад',
  ];

Future<void> _pickImage() async {
  final ImagePicker _picker = ImagePicker(); // Picker-ээ үүсгэж байна
  
  final XFile? image = await _picker.pickImage(
    source: ImageSource.camera,
    maxWidth: 800,       // Зургийн өргөнийг хязгаарлана
    imageQuality: 50,     // Чанарыг нь 50% болгож хэмжээг эрс багасгана
  );

  if (image != null) {
    setState(() {
      _image = File(image.path); // Авсан зургаа дэлгэцэнд харуулахын тулд хадгална
    });
  }
}

  // 2. Байршил тогтоох функц
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentPosition = position);
  }
  

  // 3. Мэдээллийг Firebase руу илгээх
  Future<void> _submitReport() async {
    try {
    String base64Image = "";

    // 1. Зураг байгаа эсэхийг шалгаад Base64 рүү хөрвүүлэх
    if (_image != null) {
      List<int> imageBytes = await _image!.readAsBytes();
      base64Image = base64Encode(imageBytes);
    }

    final user = FirebaseAuth.instance.currentUser;

    // 2. Firestore руу илгээх
    await FirebaseFirestore.instance.collection('reports').add({
      'userId': user?.uid,
      'type': _selectedType,
      'description': _descriptionController.text,
      'image_data': base64Image, // Зургийг текст хэлбэрээр хадгалах
      'location': _currentPosition != null 
          ? '${_currentPosition!.latitude}, ${_currentPosition!.longitude}' 
          : 'Тодорхойгүй',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Шинэ',
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Мэдээлэл амжилттай илгээгдлээ!")),
    );
    
    // Илгээсний дараа талбаруудыг цэвэрлэх
    _descriptionController.clear();
    setState(() {
      _image = null;
    });

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Алдаа гарлаа: $e")),
    );
  }
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user?.uid,
        'type': _selectedType,
        'description': _descriptionController.text,
        'location': _currentPosition != null 
            ? '${_currentPosition!.latitude}, ${_currentPosition!.longitude}' 
            : 'Тодорхойгүй',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Шинэ',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Мэдээлэл болон байршлыг амжилттай илгээлээ!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Алдаа: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Хүүхэд хамгааллын мэдээлэл")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField(
              value: _selectedType,
              items: _reportTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => setState(() => _selectedType = val as String),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Юу болсон талаар бичнэ үү", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            
            // Зураг харуулах хэсэг
            _image != null 
              ? Image.file(_image!, height: 150) 
              : const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(onPressed: _pickImage, icon: const Icon(Icons.camera), label: const Text("Зураг авах")),
                ElevatedButton.icon(onPressed: _getCurrentLocation, icon: const Icon(Icons.location_on), label: const Text("Байршил авах")),
              ],
            ),
            
            // Жишээ нь AppBar дээрээ Logout товчлуур нэмэх:
            AppBar(
              title: Text("Мэдээлэл илгээх"),
              actions: [
              IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
              await FirebaseAuth.instance.signOut(); // Системээс гаргах
               },
              ),
            ],
            ),
            const SizedBox(height: 10),
            if (_currentPosition != null)
              Text("Байршил: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}"),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60)
              ),
              child: const Text("МЭДЭЭЛЭЛ ИЛГЭЭХ", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}