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

  @override
  void initState() {
    super.initState();
    _setStreamQuality();
  }


  // 🔄 Bascule entre le mode plein écran et normal
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    }
  }

  void _toggleWeatherPanel() {
    setState(() {
      _isWeatherPanelOpen = !_isWeatherPanelOpen;
    });
  }

  Future<void> _setStreamQuality() async {
    String url = "http://192.168.4.1/control?var=quality&val=31";
    try {
      await http.get(Uri.parse(url));
      print("Qualité du flux définie à 31");
    } catch (e) {
      print("Erreur lors du réglage de la qualité : $e");
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
            ? null // Pas de barre de navigation en plein écran
            : AppBar(
          title: Text('Surveillance Canine 🐕‍🦺'),
          backgroundColor: Colors.blueGrey[900],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildVideoStream(), // Vidéo en mode plein écran ou normal
                if (!_isFullScreen) ...[ // Infos cachées en plein écran
                  _buildInfoPanel(),
                ],
              ],
            ),
            // Affichage du panneau météo
            if (_isWeatherPanelOpen) _buildWeatherPanel(),
          ],
        ),
      ),
    );
  }

  // 🎥 Interface vidéo en mode normal avec bouton plein écran
  Widget _buildVideoStream() {
    return Stack(
      children: [
        Container(
          height: _isFullScreen ? MediaQuery.of(context).size.height : MediaQuery.of(context).size.height / 3,
          color: Colors.black,
          child: Mjpeg(
            stream: _streamUrl,
            isLive: true,
          ),
        ),

        if (!_isFullScreen) // Affiche le bouton plein écran en mode normal
          Positioned(
            bottom: 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.fullscreen, size: 30, color: Colors.white),
              onPressed: _toggleFullScreen, // Utilisation de la méthode existante
            ),
          ),

        if (_isFullScreen) // Affiche le bouton pour revenir en mode normal en plein écran
          Positioned(
            bottom: 30,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.fullscreen_exit, size: 40, color: Colors.white),
              onPressed: _toggleFullScreen, // Utilisation de la méthode existante
            ),
          ),

        if (!_isFullScreen) // Affiche le bouton plein écran en mode normal
        // L'icône du soleil placée en bas à gauche dans le rectangle vidéo
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
        if (_isFullScreen) // Affiche le bouton pour revenir en mode normal en plein écran
        // L'icône du soleil placée en bas à gauche dans le rectangle vidéo
          Positioned(
            bottom: 30,
            left: 20,
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
                  _isWeatherPanelOpen = false; // Fermer le panneau météo après sélection
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

  // 📑 Infos supplémentaires (gaz, localisation) en mode normal
  Widget _buildInfoPanel() {
    double screenWidth = MediaQuery.of(context).size.width;
    double detectionGazWidth = screenWidth * 0.9;

    return Column(
      children: [
        _buildSection(
          title: "Détection de Gaz 🛑",
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSensorCard("Gaz 1", "50 ppm", Colors.orange, detectionGazWidth),
              _buildSensorCard("Gaz 2", "30 ppm", Colors.yellow, detectionGazWidth),
              _buildSensorCard("Gaz 3", "10 ppm", Colors.green, detectionGazWidth),
            ],
          ),
        ),
        SizedBox(height: 15),
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
  Widget _buildSensorCard(String label, String value, Color color, double parentWidth) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      width: parentWidth / 3.5,
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
