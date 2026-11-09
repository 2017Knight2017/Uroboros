import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'proposal.dart';

class PhotoChoosePage extends StatefulWidget {
  const PhotoChoosePage({super.key});

  @override
  State<PhotoChoosePage> createState() => _PhotoChoosePageState();
}

class _PhotoChoosePageState extends State<PhotoChoosePage> {
  final ImagePicker _picker = ImagePicker();

  Future<bool> ensureLocationServiceIsEnabled(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    while (!serviceEnabled && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_disabled, color: Colors.orange),
                SizedBox(width: 8),
                Text('Требуется геолокация'),
              ],
            ),
            content: const Text(
              'Приложение использует автоматическое определение геолокации. Пожалуйста, включите её в настройках.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Включить GPS'),
              ),
            ],
          );
        },
      );

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
    }

    return true;
  }

  Future<void> _takePhoto(String label) async {
    if (!(await ensureLocationServiceIsEnabled(context))) return;

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85, 
    );

    if (photo != null && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProposalScreen(images: [File(photo.path)], label: Text(label)),
        ),
      );

      if (result == true && mounted) Navigator.pop(context, true);
    }
  }

  ElevatedButton menuButton(String label) => ElevatedButton(
    style: ElevatedButton.styleFrom(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)
      ),
    ),
    onPressed: () => _takePhoto(label), 
    child: Text(
      label,
      textAlign: TextAlign.center
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Uroboros'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), 
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              children: [
                menuButton("Езда по автобусной полосе"),
                menuButton("Парковка на автобусной остановке"),
                menuButton("Парковка на тротуаре / пешеходной зоне"),
                menuButton("Парковка на газоне / зеленой зоне"),
                menuButton("Парковка на велодорожке / велополосе"),
                menuButton("Езда по автобусной полосе"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
