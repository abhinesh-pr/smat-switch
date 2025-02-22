import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SwitchifyDashboard extends StatelessWidget {
  final DatabaseReference lightRef = FirebaseDatabase.instance
      .refFromURL("https://smart-hub-13f70-default-rtdb.firebaseio.com/")
      .child("switch/light/status");

  final DatabaseReference socketRef = FirebaseDatabase.instance
      .refFromURL("https://smart-hub-13f70-default-rtdb.firebaseio.com/")
      .child("switch/fan/status");

  final DatabaseReference humidityRef = FirebaseDatabase.instance
      .refFromURL("https://smart-hub-13f70-default-rtdb.firebaseio.com/")
      .child("sensor/humidity");

  final DatabaseReference temperatureRef = FirebaseDatabase.instance
      .refFromURL("https://smart-hub-13f70-default-rtdb.firebaseio.com/")
      .child("sensor/temperature");

  SwitchifyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.only(left: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 22, color: Colors.black),
                    children: [
                      TextSpan(text: "Switch."),
                      TextSpan(
                        text: "ify",
                        style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 80),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 30,
                mainAxisSpacing: 35,
                childAspectRatio: 1,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  StatusCard(icon: Icons.lightbulb, title: "Light", dbRef: lightRef),
                  StatusCard(icon: Icons.power, title: "Socket", dbRef: socketRef),
                  StatusCard(icon: Icons.water_drop, title: "Humidity", dbRef: humidityRef),
                  StatusCard(icon: Icons.thermostat, title: "Temperature", dbRef: temperatureRef),
                ],
              ),
            ),
            SizedBox(height: 80),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: ControlButton(type: 'light'),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 80,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: ControlButton(type: 'socket'),
                    ),
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

class StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final DatabaseReference dbRef; // Firebase reference

  StatusCard({required this.icon, required this.title, required this.dbRef});

  Color getCircleColor(String value) {
    if (title == "Light" || title == "Socket") {
      return value == "ON" ? Color(0xFFb2ff9e) : Color(0xFFf4978e);
    } else if (title == "Humidity") {
      double humidity = double.tryParse(value) ?? 0;
      if (humidity < 40) return Color(0xFFf4978e);
      if (humidity > 60) return Color(0xFFfcefb4);
      return Color(0xFFb2ff9e);
    } else if (title == "Temperature") {
      double temp = double.tryParse(value) ?? 0;
      if (temp < 25) return Color(0xFFa2d2ff);
      if (temp > 30) return Color(0xFFf4978e);
      return Color(0xFFb2ff9e);
    }
    return Colors.grey;
  }

  Color getIconColor(String value) {
    if (title == "Light" || title == "Socket") {
      return value == "ON" ? Color(0xFF72dc653) : Color(0xFFe5383b);
    } else if (title == "Humidity") {
      double humidity = double.tryParse(value) ?? 0;
      if (humidity < 40) return Color(0xFFe5383b);
      if (humidity > 60) return Color(0xFFffd400);
      return Color(0xFF72dc653);
    } else if (title == "Temperature") {
      double temp = double.tryParse(value) ?? 0;
      if (temp < 25) return Color(0xFF4361ee);
      if (temp > 30) return Color(0xFFe5383b);
      return Color(0xFF72dc653);
    }
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: dbRef.onValue, // Listen to Firebase changes
      builder: (context, snapshot) {
        String status = "Loading...";
        Color circleColor = Colors.grey;
        Color iconColor = Colors.black;

        if (snapshot.hasData && snapshot.data!.snapshot.exists) {
          status = snapshot.data!.snapshot.value.toString();
          circleColor = getCircleColor(status);
          iconColor = getIconColor(status);
        }

        return Container(
          padding: EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 7,
                offset: Offset(2, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              SizedBox(height: 10),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              SizedBox(height: 3),
              Text(status, style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }
}


class ControlButton extends StatefulWidget {
  final String type; // 'light' or 'socket'

  const ControlButton({Key? key, required this.type}) : super(key: key);

  @override
  _ControlButtonState createState() => _ControlButtonState();
}

class _ControlButtonState extends State<ControlButton> {
  bool isOn = false;
  late DatabaseReference _dbRef;

  @override
  void initState() {
    super.initState();

    // Determine the Firebase reference based on type
    _dbRef = FirebaseDatabase.instance.refFromURL(
        "https://smart-hub-13f70-default-rtdb.firebaseio.com/");

    if (widget.type == 'light') {
      _dbRef = _dbRef.child("switch/light/status");
    } else {
      _dbRef = _dbRef.child("switch/fan/status");
    }

    // Listen to Firebase for real-time updates
    _dbRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          isOn = event.snapshot.value == "ON"; // Assuming values in Firebase are "ON"/"OFF"
        });
      }
    });
  }

  void toggleState() {
    setState(() {
      isOn = !isOn;
    });

    // Update Firebase with new state
    _dbRef.set(isOn ? "ON" : "OFF");
  }

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor = Colors.white;
    String label;
    Color buttonColor = isOn ? Color(0xFF9d4edd) : Color(0xFFc77dff); // Updated colors

    if (widget.type == 'light') {
      icon = isOn ? Icons.lightbulb : Icons.lightbulb_outline;
      label = isOn ? 'Light On' : 'Light Off';
    } else {
      icon = isOn ? Icons.power : Icons.power_off;
      label = isOn ? 'Socket On' : 'Socket Off';
    }

    return ElevatedButton.icon(
      onPressed: toggleState,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor, // Apply dynamic color
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(icon, size: 24, color: iconColor),
      label: Text(
        label,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
