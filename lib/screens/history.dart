import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatusCheckScreen extends StatefulWidget {
  const StatusCheckScreen({super.key});

  @override
  State<StatusCheckScreen> createState() => _StatusCheckScreenState();
}

class _StatusCheckScreenState extends State<StatusCheckScreen> {
  String selectedStatus = "Бүгд"; // Анхны сонголт

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Миний мэдээллүүд", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Шүүлтүүр хэсэг (Tabs)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: ["Бүгд", "Хүлээгдэж", "Хянагдсан", "Шийдвэрлэсэн"].map((status) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: selectedStatus == status,
                    onSelected: (bool selected) {
                      setState(() {
                        selectedStatus = status;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // 2. Мэдээллийн жагсаалт
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getFilteredStream(user?.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text("Мэдээлэл олдсонгүй."));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildReportCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Дипломын загвар дээрх нэмэх товчлуур
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Firestore-оос шүүж унших функц
  Stream<QuerySnapshot> _getFilteredStream(String? uid) {
    var query = FirebaseFirestore.instance
        .collection('reports')
        .where('userId', isEqualTo: uid);

    if (selectedStatus != "Бүгд") {
      query = query.where('status', isEqualTo: selectedStatus);
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

 // Мэдээллийн картыг зурагтай нь хамт бүтээх
  Widget _buildReportCard(Map<String, dynamic> data) {
    // 1. Статусаас хамаарч өнгө тодорхойлох
    Color statusColor;
    String statusText = data['status'] ?? "Шинэ";

    switch (statusText) {
      case "Хянагдсан":
        statusColor = Colors.green;
        break;
      case "Шийдвэрлэсэн":
        statusColor = Colors.blue;
        break;
      case "Шинэ":
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. ЗУРАГ ХАРУУЛАХ ХЭСЭГ (Base64 -> Image)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: (data['image_data'] != null && data['image_data'].toString().isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        base64Decode(data['image_data']),
                        fit: BoxFit.cover,
                        // Зураг ачаалахад алдаа гарвал (Base64 буруу бол)
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, color: Colors.red),
                      ),
                    )
                  : const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
            
            const SizedBox(width: 15),

            // 3. ТЕКСТ МЭДЭЭЛЛИЙН ХЭСЭГ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Төрөл (Гарчиг)
                      Expanded(
                        child: Text(
                          data['type'] ?? "Төрөлгүй",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Статус (Badge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Тайлбар
                  Text(
                    data['description'] ?? "Тайлбаргүй",
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Divider(height: 15),
                  // Огноо
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        data['timestamp'] != null 
                            ? (data['timestamp'] as Timestamp).toDate().toString().substring(0, 16)
                            : "Огноогүй",
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}