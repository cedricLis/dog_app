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
  String _selectedWeather = 'Normal'; // Option par défaut
  String _streamUrl = 'http://192.168.4.1:81/stream'; // URL du flux vidéo

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

  // Fonction pour envoyer une requête à la caméra selon l'environnement
  Future<void> _adjustCameraSettings() async {
    String url = "http://192.168.4.1/control";
    Map<String, String> queryParams = {};

    // Adapter les paramètres en fonction de la météo
    switch (_selectedWeather) {
      case 'Ensoleillé':
        queryParams = {"var": "wb", "val": "2"}; // Balance des blancs pour l'ensoleillement
        _streamUrl = 'http://192.168.4.1:81/stream?env=sunny'; // URL spécifique si ensoleillé
        break;
      case 'Nuageux':
        queryParams = {"var": "wb", "val": "1"}; // Balance des blancs pour nuageux
        _streamUrl = 'http://192.168.4.1:81/stream?env=cloudy'; // URL spécifique si nuageux
        break;
      case 'Normal':
        queryParams = {"var": "wb", "val": "0"}; // Réglages par défaut
        _streamUrl = 'http://192.168.4.1:81/stream?env=normal'; // URL par défaut
        break;
    }

    // Crée une nouvelle URL avec les paramètres
    final Uri uri = Uri.parse(url).replace(queryParameters: queryParams);

    // Envoi de la requête à la caméra
    await http.get(uri);

    // Redémarre le flux vidéo avec la nouvelle URL après la mise à jour
    setState(() {
      // Met à jour le flux vidéo avec la nouvelle URL
      _streamUrl = _streamUrl;
    });
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
        body: _isFullScreen
            ? _buildFullScreenVideo()
            : _buildNormalScreen(screenHeight),
      ),
    );
  }

  // 🎥 Interface normale avec vidéo et infos gaz/GPS
  Widget _buildNormalScreen(double screenHeight) {
    return Column(
      children: [
        // 📡 Flux vidéo en direct avec bouton plein écran
        Stack(
          children: [
            Container(
              height: screenHeight / 3,
              color: Colors.black,
              child: Mjpeg(
                stream: _streamUrl,
                isLive: true,
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.fullscreen, size: 30, color: Colors.white),
                onPressed: _toggleFullScreen,
              ),
            ),
          ],
        ),

        SizedBox(height: 10),

        // 🛑 Section météo (sélecteur déroulant)
        _buildWeatherSelection(),

        SizedBox(height: 10),

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

  // Widget pour le sélecteur de météo
  Widget _buildWeatherSelection() {
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
          Text("Sélectionner l'environnement météo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          DropdownButton<String>(
            value: _selectedWeather,
            onChanged: (String? newValue) {
              setState(() {
                _selectedWeather = newValue!;
                _adjustCameraSettings(); // Mettre à jour la caméra dès que l'option change
              });
            },
            items: <String>['Normal', 'Ensoleillé', 'Nuageux']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 🔄 Mode plein écran (paysage) avec un bouton pour quitter le mode plein écran
  Widget _buildFullScreenVideo() {
    return GestureDetector(
      onTap: _toggleFullScreen,
      child: Stack(
        children: [
          Center(
            child: Mjpeg(
              stream: _streamUrl,
              isLive: true,
            ),
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: IconButton(
              icon: Icon(Icons.fullscreen_exit, size: 40, color: Colors.white),
              onPressed: _toggleFullScreen,
            ),
          ),
        ],
      ),
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
