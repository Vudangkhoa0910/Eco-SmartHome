#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <Adafruit_INA219.h>
#include <Wire.h>
#include <time.h>
#include <ESPping.h>
#include <ESP32Servo.h>

// WiFi credentials
const char* ssid = "iPhone (85)";
const char* password = "1234567899";

// MQTT over TLS (EMQX Cloud)
const char* mqtt_server = "i0bf1b65.ala.asia-southeast1.emqxsl.com";
const int mqtt_port = 8883;
const char* mqtt_user = "af07dd3c";
const char* mqtt_pass = "U0ofxmA6rbhSp4_O";
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

// Cấu hình chân kết nối
#define DHT_PIN 23
#define DHT_TYPE DHT11

// Motor cổng (giữ nguyên)
#define MOTOR_FORWARD_PIN 26
#define MOTOR_REVERSE_PIN 27

// LED hiện tại (giữ nguyên)
#define LED_GATE_PIN 14
#define LED_AROUND_PIN 13

// Servo mái che
#define SERVO_AWNING_PIN 25
Servo servoAwning;
bool awningOpen = false;

// Đèn sân và khu vực ngoài
#define LED_YARD_MAIN_PIN 12        // Đèn sân chính
#define LED_FISH_POND_PIN 15        // Đèn khu bể cá  
#define LED_AWNING_AREA_PIN 2       // Đèn mái hiên

// Đèn trong nhà
#define LED_LIVING_ROOM_PIN 4       // Đèn phòng khách
#define LED_KITCHEN_PIN 16          // Đèn phòng bếp
#define LED_BEDROOM_PIN 17          // Đèn phòng ngủ
#define LED_STAIRS_PIN 5            // Đèn cầu thang
#define LED_BATHROOM_PIN 18         // Đèn vệ sinh

// Topic MQTT
#define TOPIC_TEMP        "khoasmarthome/temperature"
#define TOPIC_HUMID       "khoasmarthome/humidity"
#define TOPIC_CURRENT     "khoasmarthome/current"
#define TOPIC_VOLTAGE     "khoasmarthome/voltage"
#define TOPIC_POWER       "khoasmarthome/power"

// Điều khiển cổng và đèn cổng (giữ nguyên)
#define TOPIC_LED_GATE    "khoasmarthome/led_gate"
#define TOPIC_LED_AROUND  "khoasmarthome/led_around"
#define TOPIC_MOTOR       "khoasmarthome/motor"

// Điều khiển mái che và đèn sân
#define TOPIC_AWNING      "khoasmarthome/awning"
#define TOPIC_YARD_MAIN   "khoasmarthome/yard_main_light"
#define TOPIC_FISH_POND   "khoasmarthome/fish_pond_light"
#define TOPIC_AWNING_LIGHT "khoasmarthome/awning_light"

// Điều khiển đèn trong nhà
#define TOPIC_LIVING_ROOM "khoasmarthome/living_room_light"
#define TOPIC_KITCHEN     "khoasmarthome/kitchen_light"
#define TOPIC_BEDROOM     "khoasmarthome/bedroom_light"
#define TOPIC_STAIRS      "khoasmarthome/stairs_light"
#define TOPIC_BATHROOM    "khoasmarthome/bathroom_light"

DHT dht(DHT_PIN, DHT_TYPE);
Adafruit_INA219 ina219;
WiFiClientSecure espClient;
PubSubClient client(espClient);

unsigned long lastMsg = 0;
#define MSG_INTERVAL 5000

// Điều khiển motor - tăng thời gian chạy lên 7 giây
unsigned long motorRunTime = 7000;  // Tăng từ 5000ms lên 7000ms
bool motorRunning = false;
unsigned long motorStartTime = 0;
int motorState = 0; // 0 = dừng, 1 = tiến, 2 = lùi

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

  // Điều khiển LED cổng và xung quanh (giữ nguyên)
  if (String(topic) == TOPIC_LED_GATE)
    digitalWrite(LED_GATE_PIN, message == "ON" ? HIGH : LOW);
  else if (String(topic) == TOPIC_LED_AROUND) {
    // Nếu rơ le active LOW: khi GPIO xuống LOW thì rơ le đóng, đèn sáng
    // Nếu rơ le active HIGH: khi GPIO lên HIGH thì rơ le đóng, đèn sáng
    // Đa số module rơ le 1 kênh dùng opto sẽ active LOW
    digitalWrite(LED_AROUND_PIN, message == "ON" ? LOW : HIGH);
  }
  // Điều khiển motor cổng (giữ nguyên logic)
  else if (String(topic) == TOPIC_MOTOR && !motorRunning) {
    if (motorState == 0 || motorState == 2) {
      digitalWrite(MOTOR_FORWARD_PIN, HIGH);
      digitalWrite(MOTOR_REVERSE_PIN, LOW);
      motorState = 1;
    } else {
      digitalWrite(MOTOR_FORWARD_PIN, LOW);
      digitalWrite(MOTOR_REVERSE_PIN, HIGH);
      motorState = 2;
    }
    motorStartTime = millis();
    motorRunning = true;
    Serial.printf("⚙️ Motor running: %s\n", motorState == 1 ? "FORWARD" : "REVERSE");
  }
  
  // Điều khiển mái che bằng servo
  else if (String(topic) == TOPIC_AWNING) {
    if (message == "ON" && !awningOpen) {
      servoAwning.write(90);  // Mở mái che
      awningOpen = true;
      Serial.println("🏠 Awning opened");
    } else if (message == "OFF" && awningOpen) {
      servoAwning.write(0);   // Đóng mái che
      awningOpen = false;
      Serial.println("🏠 Awning closed");
    }
  }
  
  // Điều khiển đèn sân chính
  else if (String(topic) == TOPIC_YARD_MAIN)
    digitalWrite(LED_YARD_MAIN_PIN, message == "ON" ? HIGH : LOW);
    
  // Điều khiển đèn khu bể cá
  else if (String(topic) == TOPIC_FISH_POND)
    digitalWrite(LED_FISH_POND_PIN, message == "ON" ? HIGH : LOW);
    
  // Điều khiển đèn mái hiên
  else if (String(topic) == TOPIC_AWNING_LIGHT)
    digitalWrite(LED_AWNING_AREA_PIN, message == "ON" ? HIGH : LOW);
    
  // Điều khiển đèn trong nhà
  else if (String(topic) == TOPIC_LIVING_ROOM)
    digitalWrite(LED_LIVING_ROOM_PIN, message == "ON" ? HIGH : LOW);
  else if (String(topic) == TOPIC_KITCHEN)
    digitalWrite(LED_KITCHEN_PIN, message == "ON" ? HIGH : LOW);
  else if (String(topic) == TOPIC_BEDROOM)
    digitalWrite(LED_BEDROOM_PIN, message == "ON" ? HIGH : LOW);
  else if (String(topic) == TOPIC_STAIRS)
    digitalWrite(LED_STAIRS_PIN, message == "ON" ? HIGH : LOW);
  else if (String(topic) == TOPIC_BATHROOM)
    digitalWrite(LED_BATHROOM_PIN, message == "ON" ? HIGH : LOW);
}

void reconnect() {
  while (!client.connected()) {
    Serial.print("🔁 Attempting MQTT connection...");
    if (client.connect(mqtt_client_id, mqtt_user, mqtt_pass)) {
      Serial.println("✅ connected");
      
      // Subscribe to existing topics (giữ nguyên)
      client.subscribe(TOPIC_LED_GATE);
      client.subscribe(TOPIC_LED_AROUND);
      client.subscribe(TOPIC_MOTOR);
      
      // Subscribe to new topics
      client.subscribe(TOPIC_AWNING);
      client.subscribe(TOPIC_YARD_MAIN);
      client.subscribe(TOPIC_FISH_POND);
      client.subscribe(TOPIC_AWNING_LIGHT);
      client.subscribe(TOPIC_LIVING_ROOM);
      client.subscribe(TOPIC_KITCHEN);
      client.subscribe(TOPIC_BEDROOM);
      client.subscribe(TOPIC_STAIRS);
      client.subscribe(TOPIC_BATHROOM);
      
    } else {
      Serial.printf("❌ failed, rc=%d, retrying in 5s\n", client.state());
      delay(5000);
    }
  }
}

void setup() {
  Serial.begin(115200);

  // Cấu hình chân LED và motor (giữ nguyên)
  pinMode(LED_GATE_PIN, OUTPUT);
  pinMode(LED_AROUND_PIN, OUTPUT);
  pinMode(MOTOR_FORWARD_PIN, OUTPUT);
  pinMode(MOTOR_REVERSE_PIN, OUTPUT);

  // Đảm bảo rơ le tắt ban đầu
  digitalWrite(LED_AROUND_PIN, HIGH); // Nếu active LOW, HIGH là tắt

  // Cấu hình servo mái che
  servoAwning.attach(SERVO_AWNING_PIN);
  servoAwning.write(0); // Đóng mái che ban đầu

  // Cấu hình đèn sân và khu vực ngoài
  pinMode(LED_YARD_MAIN_PIN, OUTPUT);
  pinMode(LED_FISH_POND_PIN, OUTPUT);
  pinMode(LED_AWNING_AREA_PIN, OUTPUT);

  // Cấu hình đèn trong nhà
  pinMode(LED_LIVING_ROOM_PIN, OUTPUT);
  pinMode(LED_KITCHEN_PIN, OUTPUT);
  pinMode(LED_BEDROOM_PIN, OUTPUT);
  pinMode(LED_STAIRS_PIN, OUTPUT);
  pinMode(LED_BATHROOM_PIN, OUTPUT);

  // Tắt tất cả đèn ban đầu
  digitalWrite(LED_GATE_PIN, LOW);
  digitalWrite(LED_AROUND_PIN, LOW);
  digitalWrite(LED_YARD_MAIN_PIN, LOW);
  digitalWrite(LED_FISH_POND_PIN, LOW);
  digitalWrite(LED_AWNING_AREA_PIN, LOW);
  digitalWrite(LED_LIVING_ROOM_PIN, LOW);
  digitalWrite(LED_KITCHEN_PIN, LOW);
  digitalWrite(LED_BEDROOM_PIN, LOW);
  digitalWrite(LED_STAIRS_PIN, LOW);
  digitalWrite(LED_BATHROOM_PIN, LOW);

  // Cấu hình cảm biến (giữ nguyên)
  Wire.begin(32, 33);  // INA219 SDA, SCL
  ina219.begin();
  dht.begin();

  setup_wifi();
  syncTime();
  checkPing();

  espClient.setInsecure();  // chỉ dùng cho thử nghiệm, bỏ nếu dùng root_ca
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);
  
  Serial.println("🎯 Smart Home System Ready!");
  Serial.println("📋 Available devices:");
  Serial.println("   🚪 Gate Motor (7s runtime)");
  Serial.println("   💡 LED Gate & Around");
  Serial.println("   🏠 Servo Awning");
  Serial.println("   🌿 Yard & Fish Pond Lights");
  Serial.println("   🏘️ Indoor Lights (5 rooms)");
}

void loop() {
  if (!client.connected()) reconnect();
  client.loop();

  unsigned long now = millis();

  // Tắt motor sau 7 giây (tăng từ 5 giây)
  if (motorRunning && now - motorStartTime > motorRunTime) {
    digitalWrite(MOTOR_FORWARD_PIN, LOW);
    digitalWrite(MOTOR_REVERSE_PIN, LOW);
    motorRunning = false;
    Serial.println("⛔ Motor stopped (7s runtime)");
  }

  // Gửi dữ liệu cảm biến định kỳ (giữ nguyên)
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