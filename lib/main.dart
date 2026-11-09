import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'photo_choose.dart';
import 'package:path_provider/path_provider.dart';
import 'proposal_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uroboros',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.blueAccent),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> _proposals = [];
  bool _isLoading = true; 

  @override
  void initState() {
    super.initState();
    _loadProposals();
  }

  void _loadProposals() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/proposals.json');
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final decodedData = jsonDecode(contents);
        //final decodedData = [{
        //  "id":"1102",
        //  "status":"processing",
        //  "image":"/data/user/0/com.example.my_city/cache/scaled_a8b9b399-4930-4a1f-a727-adc81a20088e3619776828351711048.jpg",
        //  "type":"Езда по автобусной полосе",
        //  "location":"г. Бишкек, ул Бокомбаева, 6"
        //  "date":"2026-11-08T05:00:32.404506",
        //  "number":"236786718",
        //  "comment":"37218978"
        //}];

        setState(() {
          _proposals = decodedData; 
          _isLoading = false;    
        });
      } else {
        await file.writeAsString(jsonEncode([]));
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при чтении файла: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _tellAboutCrime() async {
    final bool? result = await Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => PhotoChoosePage()
      )
    );

    if (result == true) _loadProposals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Uroboros'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30.0),

          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: _tellAboutCrime, 
              child: Padding(
                padding: EdgeInsetsGeometry.all(48.0),
                child: Text(
                  "Сообщить о нарушении",
                  style: TextStyle(fontSize: 18),
                )
              )
            ),
          ),

          const SizedBox(height: 30.0),

          const Padding(
            padding: EdgeInsetsGeometry.only(left: 16.0),
            child: Text(
              "До двух отчётов в час. Съёмка только камерой приложения.",
              style: TextStyle(fontWeight: FontWeight(300)))
          ),

          const SizedBox(height: 20.0),

          const Padding(
            padding: EdgeInsetsGeometry.only(left: 16.0),
            child: Text(
              "Мои отчёты", 
              style: TextStyle(
                fontWeight: FontWeight(600), 
                fontSize: 18),)
          ),

          const SizedBox(height: 20.0),

          _isLoading ?
            const Center(
              child: CircularProgressIndicator(),
            )
          : 
            _proposals.isEmpty ? 
              Center(
                child: Text("Пока нет отчётов.", style: TextStyle(fontWeight: FontWeight(300))),
              )
            :
              Expanded(
                child: ListView.builder(
                  itemCount: _proposals.length,
                  itemBuilder: (context, idx) => ProposalCard(data: _proposals[_proposals.length-1 - idx])
                )
              ),
            ],
      ),
    );
  }
}