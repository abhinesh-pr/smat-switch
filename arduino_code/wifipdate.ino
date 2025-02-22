#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include "addons/TokenHelper.h"
#include "addons/RTDBHelper.h"
#include <DHT.h>

// WiFi Credentials
#define WIFI_SSID "iQOO Z5"
#define WIFI_PASSWORD "Abhi@Pragz"

// Firebase Configuration
#define DATABASE_URL "https://smart-hub-13f70-default-rtdb.firebaseio.com"
#define API_KEY "AIzaSyDM-Plif3Uhm0L4Hh6FyDoLIfeP48u8Hxs"

FirebaseConfig config;
FirebaseAuth auth;
FirebaseData fbdo;

// Pin Definitions
#define SWITCH_PIN1 25   // Physical switch for Fan (Input)
#define RELAY_PIN1 14    // Relay for Fan (Output)
#define SWITCH_PIN2 26   // Physical switch for Light (Input)
#define RELAY_PIN2 27    // Relay for Light (Output)

// DHT11 Configuration
#define DHTPIN 4
#define DHTTYPE DHT11
DHT dht(DHTPIN, DHTTYPE);

bool lastSwitchState1 = false;
bool lastFirebaseState1 = false;
bool lastSwitchState2 = false;
bool lastFirebaseState2 = false;

void setup() {
    Serial.begin(115200);

    // Initialize Pins
    pinMode(SWITCH_PIN1, INPUT_PULLUP);
    pinMode(RELAY_PIN1, OUTPUT);
    digitalWrite(RELAY_PIN1, HIGH); // Start with relay OFF

    pinMode(SWITCH_PIN2, INPUT_PULLUP);
    pinMode(RELAY_PIN2, OUTPUT);
    digitalWrite(RELAY_PIN2, HIGH); // Start with relay OFF

    dht.begin(); // Initialize DHT sensor

    // Connect to Wi-Fi
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    Serial.print("Connecting to Wi-Fi");
    while (WiFi.status() != WL_CONNECTED) {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nConnected to Wi-Fi");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    // Firebase Configuration
    config.database_url = DATABASE_URL;
    config.api_key = API_KEY;
    auth.user.email = "abhinesh436@gmail.com";
    auth.user.password = "Qwerty@12345";

    config.token_status_callback = tokenStatusCallback;

    // Initialize Firebase
    Firebase.begin(&config, &auth);
    Firebase.reconnectWiFi(true);
}

void loop() {
    // Read physical switch states
    bool switchState1 = digitalRead(SWITCH_PIN1) == LOW;  // Active LOW
    bool switchState2 = digitalRead(SWITCH_PIN2) == LOW;  // Active LOW

    // Read Firebase states
    bool firebaseState1 = lastFirebaseState1;
    bool firebaseState2 = lastFirebaseState2;

    if (Firebase.RTDB.getString(&fbdo, "/switch/fan/status")) {
        firebaseState1 = (fbdo.stringData() == "ON");
    } else {
        Serial.print("Error reading Firebase Fan: ");
        Serial.println(fbdo.errorReason());
    }

    if (Firebase.RTDB.getString(&fbdo, "/switch/light/status")) {
        firebaseState2 = (fbdo.stringData() == "ON");
    } else {
        Serial.print("Error reading Firebase Light: ");
        Serial.println(fbdo.errorReason());
    }

    // Control Fan Relay via Switch
    if (switchState1 != lastSwitchState1) {
        lastSwitchState1 = switchState1;
        firebaseState1 = switchState1;

        Firebase.RTDB.setString(&fbdo, "/switch/fan/status", switchState1 ? "ON" : "OFF");
        Serial.println(switchState1 ? "Fan ON (Switch Toggled)" : "Fan OFF (Switch Toggled)");
    }

    // Control Light Relay via Switch
    if (switchState2 != lastSwitchState2) {
        lastSwitchState2 = switchState2;
        firebaseState2 = switchState2;

        Firebase.RTDB.setString(&fbdo, "/switch/light/status", switchState2 ? "ON" : "OFF");
        Serial.println(switchState2 ? "Light ON (Switch Toggled)" : "Light OFF (Switch Toggled)");
    }

    // Control Fan Relay via Firebase
    if (firebaseState1 != lastFirebaseState1) {
        lastFirebaseState1 = firebaseState1;
        digitalWrite(RELAY_PIN1, firebaseState1 ? LOW : HIGH);
        Serial.println(firebaseState1 ? "Fan ON (Firebase Update)" : "Fan OFF (Firebase Update)");
    }

    // Control Light Relay via Firebase
    if (firebaseState2 != lastFirebaseState2) {
        lastFirebaseState2 = firebaseState2;
        digitalWrite(RELAY_PIN2, firebaseState2 ? LOW : HIGH);
        Serial.println(firebaseState2 ? "Light ON (Firebase Update)" : "Light OFF (Firebase Update)");
    }

    // Read Temperature and Humidity from DHT11
    float temperature = dht.readTemperature();
    float humidity = dht.readHumidity();

    if (!isnan(temperature) && !isnan(humidity)) {
        Serial.print("Temperature: ");
        Serial.print(temperature);
        Serial.print("°C  |  Humidity: ");
        Serial.print(humidity);
        Serial.println("%");
    } else {
        Serial.println("Failed to read from DHT sensor!");
    }

    delay(2000); // Delay for stability
}
