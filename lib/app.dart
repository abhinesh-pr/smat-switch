import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DatabaseReference _fanRef = FirebaseDatabase.instance
      .refFromURL("https://smart-hub-13f70-default-rtdb.firebaseio.com/")
      .child("switch/fan/status");

  final DatabaseReference _lightRef = FirebaseDatabase.instance
      .refFromURL("https://smart-hub-13f70-default-rtdb.firebaseio.com/")
      .child("switch/light/status");

  final DatabaseReference _ssidRef = FirebaseDatabase.instance
      .refFromURL("https://smart-hub-13f70-default-rtdb.firebaseio.com/")
      .child("config/wifiSSID");
  
  final DatabaseReference _passwordRef = FirebaseDatabase.instance
      .refFromURL("https://smart-hub-13f70-default-rtdb.firebaseio.com/")
      .child("config/wifiPassword");


  String fanStatus = "OFF";
  bool isFanOn = false;
  String lightStatus = "OFF";
  bool isLightOn = false;
  String smartHubSSID = "SmartHub_AP";

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> requestPermissions() async {
    await [
      Permission.location,
      Permission.locationWhenInUse,
    ].request();
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _listenToSwitchStatus();
  }

  void _listenToSwitchStatus() {
    _fanRef.onValue.listen((event) {
      setState(() {
        fanStatus = event.snapshot.value.toString();
        isFanOn = fanStatus == "ON";
      });
    });

    _lightRef.onValue.listen((event) {
      setState(() {
        lightStatus = event.snapshot.value.toString();
        isLightOn = lightStatus == "ON";
      });
    });
  }

  void _toggleFan() {
    _fanRef.set(isFanOn ? "OFF" : "ON");
  }

  void _toggleLight() {
    _lightRef.set(isLightOn ? "OFF" : "ON");
  }

  void connectToDeviceWiFi() async {
    print("Attempting to connect to WiFi: $smartHubSSID");
    bool connected = await WiFiForIoTPlugin.findAndConnect(smartHubSSID);

    if (connected) {
      print("Successfully connected to $smartHubSSID");
      await Future.delayed(Duration(seconds: 2));
      bool canLaunch = await canLaunchUrl(Uri.parse("http://192.168.4.1"));

      if (canLaunch) {
        print("Opening device portal...");
        launchUrl(Uri.parse("http://192.168.4.1"), mode: LaunchMode.externalApplication);
      } else {
        print("Cannot open the URL.");
      }
    } else {
      print("Failed to connect to device WiFi.");
    }
  }


  void _showWiFiDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("WiFi Configuration"),
          content: Text("Do you want to configure the device WiFi?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                connectToDeviceWiFi();
              },
              child: Text("Connect"),
            ),
          ],
        );
      },
    );
  }


// Custom Input Field with Neumorphic Design
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Colors.black, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Color(0xFF515151)),
        prefixIcon: Icon(icon, color: Color(0xFF000000)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black,width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

// Custom Styled Text Button
  Widget _buildTextButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(color: Colors.black, fontSize: 16),
      ),
    );
  }

// Custom Styled Elevated Button
  Widget _buildElevatedButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF0D6DFB),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 10,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("Smart Controller"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Gradient (Changes when any switch is ON)
          AnimatedContainer(
            duration: Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isFanOn || isLightOn
                    ? [Colors.blueAccent.shade700, Colors.purpleAccent.shade700]
                    : [Colors.purpleAccent.shade700, Colors.blueAccent.shade700],
              ),
            ),
          ),
          Center(child: _buildControlPanel()),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // FAN Card
              _buildSwitchCard(
                label: "FAN",
                status: fanStatus,
                isOn: isFanOn,
                colors: isFanOn
                    ? [Colors.green.shade600, Colors.greenAccent.shade400]
                    : [Color(0Xff8B0000), Color(0XffFF3B30)],
                toggleFunction: _toggleFan,
              ),
              SizedBox(width: 20),
              // LIGHT Card
              _buildSwitchCard(
                label: "LIGHT",
                status: lightStatus,
                isOn: isLightOn,
                colors: isLightOn
                    ? [Colors.green.shade600, Colors.greenAccent.shade400]
                    : [Color(0Xff8B0000), Color(0XffFF3B30)],
                toggleFunction: _toggleLight,
              ),
            ],
          ),
          SizedBox(height: 20),
          // WiFi Configuration Button
          ElevatedButton(
            onPressed: _showWiFiDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: EdgeInsets.symmetric(vertical: 15),
              minimumSize: Size(double.infinity, 50),
            ),
            child: Text(
              "Configure WiFi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchCard({
    required String label,
    required String status,
    required bool isOn,
    required List<Color> colors,
    required VoidCallback toggleFunction,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: toggleFunction,
        child: AnimatedContainer(
          duration: Duration(milliseconds: 500),
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                label == "FAN" ? Icons.air : Icons.lightbulb,
                size: 50,
                color: isOn ? Colors.white : Colors.grey.shade300,
              ),
              SizedBox(height: 10),
              Text(
                "$label: $status",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
