#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <DHT.h>
#include <Adafruit_INA219.h>
#include <Wire.h>
#include <time.h>
#include <ESPping.h>
#include <ESP32Servo.h>
#include <U8g2lib.h>

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

// I2C Device Addresses
#define OLED_ADDRESS 0x3C
#define INA219_ADDRESS 0x40

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

// Điều khiển cổng và đèn cổng - BỔ SUNG MQTT CHO ĐA MỨC ĐỘ
#define TOPIC_LED_GATE    "khoasmarthome/led_gate"
#define TOPIC_LED_AROUND  "khoasmarthome/led_around"
// Status reporting topics
#define TOPIC_LED_GATE_STATUS    "khoasmarthome/led_gate/status"
#define TOPIC_LED_AROUND_STATUS  "khoasmarthome/led_around/status"
#define TOPIC_DEVICE_STATUS      "khoasmarthome/device_status"
#define TOPIC_MOTOR       "khoasmarthome/motor"
#define TOPIC_GATE_LEVEL  "khoasmarthome/gate_level"     // Topic mới cho điều khiển mức độ
#define TOPIC_GATE_STATUS "khoasmarthome/gate_status"    // Topic báo trạng thái

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
Adafruit_INA219 ina219(INA219_ADDRESS);  // Khởi tạo với địa chỉ I2C
WiFiClientSecure espClient;
PubSubClient client(espClient);

// OLED Display 1.3 inch (128x64) - Sử dụng địa chỉ 0x3C
U8G2_SSD1306_128X64_NONAME_F_HW_I2C u8g2(U8G2_R0, /* reset=*/ U8X8_PIN_NONE);
bool oledFound = false;

unsigned long lastMsg = 0;
#define MSG_INTERVAL 5000

// Current device states - for persistence and reporting
bool ledGateState = false;    // true = ON, false = OFF
bool ledAroundState = false;
// Add more device states as needed for other devices

// Điều khiển motor cổng - CẢI TIẾN 25% INTERVALS
unsigned long motorRunTime = 7000;  // Thời gian mở hoàn toàn (0→100%)
bool motorRunning = false;
unsigned long motorStartTime = 0;
int motorState = 0; // 0 = dừng, 1 = tiến, 2 = lùi
int gateLevel = 0;  // 0 = đóng (0%), 1 = 25%, 2 = 50%, 3 = 75%, 4 = 100%
int targetGateLevel = 0; // Target level để track trong motor operation

// Failsafe - Maximum motor runtime to prevent damage
const unsigned long MAX_MOTOR_RUNTIME = 7000;  // 7 seconds absolute maximum

// Thời gian tích lũy cho từng mức độ mở cổng (0-100% trong 7 giây)
unsigned long gateLevelTimes[5] = {
  0,     // 0% = 0ms
  1750,  // 25% = 1.75s 
  3500,  // 50% = 3.5s
  5250,  // 75% = 5.25s  
  7000   // 100% = 7s
};

// I2C Scanner để kiểm tra thiết bị
void scanI2C() {
  Serial.println("🔍 Scanning I2C devices...");
  int deviceCount = 0;
  
  for (byte address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    byte error = Wire.endTransmission();
    
    if (error == 0) {
      Serial.printf("✅ I2C device found at 0x%02X\n", address);
      deviceCount++;
      
      if (address == OLED_ADDRESS) {
        Serial.println("   -> OLED Display detected");
      } else if (address == INA219_ADDRESS) {
        Serial.println("   -> INA219 Power Monitor detected");
      }
    }
  }
  
  if (deviceCount == 0) {
    Serial.println("❌ No I2C devices found");
  } else {
    Serial.printf("📡 Total I2C devices found: %d\n", deviceCount);
  }
  Serial.println();
}

// Khởi tạo OLED an toàn
bool initOLED() {
  Serial.println("🖥️ Initializing OLED...");
  
  // Kiểm tra OLED có tồn tại không
  Wire.beginTransmission(OLED_ADDRESS);
  byte error = Wire.endTransmission();
  
  if (error != 0) {
    Serial.printf("❌ OLED not found at 0x%02X\n", OLED_ADDRESS);
    return false;
  }
  
  // Khởi tạo OLED
  if (!u8g2.begin()) {
    Serial.println("❌ OLED initialization failed");
    return false;
  }
  
  Serial.println("✅ OLED initialized successfully");
  
  // Hiển thị màn hình khởi động
  u8g2.clearBuffer();
  u8g2.setFont(u8g2_font_ncenB10_tr);
  u8g2.drawStr(20, 35, "SMART HOME");
  u8g2.setFont(u8g2_font_6x10_tr);
  u8g2.drawStr(30, 50, "Starting...");
  u8g2.sendBuffer();
  
  return true;
}

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
  // 🚨 TEMPORARILY DISABLED - Ping function causing hangs
  Serial.println("⚠️ Ping check disabled to prevent ESP32 hang");
  Serial.println("🔧 MQTT connection will be tested directly");
  /*
  if (Ping.ping(mqtt_server)) {
    Serial.println("✅ Ping MQTT Broker OK");
  } else {
    Serial.println("❌ Ping failed");
  }
  */
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (unsigned int i = 0; i < length; i++) message += (char)payload[i];
  
  // 🚨 ENHANCED DEBUG - Always print received messages
  Serial.printf("� MQTT RECEIVED [%s]: %s (length: %d)\n", topic, message.c_str(), length);
  Serial.printf("🔥 Current time: %lu ms\n", millis());

  // Điều khiển cổng và đèn cổng - BỔ SUNG MQTT CHO ĐA MỨC ĐỘ
  if (String(topic) == TOPIC_LED_GATE) {
    // Rơ le active LOW: GPIO LOW = relay ON = đèn sáng
    bool newState = (message == "ON");
    digitalWrite(LED_GATE_PIN, newState ? LOW : HIGH);
    ledGateState = newState;  // Update state tracking
    
    Serial.printf("💡 LED Gate set to %s (GPIO: %s)\n", 
                  message.c_str(), 
                  (newState ? "LOW" : "HIGH"));
    
    // Report status back to MQTT
    publishDeviceStatus("led_gate", newState);
  }
  else if (String(topic) == TOPIC_LED_AROUND) {
    // FIXED: Rơ le active LOW nhưng logic ngược - ON = tắt đèn, OFF = mở đèn
    bool newState = (message == "ON");
    // Đảo logic: ON -> HIGH (tắt đèn), OFF -> LOW (mở đèn)
    digitalWrite(LED_AROUND_PIN, newState ? HIGH : LOW);
    ledAroundState = newState;  // Update state tracking
    
    Serial.printf("💡 LED Around set to %s (GPIO: %s) - %s\n", 
                  message.c_str(), 
                  (newState ? "HIGH" : "LOW"),
                  (newState ? "TẮT" : "MỞ"));
    
    // Report status back to MQTT
    publishDeviceStatus("led_around", newState);
  }
  // Điều khiển motor cổng - CẢI TIẾN ĐA MỨC ĐỘ với DIRECTION
  else if (String(topic) == TOPIC_GATE_LEVEL && !motorRunning) {
    // Handle STOP command
    if (message == "STOP") {
      Serial.printf("🛑 STOP command received - motor already stopped\n");
      return;
    }
    
    // Parse enhanced message format: "targetLevel|direction|command"
    // Example: "25|closing|OPEN_TO_25" or simple: "50"
    int targetLevel;
    String direction = "";
    String command = "";
    
    if (message.indexOf('|') > 0) {
      // Enhanced format: "targetLevel|direction|command"
      int firstPipe = message.indexOf('|');
      int secondPipe = message.indexOf('|', firstPipe + 1);
      
      String levelStr = message.substring(0, firstPipe);
      direction = message.substring(firstPipe + 1, secondPipe);
      command = message.substring(secondPipe + 1);
      
      int inputValue = levelStr.toInt();
      
      // Convert percentage to ESP32 level (0-100% -> 0-4 levels)
      if (inputValue >= 0 && inputValue <= 100) {
        if (inputValue == 0) targetLevel = 0;        // 0% = CLOSED
        else if (inputValue <= 25) targetLevel = 1;  // 1-25% = LEVEL_25
        else if (inputValue <= 50) targetLevel = 2;  // 26-50% = LEVEL_50  
        else if (inputValue <= 75) targetLevel = 3;  // 51-75% = LEVEL_75
        else targetLevel = 4;                        // 76-100% = LEVEL_100
        
        Serial.printf("📨 Enhanced MQTT: %d%% -> level=%d, direction=%s, cmd=%s\n", 
                      inputValue, targetLevel, direction.c_str(), command.c_str());
      } else {
        Serial.printf("❌ Invalid enhanced input: %s\n", message.c_str());
        return;
      }
    } else {
      // Legacy format: simple number
      int inputValue = message.toInt();
      
      // Convert percentage to level (0-100% -> 0-4 levels)
      if (inputValue >= 0 && inputValue <= 100) {
        if (inputValue == 0) targetLevel = 0;        // 0% = CLOSED
        else if (inputValue <= 25) targetLevel = 1;  // 1-25% = LEVEL_25
        else if (inputValue <= 50) targetLevel = 2;  // 26-50% = LEVEL_50
        else if (inputValue <= 75) targetLevel = 3;  // 51-75% = LEVEL_75
        else targetLevel = 4;                        // 76-100% = LEVEL_100
        
        Serial.printf("📨 Legacy MQTT: percentage=%d%% -> level=%d (current=%d)\n", 
                      inputValue, targetLevel, gateLevel);
      }
      // Direct level input (0-4)
      else if (inputValue >= 0 && inputValue <= 4) {
        targetLevel = inputValue;
        Serial.printf("📨 Legacy MQTT: level=%d (current=%d)\n", 
                      targetLevel, gateLevel);
      }
      else {
        Serial.printf("❌ Invalid input value: %d - must be 0-100%% or 0-4 level\n", inputValue);
        return;
      }
    }
    
    if (targetLevel != gateLevel) {
      Serial.printf("🚀 Motor starting: level %d -> %d (direction: %s)\n", 
                    gateLevel, targetLevel, direction.c_str());
      controlGateToLevel(targetLevel);
    } else {
      Serial.printf("ℹ️ Gate already at level %d - no action needed\n", targetLevel);
    }
  } else if (String(topic) == TOPIC_GATE_LEVEL && motorRunning) {
    // Allow STOP command even when motor is running
    if (message == "STOP" || message.indexOf("STOP") >= 0) {
      Serial.printf("🛑 EMERGENCY STOP received - stopping motor immediately\n");
      // Stop motor immediately
      digitalWrite(MOTOR_FORWARD_PIN, LOW);
      digitalWrite(MOTOR_REVERSE_PIN, LOW);
      motorRunning = false;
      motorState = 0;
      
      // ✅ Emergency stop - keep current gateLevel (don't update to target)
      // gateLevel stays as-is
      
      // Publish current status
      publishGateStatus();
      Serial.printf("⏹️ Motor emergency stopped at level %d\n", gateLevel);
    } else {
      Serial.printf("⚠️ Gate control ignored - motor already running (use STOP to halt)\n");
      Serial.printf("🔧 Current motor state: level %d->%d, elapsed %lu ms\n", 
                    gateLevel, targetGateLevel, millis() - motorStartTime);
    }
  }
  // Handle status request
  else if (String(topic) == "khoasmarthome/status_request") {
    if (message == "GATE_STATUS") {
      publishGateStatus(); // Send current gate status immediately
    } else if (message == "ALL_DEVICES") {
      publishAllDeviceStatus(); // Send all device status
    } else if (message == "LED_GATE") {
      publishDeviceStatus("led_gate", ledGateState);
    } else if (message == "LED_AROUND") {
      publishDeviceStatus("led_around", ledAroundState);
    }
  }
  // Logic cũ cho tương thích ngược - DISABLED để tránh xung đột với gate_level
  else if (String(topic) == TOPIC_MOTOR && !motorRunning) {
    Serial.printf("⚠️ Legacy TOPIC_MOTOR received: %s - IGNORED (use gate_level instead)\n", message.c_str());
    Serial.printf("💡 Please use topic '%s' with percentage values (0-100)\n", TOPIC_GATE_LEVEL);
    // Comment out để disable legacy logic
    /*
    if (message == "CLOSE" || message == "0") {
      Serial.printf("🔒 Motor command: CLOSE\n");
      controlGateToLevel(0); // Đóng hoàn toàn (0%)
    }
    else if (message == "PEDESTRIAN" || message == "1") {
      Serial.printf("🚶 Motor command: PEDESTRIAN (25%)\n");
      controlGateToLevel(1); // Mở cho người đi bộ (25%)
    }
    else if (message == "MOTORBIKE" || message == "2") {
      Serial.printf("🏍️ Motor command: MOTORBIKE (50%)\n");
      controlGateToLevel(2); // Mở cho xe máy (50%)
    }
    else if (message == "CAR" || message == "3") {
      Serial.printf("🚗 Motor command: CAR (75%)\n");
      controlGateToLevel(3); // Mở cho xe hơi (75%)
    }
    else if (message == "TRUCK" || message == "4") {
      Serial.printf("🚛 Motor command: TRUCK FULL (100%)\n");
      controlGateToLevel(4); // Mở hoàn toàn (100%)
    }
    else {
      Serial.printf("❌ Unknown motor command: %s\n", message.c_str());
    }
    */
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
      Serial.printf("🔥 MQTT CLIENT ID: %s\n", mqtt_client_id);
      Serial.printf("🔥 MQTT BROKER: %s:%d\n", mqtt_server, mqtt_port);
      
      // Subscribe to existing topics (giữ nguyên)
      client.subscribe(TOPIC_LED_GATE);
      client.subscribe(TOPIC_LED_AROUND);
      client.subscribe(TOPIC_MOTOR);
      client.subscribe(TOPIC_GATE_LEVEL);   // Subscribe topic mới
      client.subscribe("khoasmarthome/status_request"); // Subscribe status request
      
      // 🚨 ENHANCED DEBUG - Confirm subscriptions
      Serial.printf("🔥 SUBSCRIBED TO GATE_LEVEL: %s\n", TOPIC_GATE_LEVEL);
      Serial.printf("🔥 SUBSCRIBED TO GATE_STATUS: %s\n", TOPIC_GATE_STATUS);
      
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
      
      // 🚨 IMMEDIATE STATUS PUBLISH for debugging
      Serial.println("🔥 Publishing initial device status...");
      publishAllDeviceStatus();
      
      // 🚨 EXPLICIT GATE STATUS - Send gate closed state immediately
      delay(200);
      publishGateStatus();
      Serial.println("✅ MQTT connected - Initial gate status sent");
      
    } else {
      Serial.printf("❌ failed, rc=%d, retrying in 5s\n", client.state());
      delay(5000);
    }
  }
}

// Hàm cập nhật hiển thị OLED
void updateOLED(float voltage, float current, float power, float temperature, float humidity) {
  // Kiểm tra OLED có sẵn sàng không
  if (!oledFound) {
    return; // Thoát nếu OLED không hoạt động
  }
  
  u8g2.clearBuffer();
  
  // Tiêu đề "SMART HOME" - căn giữa
  u8g2.setFont(u8g2_font_ncenB08_tr);
  u8g2.drawStr(25, 12, "SMART HOME");
  
  // Vẽ đường kẻ ngang
  u8g2.drawHLine(10, 16, 108);
  
  // Hiển thị thông tin điện năng
  u8g2.setFont(u8g2_font_6x10_tr);
  
  char voltageStr[20];
  char currentStr[20];
  char powerStr[20];
  char tempStr[20];
  char humidStr[20];
  
  snprintf(voltageStr, sizeof(voltageStr), "Voltage: %.2fV", voltage);
  snprintf(currentStr, sizeof(currentStr), "Current: %.1fmA", current);
  snprintf(powerStr, sizeof(powerStr), "Power: %.1fmW", power);
  snprintf(tempStr, sizeof(tempStr), "Temp: %.1fC", temperature);
  snprintf(humidStr, sizeof(humidStr), "Humid: %.1f%%", humidity);
  
  u8g2.drawStr(2, 28, voltageStr);
  u8g2.drawStr(2, 38, currentStr);
  u8g2.drawStr(2, 48, powerStr);
  u8g2.drawStr(2, 58, tempStr);
  u8g2.drawStr(68, 58, humidStr);
  
  // Hiển thị trạng thái gate
  char gateStr[20];
  int gatePercentage = (gateLevel == 0) ? 0 : (gateLevel == 1) ? 25 : (gateLevel == 2) ? 50 : (gateLevel == 3) ? 75 : 100;
  snprintf(gateStr, sizeof(gateStr), "Gate: %d%%", gatePercentage);
  u8g2.drawStr(68, 28, gateStr);
  
  // Hiển thị trạng thái WiFi và MQTT
  u8g2.setFont(u8g2_font_4x6_tr);
  if (WiFi.status() == WL_CONNECTED) {
    u8g2.drawStr(68, 38, "WiFi: OK");
  } else {
    u8g2.drawStr(68, 38, "WiFi: X");
  }
  
  if (client.connected()) {
    u8g2.drawStr(68, 48, "MQTT: OK");
  } else {
    u8g2.drawStr(68, 48, "MQTT: X");
  }
  
  u8g2.sendBuffer();
}

void setup() {
  Serial.begin(115200);

  // Cấu hình chân LED và motor (giữ nguyên)
  pinMode(LED_GATE_PIN, OUTPUT);
  pinMode(LED_AROUND_PIN, OUTPUT);
  pinMode(MOTOR_FORWARD_PIN, OUTPUT);
  pinMode(MOTOR_REVERSE_PIN, OUTPUT);

  // Đảm bảo rơ le tắt ban đầu - FIXED: Logic đã đảo ngược
  digitalWrite(LED_AROUND_PIN, HIGH); // LED Around: HIGH = OFF (tắt đèn)

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
  digitalWrite(LED_GATE_PIN, HIGH);        // ESP32 active LOW - HIGH = OFF
  digitalWrite(LED_AROUND_PIN, HIGH);      // FIXED: HIGH = OFF (tắt đèn) theo logic đã đảo
  digitalWrite(LED_YARD_MAIN_PIN, LOW);
  digitalWrite(LED_FISH_POND_PIN, LOW);
  digitalWrite(LED_AWNING_AREA_PIN, LOW);
  digitalWrite(LED_LIVING_ROOM_PIN, LOW);
  digitalWrite(LED_KITCHEN_PIN, LOW);
  digitalWrite(LED_BEDROOM_PIN, LOW);
  digitalWrite(LED_STAIRS_PIN, LOW);
  digitalWrite(LED_BATHROOM_PIN, LOW);

  // Initialize device states
  ledGateState = false;    // OFF
  ledAroundState = false;  // OFF

  // Cấu hình cảm biến và I2C
  Wire.begin(21, 22);  // SDA=21, SCL=22 (chân I2C mặc định ESP32)
  Serial.println("🔧 I2C Bus initialized (SDA=21, SCL=22)");
  
  // Quét các thiết bị I2C
  scanI2C();
  
  // Khởi tạo INA219 (đã có địa chỉ trong constructor)
  if (!ina219.begin()) {
    Serial.printf("❌ INA219 initialization failed at 0x%02X\n", INA219_ADDRESS);
  } else {
    Serial.printf("✅ INA219 initialized at 0x%02X\n", INA219_ADDRESS);
  }
  
  // Khởi tạo DHT11
  dht.begin();
  Serial.println("✅ DHT11 initialized");

  // Khởi tạo OLED Display
  oledFound = initOLED();
  if (oledFound) {
    Serial.println("📺 OLED Display ready");
    delay(2000); // Hiển thị màn hình khởi động 2 giây
  } else {
    Serial.println("⚠️ OLED Display not available - continuing without display");
  }

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
  
  // 🚨 INITIAL GATE STATUS - Send default gate closed state to Flutter
  Serial.println("📡 Sending initial gate status: CLOSED (0%)");
  gateLevel = 0;  // Ensure gate starts at closed position
  targetGateLevel = 0;
  motorRunning = false;
  motorState = 0;
  
  // Publish initial device status after 3 seconds
  delay(3000);
  publishAllDeviceStatus();
  
  // 🚨 ADDITIONAL - Explicitly send gate closed status
  delay(500);
  publishGateStatus();
  Serial.println("✅ Initial gate status sent: 0% CLOSED");
}

void loop() {
  if (!client.connected()) reconnect();
  client.loop();

  unsigned long now = millis();

  // Debug motor timing mọi lúc khi motor đang chạy
  if (motorRunning) {
    unsigned long elapsed = now - motorStartTime;
    Serial.printf("⏰ MOTOR TIMING: elapsed=%lu ms, target=%lu ms, max=%lu ms\n",
                  elapsed, motorRunTime, MAX_MOTOR_RUNTIME);
  }

  // Kiểm tra và tắt motor khi đạt mức độ mong muốn
  if (motorRunning && now - motorStartTime >= motorRunTime) {
    digitalWrite(MOTOR_FORWARD_PIN, LOW);
    digitalWrite(MOTOR_REVERSE_PIN, LOW);
    motorRunning = false;
    motorState = 0;
    
    // ✅ CHỈ BÂY GIỜ MỚI UPDATE gateLevel
    gateLevel = targetGateLevel;
    
    // Báo trạng thái cổng qua MQTT
    publishGateStatus();
    
    Serial.printf("⏹️ Motor stopped at level %d (runtime: %lu ms)\n", gateLevel, now - motorStartTime);
  }
  
  // FAILSAFE: Ngắt motor nếu chạy quá 7 giây (bảo vệ phần cứng)
  if (motorRunning && now - motorStartTime >= MAX_MOTOR_RUNTIME) {
    digitalWrite(MOTOR_FORWARD_PIN, LOW);
    digitalWrite(MOTOR_REVERSE_PIN, LOW);
    motorRunning = false;
    motorState = 0;
    
    // ⚠️ FAILSAFE: Update gateLevel to target (assume reached)
    gateLevel = targetGateLevel;
    
    // Báo lỗi failsafe
    publishGateStatus();
    
    Serial.printf("🚨 FAILSAFE: Motor force stopped after %lu ms (max: %lu ms)\n", 
                  now - motorStartTime, MAX_MOTOR_RUNTIME);
    Serial.printf("⚠️ Motor runtime exceeded maximum safe limit - check hardware!\n");
  }
  
  // Debug motor state mỗi 5 giây thay vì 10 giây
  static unsigned long lastDebug = 0;
  if (now - lastDebug > 5000) {
    lastDebug = now;
    Serial.printf("🔍 Debug - gateLevel=%d, targetLevel=%d, motorRunning=%s, motorState=%d\n", 
                  gateLevel, targetGateLevel, motorRunning ? "true" : "false", motorState);
    if (motorRunning) {
      Serial.printf("🔍 Motor timing - elapsed=%lu ms, target=%lu ms\n", 
                    now - motorStartTime, motorRunTime);
    }
    
    // 🚨 ENHANCED DEBUG - MQTT connection status
    Serial.printf("🔥 MQTT Status: connected=%s, state=%d\n", 
                  client.connected() ? "true" : "false", client.state());
    Serial.printf("🔥 WiFi Status: %s, IP: %s\n", 
                  WiFi.status() == WL_CONNECTED ? "connected" : "disconnected", 
                  WiFi.localIP().toString().c_str());
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
    
    // Cập nhật OLED Display với thông tin mới nhất (chỉ khi OLED hoạt động)
    if (oledFound) {
      updateOLED(busV, current, power, t, h);
    }
    
    // 🚨 PERIODIC GATE STATUS - Send gate status every 5 seconds to ensure Flutter stays updated
    publishGateStatus();
    Serial.printf("📡 Periodic gate status sent: %d%% (level %d)\n", 
                  (gateLevel == 0) ? 0 : (gateLevel == 1) ? 25 : (gateLevel == 2) ? 50 : (gateLevel == 3) ? 75 : 100, 
                  gateLevel);
  }
}

// THÊM CÁC HÀM MỚI CHO ĐIỀU KHIỂN ĐA MỨC ĐỘ CỔNG

void controlGateToLevel(int targetLevel) {
  if (targetLevel < 0 || targetLevel > 4 || targetLevel == gateLevel) return;
  
  int currentLevel = gateLevel; // Lưu level hiện tại
  bool needForward = targetLevel > currentLevel;
  
  Serial.printf("⚙️ Controlling gate from level %d to %d\n", currentLevel, targetLevel);
  
  // Tính thời gian chạy dựa trên mức độ hiện tại và mục tiêu
  if (needForward) {
    motorRunTime = gateLevelTimes[targetLevel] - gateLevelTimes[currentLevel];
    digitalWrite(MOTOR_FORWARD_PIN, HIGH);
    digitalWrite(MOTOR_REVERSE_PIN, LOW);
    motorState = 1;
    Serial.printf("🔼 Motor FORWARD for %lu ms\n", motorRunTime);
  } else {
    motorRunTime = gateLevelTimes[currentLevel] - gateLevelTimes[targetLevel];
    digitalWrite(MOTOR_FORWARD_PIN, LOW);
    digitalWrite(MOTOR_REVERSE_PIN, HIGH);
    motorState = 2;
    Serial.printf("🔽 Motor REVERSE for %lu ms\n", motorRunTime);
  }
  
  // ✅ FIX: Lưu target, KHÔNG update gateLevel ngay
  targetGateLevel = targetLevel;
  motorStartTime = millis();
  motorRunning = true;
  
  // Debug thông tin timing
  Serial.printf("🔧 DEBUG: currentLevel=%d, targetLevel=%d, motorRunTime=%lu ms\n", 
                currentLevel, targetLevel, motorRunTime);
  Serial.printf("🔧 DEBUG: gateLevelTimes[%d]=%lu, gateLevelTimes[%d]=%lu\n", 
                currentLevel, gateLevelTimes[currentLevel], 
                targetLevel, gateLevelTimes[targetLevel]);
  
  // Publish status with MOVING state - dùng current level, moving to target
  int currentPercentage;
  int targetPercentage;
  switch(currentLevel) {
    case 0: currentPercentage = 0; break;   // 0%
    case 1: currentPercentage = 25; break;  // 25%
    case 2: currentPercentage = 50; break;  // 50%
    case 3: currentPercentage = 75; break;  // 75%
    case 4: currentPercentage = 100; break; // 100%
    default: currentPercentage = 0; break;
  }
  switch(targetLevel) {
    case 0: targetPercentage = 0; break;   // 0%
    case 1: targetPercentage = 25; break;  // 25%
    case 2: targetPercentage = 50; break;  // 50%
    case 3: targetPercentage = 75; break;  // 75%
    case 4: targetPercentage = 100; break; // 100%
    default: targetPercentage = 0; break;
  }
  
  // 🚨 SAFETY CHECK - Use char arrays instead of String objects
  char statusStr[8];
  char descriptionStr[32];
  char messageStr[64];
  
  snprintf(statusStr, sizeof(statusStr), "%d", currentPercentage);
  snprintf(descriptionStr, sizeof(descriptionStr), "MOVING_TO_%d", targetPercentage);
  // 🚨 NEW FORMAT: "percentage:isMoving:description"
  snprintf(messageStr, sizeof(messageStr), "%s:%s:%s", statusStr, "true", descriptionStr);
  
  if (client.connected() && strlen(messageStr) > 0) {
    client.publish(TOPIC_GATE_STATUS, messageStr);
    Serial.printf("📡 Gate status published: %d%% MOVING_TO_%d%% (level %d->%d)\n", 
                  currentPercentage, targetPercentage, currentLevel, targetLevel);
  } else {
    Serial.println("⚠️ MQTT not connected or invalid message - skipping status publish");
  }
  
  Serial.printf("⚙️ Motor started: %s direction, target level %d, runtime %lu ms\n", 
                needForward ? "FORWARD" : "REVERSE", targetLevel, motorRunTime);
}

void publishGateStatus() {
  if (!client.connected()) {
    Serial.println("⚠️ MQTT not connected - skipping gate status publish");
    return;
  }
  
  // 🚨 SAFETY CHECK - Validate gateLevel bounds
  if (gateLevel < 0 || gateLevel > 4) {
    Serial.printf("⚠️ Invalid gateLevel: %d - resetting to 0\n", gateLevel);
    gateLevel = 0;
  }
  
  // Convert level to percentage với 25% intervals để gửi về Flutter
  int percentage;
  switch(gateLevel) {
    case 0: percentage = 0; break;     // 0% = CLOSED
    case 1: percentage = 25; break;    // 25% = LEVEL_25
    case 2: percentage = 50; break;    // 50% = LEVEL_50  
    case 3: percentage = 75; break;    // 75% = LEVEL_75
    case 4: percentage = 100; break;   // 100% = LEVEL_100
    default: percentage = 0; break;
  }
  
  // 🚨 SAFETY CHECK - Use char arrays instead of String objects
  char statusStr[8];
  char descriptionStr[32];
  char messageStr[64];
  
  snprintf(statusStr, sizeof(statusStr), "%d", percentage);
  
  if (motorRunning) {
    snprintf(descriptionStr, sizeof(descriptionStr), "MOVING_TO_%d", percentage);
    // 🚨 NEW FORMAT: "percentage:isMoving:description" 
    snprintf(messageStr, sizeof(messageStr), "%s:%s:%s", statusStr, "true", descriptionStr);
  } else {
    switch(gateLevel) {
      case 0: strcpy(descriptionStr, "CLOSED"); break;
      case 1: strcpy(descriptionStr, "LEVEL_25"); break;
      case 2: strcpy(descriptionStr, "LEVEL_50"); break;
      case 3: strcpy(descriptionStr, "LEVEL_75"); break;
      case 4: strcpy(descriptionStr, "LEVEL_100"); break;
      default: strcpy(descriptionStr, "UNKNOWN"); break;
    }
    // 🚨 NEW FORMAT: "percentage:isMoving:description"
    snprintf(messageStr, sizeof(messageStr), "%s:%s:%s", statusStr, "false", descriptionStr);
  }
  
  // 🚨 SAFETY CHECK - Validate message before publishing
  if (strlen(messageStr) > 0) {
    client.publish(TOPIC_GATE_STATUS, messageStr);
    Serial.printf("📡 Gate status published: %s%% (level %d) - %s\n", 
                  statusStr, gateLevel, descriptionStr);
  } else {
    Serial.println("⚠️ Empty message - skipping gate status publish");
  }
}

// NEW: Publish individual device status
void publishDeviceStatus(const char* deviceName, bool isOn) {
  if (!client.connected()) {
    Serial.println("⚠️ MQTT not connected - skipping device status publish");
    return;
  }
  
  // 🚨 SAFETY CHECK - Validate deviceName
  if (deviceName == nullptr || strlen(deviceName) == 0) {
    Serial.println("⚠️ Invalid device name - skipping device status publish");
    return;
  }
  
  // 🚨 SAFETY CHECK - Use char arrays instead of String objects
  char topicStr[64];
  char messageStr[8];
  char jsonStr[128];
  
  snprintf(topicStr, sizeof(topicStr), "khoasmarthome/%s/status", deviceName);
  strcpy(messageStr, isOn ? "ON" : "OFF");
  
  // Validate before publishing
  if (strlen(topicStr) > 0 && strlen(messageStr) > 0) {
    client.publish(topicStr, messageStr);
    Serial.printf("📡 Device status published: %s = %s\n", deviceName, messageStr);
    
    // Also publish to general device status topic with JSON format
    snprintf(jsonStr, sizeof(jsonStr), 
             "{\"device\":\"%s\",\"state\":\"%s\",\"timestamp\":%lu}", 
             deviceName, messageStr, millis());
    
    client.publish(TOPIC_DEVICE_STATUS, jsonStr);
  } else {
    Serial.printf("⚠️ Invalid topic or message for device: %s\n", deviceName);
  }
}

// NEW: Publish all device status at once
void publishAllDeviceStatus() {
  if (!client.connected()) {
    Serial.println("⚠️ MQTT not connected - skipping all device status publish");
    return;
  }
  
  Serial.println("📡 Publishing all device status...");
  
  // 🚨 SAFETY CHECK - Add delays between publishes to prevent overload
  publishDeviceStatus("led_gate", ledGateState);
  delay(100);
  
  publishDeviceStatus("led_around", ledAroundState);
  delay(100);
  
  // Publish gate status
  publishGateStatus();
  delay(100);
  
  Serial.println("✅ All device status published");
}