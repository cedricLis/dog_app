import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFullScreen = false; // Pour savoir si on est en plein écran
  bool _isWeatherPanelOpen = false;
  String _selectedWeather = 'Auto';
  String _streamUrl = 'http://192.168.4.1:81/stream';

  // 🔄 Bascule entre le mode plein écran et normal
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  Future<void> _adjustCameraSettings() async {
    String url = "http://192.168.4.1/control";
    Map<String, String> queryParams = {};

    switch (_selectedWeather) {
      case 'Auto':
        queryParams = {"var": "wb_mode", "val": "0"};
        break;
      case 'Ensoleillé':
        queryParams = {"var": "wb_mode", "val": "1"};
        break;
      case 'Nuageux':
        queryParams = {"var": "wb_mode", "val": "2"};
        break;
      case 'Intérieur':
        queryParams = {"var": "wb_mode", "val": "3"};
        break;
    }

    final Uri uri = Uri.parse(url).replace(queryParameters: queryParams);
    await http.get(uri);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return MaterialApp(
      title: 'Surveillance Canine',
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: _isFullScreen
            ? null
            : AppBar(
          title: Text('Surveillance Canine 🐕‍🦺'),
          backgroundColor: Colors.blueGrey[900],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildVideoStream(),
                if (!_isFullScreen) Expanded(child: _buildInfoPanel()),
              ],
            ),
            if (_isWeatherPanelOpen) _buildWeatherPanel(),
          ],
        ),
      ),
    );
  }

  // 🎥 Interface vidéo avec ajustement d'écran
  Widget _buildVideoStream() {
    return Stack(
      children: [
        // Vidéo avec un aspect ratio pour la proportion de la vidéo
        AspectRatio(
          aspectRatio: 16 / 9, // Garder le ratio 16:9 pour la vidéo
          child: Mjpeg(
            stream: _streamUrl,
            isLive: true,
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: IconButton(
            icon: Icon(Icons.fullscreen, size: _isFullScreen ? 50 : 30, color: Colors.white),
            onPressed: _toggleFullScreen,
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: IconButton(
            icon: Icon(Icons.wb_sunny, size: 30, color: Colors.white),
            onPressed: () {
              setState(() {
                _isWeatherPanelOpen = !_isWeatherPanelOpen;
              });
            },
          ),
        ),
      ],
    );
  }

  // 🎛️ Panel pour ajuster les paramètres de la caméra (météo)
  Widget _buildWeatherPanel() {
    return Positioned(
      left: 10,
      top: 100,
      child: Container(
        padding: EdgeInsets.all(10),
        width: 200,
        decoration: BoxDecoration(
          color: Colors.blueGrey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text("Environnement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedWeather,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedWeather = newValue!;
                  _adjustCameraSettings();
                  _isWeatherPanelOpen = false;
                });
              },
              items: ['Auto', 'Ensoleillé', 'Nuageux', 'Intérieur']
                  .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // 📑 Infos supplémentaires en mode normal
  Widget _buildInfoPanel() {
    return Column(
      children: [
        // 🛑 Section Gaz
        _buildSection(
          title: "Détection de Gaz 🛑",
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSensorCard("Gaz 1", "50 ppm", Colors.orange),
              _buildSensorCard("Gaz 2", "30 ppm", Colors.yellow),
              _buildSensorCard("Gaz 3", "10 ppm", Colors.green),
            ],
          ),
        ),
        SizedBox(height: 15),

        // 📍 Section GPS
        _buildSection(
          title: "Localisation 📍",
          content: Column(
            children: [
              Text("Latitude: 48.8566 N", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              Text("Longitude: 2.3522 E", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // 📌 Widget pour afficher une section avec un titre et du contenu
  Widget _buildSection({required String title, required Widget content}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  // 🔹 Widget pour afficher une carte sensorielle (Gaz)
  Widget _buildSensorCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      width: 110,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
