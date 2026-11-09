import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ProposalScreen extends StatefulWidget {
  final List<File> images;
  final Text label;

  const ProposalScreen({super.key, required this.images, required this.label});

  @override
  State<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends State<ProposalScreen> {
  late List<File> _images;
  String _currentAddress = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.images);
    _getAddressFromCoordinates();
  }

  Future<void> _getAddressFromCoordinates() async {
    setState(() {
      _isLoading = true;
      _currentAddress = 'Получаем геолокацию...';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _currentAddress = 'Нет разрешений на геоданные'; _isLoading = false; });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 5), 
        onTimeout: () => throw TimeoutException("Placemarks")
      );

      setState(() {
        _currentAddress = 'Определяем адрес...';
      });

      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        locale: Locale('ru', 'RU'),
      ).timeout(
        const Duration(seconds: 5), 
        onTimeout: () => throw TimeoutException("Placemarks")
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;

        String street = place.street ?? 'Улица не найдена';
        String name = place.name ?? ''; 
        String locality = place.locality ?? place.subAdministrativeArea ?? '';

        setState(() {
          _currentAddress = 'г. $locality, ул. $street, $name';
          _isLoading = false;
        });
      } else {
        setState(() {
          _currentAddress = 'Адрес не найден по данным координатам';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentAddress = 'Улица не найдена';
        _isLoading = false;
      });
    }
  }

  final ImagePicker _picker = ImagePicker();

  void _add() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1000,
      maxHeight: 1000,
      imageQuality: 85, 
    );

    if (photo != null) {
      setState(() => widget.images.add(File(photo.path)));
    }

    _scrollToPosition();
  }

  int? _deletingIndex;

  void _remove(int idx) {
    setState(() { _deletingIndex = idx; });

    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        widget.images.removeAt(idx);
        _deletingIndex = null;
      });
      
      _scrollToPosition();
    });
  }

  Future<bool> _saveProposal(String number, String comment) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/proposals.json');

      List<dynamic> decoded = await file.exists() 
        ? jsonDecode(await file.readAsString())
        : [];
      
      Map<String, String> newRecord = {
        'id': Random().nextInt(10000).toString(),
        'status': "processing",
        'image': _images[0].path,
        'type': widget.label.data.toString(),
        'location': _currentAddress,
        'date': DateTime.now().toIso8601String(),
        'number': number,
        'comment': comment,
      };

      decoded.add(newRecord);
      await file.writeAsString(jsonEncode(decoded));

      return true;
    } catch (e) {
      return false;
    }
  }

  void _showSuccessSnackBar(BuildContext context) {
    final snackBar = SnackBar(
      content: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 12),
          Text('Заявка успешно отправлена!'),
        ],
      ),
      backgroundColor: Colors.green, 
      behavior: SnackBarBehavior.floating, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 3), 
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showFailureSnackBar(BuildContext context) {
    final snackBar = SnackBar(
      content: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white),
          SizedBox(width: 12),
          Text('Ошибка!'),
        ],
      ),
      backgroundColor: Colors.red, 
      behavior: SnackBarBehavior.floating, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      duration: const Duration(seconds: 3), 
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  final ScrollController _scrollController = ScrollController();

  void _scrollToPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        final double screenWidth = MediaQuery.of(context).size.width;

        final double percentOffset = screenWidth * 0.1; 

        final double targetScroll = (maxScroll - percentOffset).clamp(0.0, maxScroll);

        _scrollController.jumpTo(targetScroll);
      }
    });
  }

  final TextEditingController _autoNumberTextController = TextEditingController();
  final TextEditingController _commentTextController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _autoNumberTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    const double margin = 8.0;
    final double itemWidth = (screenWidth / 2) - margin * 2;
    const double itemHeight = 150.0;

    final bool showAddButton = widget.images.length < 4;
    
    final int totalItems = widget.images.length + (showAddButton ? 1 : 0);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: widget.label,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.all(10.0),
            child: SizedBox(
              height: itemHeight, 
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal, 
                itemCount: totalItems,
                itemBuilder: (context, idx) {
                  if (showAddButton && idx == widget.images.length) {
                    return Container(
                      width: itemWidth,
                      margin: const EdgeInsets.only(right: margin),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: IconButton(
                        onPressed: _add,
                        icon: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.grey),
                            SizedBox(height: 4),
                            Text('Добавить', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }

                  final File imageFile = widget.images[idx];

                  return AnimatedOpacity(
                    opacity: _deletingIndex == idx ? 0.0 : 1.0, 
                    duration: const Duration(milliseconds: 200), 
                    child: AnimatedScale(
                      scale: _deletingIndex == idx ? 0.5 : 1.0, 
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        width: itemWidth,
                        margin: const EdgeInsets.only(right: margin),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                imageFile,
                                width: itemWidth,
                                height: itemHeight,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _remove(idx),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: margin),
            child: TextField(
              controller: _autoNumberTextController,
              decoration: InputDecoration(
                labelText: 'Номер автомобиля',
                hintText: 'Введите номер...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: margin),
            child: _isLoading
              ? CircularProgressIndicator()
              : Text("Локация: $_currentAddress"),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: margin),
            child: TextField(
              controller: _commentTextController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Комментарий',
                hintText: 'Введите комментарий...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsetsGeometry.symmetric(horizontal: margin),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final bool result = await _saveProposal(_autoNumberTextController.text, _commentTextController.text);
                  if (!mounted) return;

                  if (result) {
                    _showSuccessSnackBar(context);
                    Navigator.pop(context, true);
                  } else {
                    _showFailureSnackBar(context);
                  }
                },
                child: const Text(
                  'Отправить',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}