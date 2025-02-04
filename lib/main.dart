import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFullScreen = false; // Pour savoir si on est en plein écran

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
                stream: 'http://192.168.4.1:81/stream',
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

  // 🔄 Mode plein écran (paysage) avec un bouton pour quitter le mode plein écran
  Widget _buildFullScreenVideo() {
    return GestureDetector(
      onTap: _toggleFullScreen,
      child: Stack(
        children: [
          Center(
            child: Mjpeg(
              stream: 'http://192.168.4.1:81/stream',
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