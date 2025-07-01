#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <Adafruit_INA219.h>
#include <time.h>
#include <ESP32Ping.h>

// WiFi credentials
const char* ssid = "IoT System";
const char* password = "01112003";

// MQTT over TLS (EMQX Cloud)
const char* mqtt_server = "i0bf1b65.ala.asia-southeast1.emqxsl.com";
const int mqtt_port = 8883;
const char* mqtt_user = "af07dd3c";                // App ID
const char* mqtt_pass = "U0ofxmA6rbhSp4_O";        // App Secret
const char* mqtt_client_id = "ESP32_Client";

// Root CA certificate (from `openssl s_client` or EMQX dashboard `chain.pem`)
const char* root_ca = R"EOF(
-----BEGIN CERTIFICATE-----
MIIGFzCCBP+gAwIBAgIQCzlnQyWUs9z9wmDbbJKxbTANBgkqhkiG9w0BAQsFADBu
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMS0wKwYDVQQDEyRFbmNyeXB0aW9uIEV2ZXJ5d2hlcmUg
RFYgVExTIENBIC0gRzEwHhcNMjQxMDE2MDAwMDAwWhcNMjUxMDE1MjM1OTU5WjAr
MSkwJwYDVQQDDCAqLmFsYS5hc2lhLXNvdXRoZWFzdDEuZW1xeHNsLmNvbTCCASIw
DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJbNPPCbZuBzKh0cX3pS353FzzY9
0bnqMq/fN44+gdZSCyZYBBRMSG96LFn8VeExIgHSaXxqp/d4A+4wViziyrpe3Nc6
MxTIAhBxa6fTkKC76s4lK8a6ybFwxTz+Q+utju0w0OwwItsblHTYREgzSwJcW0ie
rrn76mADXwx7edngoMziIggYGb716YRaHEzj7j3BPkVrPvSuzomTxDCPzSxU4/8v
UXzlyL+6OliLzU2iewrtpQ5tePE7pHRIWhrVyAw8KAbFD88yDRpEvuuNPRtlliB5
CZrPzgzzNEJtmhEOQOABqXHRIBONNQRdWr+cwilR2PWfQs0dLgcR0WVimr0CAwEA
AaOCAvIwggLuMB8GA1UdIwQYMBaAFFV0T7JyT/VgulDR1+ZRXJoBhxrXMB0GA1Ud
DgQWBBQB8aslZ14UD1ppHJWVYYkNyERgMDArBgNVHREEJDAigiAqLmFsYS5hc2lh
LXNvdXRoZWFzdDEuZW1xeHNsLmNvbTA+BgNVHSAENzA1MDMGBmeBDAECATApMCcG
CCsGAQUFBwIBFhtodHRwOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwDgYDVR0PAQH/
BAQDAgWgMB0GA1UdJQQWMBQGCCsGAQUFBwMBBggrBgEFBQcDAjCBgAYIKwYBBQUH
AQEEdDByMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wSgYI
KwYBBQUHMAKGPmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9FbmNyeXB0aW9u
RXZlcnl3aGVyZURWVExTQ0EtRzEuY3J0MAwGA1UdEwEB/wQCMAAwggF9BgorBgEE
AdZ5AgQCBIIBbQSCAWkBZwB1ABLxTjS9U3JMhAYZw48/ehP457Vih4icbTAFhOvl
hiY6AAABkpR7DJAAAAQDAEYwRAIgOSOQLk2NDbQSiaT2HYGufCOgcUOqjgYoqwy/
qsTuNeECIFAUMfLQuob4cbaHNgtKe5VK3DoQsaS5AEqHbSYYoOkgAHYAfVkeEuF4
KnscYWd8Xv340IdcFKBOlZ65Ay/ZDowuebgAAAGSlHsMUgAABAMARzBFAiB+jgqO
Ou8wPxgNVe608/7eY7SriDRxB2gBEKWUTwiFGwIhAK32ko1rVHLcLartbDZJ40os
1JxAMOy0BwHoQf4dk4+LAHYA5tIxY0B3jMEQQQbXcbnOwdJA9paEhvu6hzId/R43
jlAAAAGSlHsMVwAABAMARzBFAiEAh9euTmXv0ENZcx9/qE4j1r6D+W3TIk1GJzAW
gcRkLPUCIBLJ/pDwFis8smhMgxxemUSRfeb+jtYXKZdvBWHxXhcQMA0GCSqGSIb3
DQEBCwUAA4IBAQCwuo2NgaONkSbtmjGhgW0xjfc6QboJGwKxAWeRRmFQQ4qL9DAy
vAKmJKrV9A4LQpBEqEpmT8Z8zab07qbC1aknnGjjjLOerR8QipwvJ5mqLhDQiII/
eTG/z0edW/Mjn5H7ICBCVsWxIYbSsKctGKNxrLqXxBbi7Ri+UuYeuyDlrR9uByBR
JPgjXC/yncjOwF+CXh5+p6O3VY/sZdAyfKnYVD9GzCJzB9zlb4+K5ILrsB0G4h4t
4jlOPPtFKF81Et8zeYMAz80swh20dBpnW17BGOnImwOjSS4tWxg+Yndt15mv2OzX
WYp+G+xOvUe8a7hrA6/L/mVO+Z6gUxbBAnmu
-----END CERTIFICATE-----
)EOF"; 

// Define pins and topics
#define DHT_PIN 23
#define DHT_TYPE DHT11
#define LED1_PIN 18
#define LED2_PIN 19
#define MOTOR_FORWARD_PIN 26
#define MOTOR_REVERSE_PIN 27

#define TOPIC_TEMP     "khoasmarthome/temperature"
#define TOPIC_HUMID    "khoasmarthome/humidity"
#define TOPIC_CURRENT  "khoasmarthome/current"
#define TOPIC_VOLTAGE  "khoasmarthome/voltage"
#define TOPIC_POWER    "khoasmarthome/power"
#define TOPIC_LED1     "khoasmarthome/led1"
#define TOPIC_LED2     "khoasmarthome/led2"
#define TOPIC_MOTOR    "khoasmarthome/motor"

DHT dht(DHT_PIN, DHT_TYPE);
Adafruit_INA219 ina219;
WiFiClientSecure espClient;
PubSubClient client(espClient);
unsigned long lastMsg = 0;
#define MSG_INTERVAL 5000

void setup_wifi() {
  WiFi.begin(ssid, password);
  Serial.print("🔌 Connecting to WiFi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n✅ WiFi connected");
  Serial.println("IP: " + WiFi.localIP().toString());
}

void syncTime() {
  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov");
  Serial.print("⏳ Syncing time");
  while (time(nullptr) < 1700000000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\n⏰ Time synced");
}

void checkPing() {
  if (Ping.ping(mqtt_server)) {
    Serial.println("✅ Ping MQTT Broker OK");
  } else {
    Serial.println("❌ Ping failed");
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (unsigned int i = 0; i < length; i++) message += (char)payload[i];
  Serial.printf("📩 Message [%s]: %s\n", topic, message.c_str());

  if (String(topic) == TOPIC_LED1)
    digitalWrite(LED1_PIN, message == "ON" ? HIGH : LOW);
  else if (String(topic) == TOPIC_LED2)
    digitalWrite(LED2_PIN, message == "ON" ? HIGH : LOW);
  else if (String(topic) == TOPIC_MOTOR)
    Serial.printf("⚙️  Motor command: %s (simulated)\n", message.c_str());
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("🔁 Attempting MQTT connection...");
    if (client.connect(mqtt_client_id, mqtt_user, mqtt_pass)) {
      Serial.println("✅ connected");
      client.subscribe(TOPIC_LED1);
      client.subscribe(TOPIC_LED2);
      client.subscribe(TOPIC_MOTOR);
    } else {
      Serial.printf("❌ failed, rc=%d, retrying in 5s\n", client.state());
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(LED1_PIN, OUTPUT);
  pinMode(LED2_PIN, OUTPUT);
  pinMode(MOTOR_FORWARD_PIN, OUTPUT);
  pinMode(MOTOR_REVERSE_PIN, OUTPUT);

  dht.begin();
  ina219.begin();

  setup_wifi();
  syncTime();
  checkPing();

  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
}

void loop() {
  if (!client.connected()) reconnect();
  client.loop();

  unsigned long now = millis();
  if (now - lastMsg > MSG_INTERVAL) {
    lastMsg = now;

    float h = dht.readHumidity();
    float t = dht.readTemperature();
    if (!isnan(h) && !isnan(t)) {
      client.publish(TOPIC_TEMP, String(t, 1).c_str());
      client.publish(TOPIC_HUMID, String(h, 1).c_str());
      Serial.printf("🌡️ Temp: %.1f°C, 💧 Hum: %.1f%%\n", t, h);
    }

    float busV = ina219.getBusVoltage_V();
    float current = ina219.getCurrent_mA();
    float power = ina219.getPower_mW();
    client.publish(TOPIC_VOLTAGE, String(busV, 2).c_str());
    client.publish(TOPIC_CURRENT, String(current, 2).c_str());
    client.publish(TOPIC_POWER, String(power, 2).c_str());
    Serial.printf("🔋 V: %.2fV, I: %.2fmA, P: %.2fmW\n", busV, current, power);
  }
}
