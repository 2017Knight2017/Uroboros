import 'dart:io';
import 'package:flutter/material.dart';

class ProposalCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProposalCard({super.key, required this.data});
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'processing':
        return Colors.amber; 
      case 'failure':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String status = data['status'] ?? 'processing';
    final String imagePath = data['image'] ?? '';
    final String type = data['type'] ?? '';
    final String location = data['location'] ?? '';
    final String number = data['number'] ?? '';
    final String date = data['date'] ?? '';
    final String comment = data['comment'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 3,
        clipBehavior: Clip.antiAlias, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                color: _getStatusColor(status),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imagePath.isNotEmpty
                          ? Image.file(
                            File(imagePath),
                            width: 55,
                            height: 55,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                          )
                          : _buildPlaceholderImage(),
                      ),

                      const SizedBox(width: 12),
                      
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              type,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '№ $number',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(date),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),
                      
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              location,
                              style: TextStyle(fontSize: 11, height: 1.3, color: Colors.grey[600])
                            ),
                            Text(
                              comment,
                              style: const TextStyle(fontSize: 12, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildPlaceholderImage() {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, size: 20, color: Colors.grey),
    );
  }
}