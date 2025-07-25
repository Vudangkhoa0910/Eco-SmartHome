#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <Adafruit_INA219.h>
#include <Wire.h>
#include <U8g2lib.h>
#include <ESPping.h>

// WiFi credentials
const char* ssid = "iPhone (85)";
const char* password = "1234567899";

// MQTT over TLS (EMQX Cloud)
const char* mqtt_server = "i0bf1b65.ala.asia-southeast1.emqxsl.com";
const int mqtt_port = 8883;
const char* mqtt_user = "af07dd3c";
const char* mqtt_pass = "U0ofxmA6rbhSp4_O";
const char* mqtt_client_id = "ESP32_S3_Indoor";

// Root CA certificate (included but not used with setInsecure)
const char* root_ca = R"EOF(
-----BEGIN CERTIFICATE-----
MIIGFzCCBP+gAwIBAgIQCzlnQyWUs9z9wmDbbJKxbTANBgkqhkiG9w0BAQsFADBu
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMS协同0wKwYDVQQDEyRFbmNyeXB0aW9uIEV2ZXJ5d2hlcmUg
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

// Pin configurations
// Floor 1
#define LED_KITCHEN_PIN 5        // Đèn bếp lớn
#define LED_LIVING_ROOM_PIN 6    // Đèn phòng khách
#define LED_BEDROOM_PIN 4        // Đèn phòng ngủ

// Floor 2
#define LED_CORNER_BEDROOM_PIN 16 // Đèn phòng ngủ góc
#define LED_YARD_BEDROOM_PIN 17   // Đèn phòng ngủ sân
#define LED_WORSHIP_ROOM_PIN 15   // Đèn phòng thờ
#define LED_HALLWAY_PIN 7         // Đèn hành lang
#define LED_BALCONY_PIN 18        // Đèn ban công lớn

// Quạt và điều hòa (mô phỏng bằng LED)
#define FAN_LIVING_ROOM_PIN 9     // Quạt tầng 1 phòng khách
#define AC_LIVING_ROOM_PIN 12     // Điều hòa tầng 1 phòng khách
#define AC_BEDROOM1_PIN 11        // Điều hòa tầng 2 phòng ngủ 1
#define AC_BEDROOM2_PIN 10        // Điều hòa tầng 2 phòng ngủ 2

// I2C pins for INA219 and OLED
#define I2C_SDA 20
#define I2C_SCL 21

// OLED configuration (1.3 inch, assuming SSD1306 128x64)
#define OLED_ADDRESS 0x3C // Common address for SSD1306
#define INA219_ADDRESS 0x40 // Default INA219 address

// MQTT topics with "inside/" prefix
#define TOPIC_CURRENT "inside/current"
#define TOPIC_VOLTAGE "inside/voltage"
#define TOPIC_POWER "inside/power"
#define TOPIC_KITCHEN "inside/kitchen_light"
#define TOPIC_LIVING_ROOM "inside/living_room_light"
#define TOPIC_BEDROOM "inside/bedroom_light"
#define TOPIC_CORNER_BEDROOM "inside/corner_bedroom_light"
#define TOPIC_YARD_BEDROOM "inside/yard_bedroom_light"
#define TOPIC_WORSHIP_ROOM "inside/worship_room_light"
#define TOPIC_HALLWAY "inside/hallway_light"
#define TOPIC_BALCONY "inside/balcony_light"

// Quạt và điều hòa topics - GỘP VÀO 1 TOPIC
#define TOPIC_CLIMATE_CONTROL "inside/climate_control"

// Device status sync topics
#define TOPIC_STATUS_REQUEST "inside/device_status/request"
#define TOPIC_STATUS_RESPONSE "inside/device_status/response"

Adafruit_INA219 ina219(INA219_ADDRESS);
U8G2_SSD1306_128X64_NONAME_F_SW_I2C u8g2(U8G2_R0, I2C_SCL, I2C_SDA, U8X8_PIN_NONE);
WiFiClientSecure espClient;
PubSubClient client(espClient);

unsigned long lastMsg = 0;
#define MSG_INTERVAL 5000
// Remove STATUS_INTERVAL - no longer needed for periodic status sending

// Function to read actual pin states and publish device status
void publishDeviceStatus() {
  if (!client.connected()) return;
  
  // Create JSON string with actual device states
  // Note: Relays are active LOW, so we need to invert the reading
  String statusJson = "{";
  statusJson += "\"kitchen_light\":" + String(digitalRead(LED_KITCHEN_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"living_room_light\":" + String(digitalRead(LED_LIVING_ROOM_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"bedroom_light\":" + String(digitalRead(LED_BEDROOM_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"corner_bedroom_light\":" + String(digitalRead(LED_CORNER_BEDROOM_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"yard_bedroom_light\":" + String(digitalRead(LED_YARD_BEDROOM_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"worship_room_light\":" + String(digitalRead(LED_WORSHIP_ROOM_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"hallway_light\":" + String(digitalRead(LED_HALLWAY_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"balcony_light\":" + String(digitalRead(LED_BALCONY_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"fan_living_room\":" + String(digitalRead(FAN_LIVING_ROOM_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"ac_living_room\":" + String(digitalRead(AC_LIVING_ROOM_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"ac_bedroom1\":" + String(digitalRead(AC_BEDROOM1_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"ac_bedroom2\":" + String(digitalRead(AC_BEDROOM2_PIN) == LOW ? "true" : "false") + ",";
  statusJson += "\"timestamp\":" + String(millis());
  statusJson += "}";
  
  client.publish(TOPIC_STATUS_RESPONSE, statusJson.c_str());
  Serial.println("📊 Published device status: " + statusJson);
}

void setup_wifi() {
  WiFi.begin(ssid, password);
  Serial.print("🔌 Đang kết nối WiFi");
  unsigned long startAttemptTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttemptTime < 30000) {
    delay(500);
    Serial.print(".");
  }
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ Đã kết nối WiFi");
    Serial.println("IP: " + WiFi.localIP().toString());
  } else {
    Serial.println("\n❌ Không thể kết nối WiFi, tiếp tục mà không có WiFi");
  }
}

bool checkInternet() {
  Serial.print("🔎 Kiểm tra kết nối Internet...");
  if (Ping.ping("8.8.8.8")) { // Ping Google DNS
    Serial.println("✅ Internet OK");
    return true;
  } else {
    Serial.println("❌ Không có kết nối Internet");
    return false;
  }
}

bool checkMQTTServer() {
  Serial.print("🔎 Kiểm tra kết nối tới máy chủ MQTT...");
  WiFiClientSecure testClient;
  testClient.setInsecure(); // Tạm thời bỏ qua xác minh TLS
  if (testClient.connect(mqtt_server, mqtt_port)) {
    Serial.println("✅ Có thể kết nối tới máy chủ MQTT");
    testClient.stop();
    return true;
  } else {
    Serial.println("❌ Không thể kết nối tới máy chủ MQTT");
    return false;
  }
}

void syncTime() {
  if (WiFi.status() != WL_CONNECTED || !checkInternet()) {
    Serial.println("⚠️ Không có kết nối Internet, bỏ qua đồng bộ thời gian");
    return;
  }

  configTime(7 * 3600, 0, "pool.ntp.org", "time.nist.gov", "time.google.com");
  Serial.print("⏳ Đang đồng bộ thời gian");
  unsigned long startAttemptTime = millis();
  while (time(nullptr) < 1700000000 && millis() - startAttemptTime < 30000) {
    delay(500);
    Serial.print(".");
  }
  if (time(nullptr) >= 1700000000) {
    Serial.println("\n⏰ Đã đồng bộ thời gian");
    time_t now = time(nullptr);
    Serial.println(ctime(&now));
  } else {
    Serial.println("\n❌ Không thể đồng bộ thời gian, tiếp tục");
  }
}

void callback(char* topic, byte* payload, unsigned int length) {
  String message;
  for (unsigned int i = 0; i < length; i++) message += (char)payload[i];
  
  // 🚨 ENHANCED DEBUG - Always print received messages
  Serial.printf("  MQTT RECEIVED [%s]: %s (length: %d)\n", topic, message.c_str(), length);
  Serial.printf("🔥 Current time: %lu ms\n", millis());

  // Handle device status request
  if (String(topic) == TOPIC_STATUS_REQUEST) {
    Serial.println("🔄 Received status request, publishing current device states...");
    publishDeviceStatus();
    return;
  }

  // Điều khiển đèn trong nhà (rơ le active LOW)
  if (String(topic) == TOPIC_KITCHEN) {
    Serial.printf("🍳 [KITCHEN] Received command '%s' -> Pin %d\n", message.c_str(), LED_KITCHEN_PIN);
    digitalWrite(LED_KITCHEN_PIN, message == "ON" ? LOW : HIGH);
    Serial.printf("🍳 [KITCHEN] Pin %d set to %s (Relay %s)\n", LED_KITCHEN_PIN, 
                  (message == "ON" ? "LOW" : "HIGH"), (message == "ON" ? "ON" : "OFF"));
    // Send status update after device control
    delay(100); // Small delay to ensure relay has switched
    publishDeviceStatus();
  }
  else if (String(topic) == TOPIC_LIVING_ROOM) {
    Serial.printf("🛋️ [LIVING] Received command '%s' -> Pin %d\n", message.c_str(), LED_LIVING_ROOM_PIN);
    digitalWrite(LED_LIVING_ROOM_PIN, message == "ON" ? LOW : HIGH);
    Serial.printf("🛋️ [LIVING] Pin %d set to %s (Relay %s)\n", LED_LIVING_ROOM_PIN, 
                  (message == "ON" ? "LOW" : "HIGH"), (message == "ON" ? "ON" : "OFF"));
    delay(100);
    publishDeviceStatus();
  }
  else if (String(topic) == TOPIC_BEDROOM) {
    digitalWrite(LED_BEDROOM_PIN, message == "ON" ? LOW : HIGH);
    delay(100);
    publishDeviceStatus();
  }
  else if (String(topic) == TOPIC_CORNER_BEDROOM) {
    digitalWrite(LED_CORNER_BEDROOM_PIN, message == "ON" ? LOW : HIGH);
    delay(100);
    publishDeviceStatus();
  }
  else if (String(topic) == TOPIC_YARD_BEDROOM) {
    digitalWrite(LED_YARD_BEDROOM_PIN, message == "ON" ? LOW : HIGH);
    delay(100);
    publishDeviceStatus();
  }
  else if (String(topic) == TOPIC_WORSHIP_ROOM) {
    digitalWrite(LED_WORSHIP_ROOM_PIN, message == "ON" ? LOW : HIGH);
    delay(100);
    publishDeviceStatus();
  }
  else if (String(topic) == TOPIC_HALLWAY) {
    digitalWrite(LED_HALLWAY_PIN, message == "ON" ? LOW : HIGH);
    delay(100);
    publishDeviceStatus();
  }
  else if (String(topic) == TOPIC_BALCONY) {
    digitalWrite(LED_BALCONY_PIN, message == "ON" ? LOW : HIGH);
    delay(100);
    publishDeviceStatus();
  }
  // 🌟 Handle combined climate control topic (AC + Fan)
  else if (String(topic) == TOPIC_CLIMATE_CONTROL) {
    Serial.printf("� [CLIMATE] Received message: '%s'\n", message.c_str());
    
    // Parse JSON message: {"device": "ac_living_room", "command": "ON"}
    // More robust JSON parsing with detailed debugging
    Serial.printf("🔍 [DEBUG] Checking JSON structure...\n");
    Serial.printf("🔍 [DEBUG] Contains '{': %s\n", message.indexOf("{") >= 0 ? "YES" : "NO");
    Serial.printf("🔍 [DEBUG] Contains '}': %s\n", message.indexOf("}") >= 0 ? "YES" : "NO");
    Serial.printf("🔍 [DEBUG] Contains 'device': %s\n", message.indexOf("device") >= 0 ? "YES" : "NO");
    Serial.printf("🔍 [DEBUG] Contains 'command': %s\n", message.indexOf("command") >= 0 ? "YES" : "NO");
    
    if (message.indexOf("{") >= 0 && message.indexOf("}") >= 0 && 
        message.indexOf("device") >= 0 && message.indexOf("command") >= 0) {
      
      // Find "device":"value" pattern
      int deviceKeyPos = message.indexOf("\"device\":");
      int deviceValueStart = message.indexOf("\"", deviceKeyPos + 9) + 1; // Skip "device":
      int deviceValueEnd = message.indexOf("\"", deviceValueStart);
      
      // Find "command":"value" pattern  
      int commandKeyPos = message.indexOf("\"command\":");
      int commandValueStart = message.indexOf("\"", commandKeyPos + 10) + 1; // Skip "command":
      int commandValueEnd = message.indexOf("\"", commandValueStart);
      
      Serial.printf("🔍 [DEBUG] Device key pos:%d, value start:%d, end:%d\n", 
                    deviceKeyPos, deviceValueStart, deviceValueEnd);
      Serial.printf("🔍 [DEBUG] Command key pos:%d, value start:%d, end:%d\n", 
                    commandKeyPos, commandValueStart, commandValueEnd);
      
      if (deviceKeyPos >= 0 && deviceValueStart > deviceKeyPos && deviceValueEnd > deviceValueStart &&
          commandKeyPos >= 0 && commandValueStart > commandKeyPos && commandValueEnd > commandValueStart) {
        
        String device = message.substring(deviceValueStart, deviceValueEnd);
        String command = message.substring(commandValueStart, commandValueEnd);
        
        Serial.printf("🌟 [CLIMATE] ✅ Parsed - Device: '%s', Command: '%s'\n", device.c_str(), command.c_str());
        
        // Control specific device
        bool deviceFound = false;
        if (device == "fan_living_room") {
          Serial.printf("🌀 [FAN] ✅ Controlling fan: %s -> Pin %d\n", command.c_str(), FAN_LIVING_ROOM_PIN);
          digitalWrite(FAN_LIVING_ROOM_PIN, command == "ON" ? LOW : HIGH);
          Serial.printf("🌀 [FAN] Pin %d set to %s (Relay %s)\n", FAN_LIVING_ROOM_PIN, 
                        (command == "ON" ? "LOW" : "HIGH"), (command == "ON" ? "ON" : "OFF"));
          deviceFound = true;
        }
        else if (device == "ac_living_room") {
          Serial.printf("❄️ [AC-LIVING] ✅ Controlling AC: %s -> Pin %d\n", command.c_str(), AC_LIVING_ROOM_PIN);
          digitalWrite(AC_LIVING_ROOM_PIN, command == "ON" ? LOW : HIGH);
          Serial.printf("❄️ [AC-LIVING] Pin %d set to %s (Relay %s)\n", AC_LIVING_ROOM_PIN, 
                        (command == "ON" ? "LOW" : "HIGH"), (command == "ON" ? "ON" : "OFF"));
          deviceFound = true;
        }
        else if (device == "ac_bedroom1") {
          Serial.printf("❄️ [AC-BEDROOM1] ✅ Controlling AC: %s -> Pin %d\n", command.c_str(), AC_BEDROOM1_PIN);
          digitalWrite(AC_BEDROOM1_PIN, command == "ON" ? LOW : HIGH);
          Serial.printf("❄️ [AC-BEDROOM1] Pin %d set to %s (Relay %s)\n", AC_BEDROOM1_PIN, 
                        (command == "ON" ? "LOW" : "HIGH"), (command == "ON" ? "ON" : "OFF"));
          deviceFound = true;
        }
        else if (device == "ac_bedroom2") {
          Serial.printf("❄️ [AC-BEDROOM2] ✅ Controlling AC: %s -> Pin %d\n", command.c_str(), AC_BEDROOM2_PIN);
          digitalWrite(AC_BEDROOM2_PIN, command == "ON" ? LOW : HIGH);
          Serial.printf("❄️ [AC-BEDROOM2] Pin %d set to %s (Relay %s)\n", AC_BEDROOM2_PIN, 
                        (command == "ON" ? "LOW" : "HIGH"), (command == "ON" ? "ON" : "OFF"));
          deviceFound = true;
        }
        
        if (deviceFound) {
          delay(100);
          publishDeviceStatus();
          Serial.printf("✅ [CLIMATE] Device '%s' controlled successfully\n", device.c_str());
        } else {
          Serial.printf("⚠️ [CLIMATE] Unknown device: '%s'\n", device.c_str());
        }
      } else {
        Serial.printf("❌ [CLIMATE] Failed to parse device/command from: '%s'\n", message.c_str());
      }
    } else {
      Serial.printf("❌ [CLIMATE] Not a valid JSON format: '%s'\n", message.c_str());
    }
  }
}

void reconnect() {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("⚠️ Mất kết nối WiFi, thử kết nối lại...");
    setup_wifi();
  }
  if (WiFi.status() == WL_CONNECTED && checkInternet() && checkMQTTServer()) {
    while (!client.connected()) {
      Serial.print("🔁 Đang kết nối MQTT...");
      // Tăng thời gian chờ kết nối
      espClient.setTimeout(10000); // 10 giây
      if (client.connect(mqtt_client_id, mqtt_user, mqtt_pass)) {
        Serial.println("✅ Đã kết nối");
        client.subscribe(TOPIC_KITCHEN);
        client.subscribe(TOPIC_LIVING_ROOM);
        client.subscribe(TOPIC_BEDROOM);
        client.subscribe(TOPIC_CORNER_BEDROOM);
        client.subscribe(TOPIC_YARD_BEDROOM);
        client.subscribe(TOPIC_WORSHIP_ROOM);
        client.subscribe(TOPIC_HALLWAY);
        client.subscribe(TOPIC_BALCONY);
        client.subscribe(TOPIC_STATUS_REQUEST);  // Subscribe to status request topic
        
        // Subscribe to climate control topic (AC + Fan combined)
        Serial.println("🌟 Subscribing to combined climate control topic...");
        bool climateSub = client.subscribe(TOPIC_CLIMATE_CONTROL);
        Serial.printf("❄️🌀 Climate control subscription (%s): %s\n", TOPIC_CLIMATE_CONTROL, climateSub ? "✅ SUCCESS" : "❌ FAILED");
        
        // Send initial device status after connection
        delay(1000); // Wait for subscription to be established
        publishDeviceStatus();
        Serial.println("📋 Subscribed to all topics and published initial status");
      } else {
        Serial.printf("❌ Thất bại, rc=%d, thử lại sau 5s\n", client.state());
        delay(5000);
      }
    }
  } else {
    Serial.println("⚠️ Không thể kết nối MQTT do mạng hoặc máy chủ, thử lại sau 5s");
    delay(5000);
  }
}

void setup() {
  Serial.begin(115200);

  // Cấu hình chân cho đèn trong nhà
  pinMode(LED_KITCHEN_PIN, OUTPUT);
  pinMode(LED_LIVING_ROOM_PIN, OUTPUT);
  pinMode(LED_BEDROOM_PIN, OUTPUT);
  pinMode(LED_CORNER_BEDROOM_PIN, OUTPUT);
  pinMode(LED_YARD_BEDROOM_PIN, OUTPUT);
  pinMode(LED_WORSHIP_ROOM_PIN, OUTPUT);
  pinMode(LED_HALLWAY_PIN, OUTPUT);
  pinMode(LED_BALCONY_PIN, OUTPUT);
  
  // Cấu hình chân cho quạt và điều hòa
  pinMode(FAN_LIVING_ROOM_PIN, OUTPUT);
  pinMode(AC_LIVING_ROOM_PIN, OUTPUT);
  pinMode(AC_BEDROOM1_PIN, OUTPUT);
  pinMode(AC_BEDROOM2_PIN, OUTPUT);

  // Tắt tất cả đèn ban đầu (rơ le active LOW)
  digitalWrite(LED_KITCHEN_PIN, HIGH);
  digitalWrite(LED_LIVING_ROOM_PIN, HIGH);
  digitalWrite(LED_BEDROOM_PIN, HIGH);
  digitalWrite(LED_CORNER_BEDROOM_PIN, HIGH);
  digitalWrite(LED_YARD_BEDROOM_PIN, HIGH);
  digitalWrite(LED_WORSHIP_ROOM_PIN, HIGH);
  digitalWrite(LED_HALLWAY_PIN, HIGH);
  digitalWrite(LED_BALCONY_PIN, HIGH);
  
  // Tắt tất cả quạt và điều hòa ban đầu (rơ le active LOW)
  digitalWrite(FAN_LIVING_ROOM_PIN, HIGH);
  digitalWrite(AC_LIVING_ROOM_PIN, HIGH);
  digitalWrite(AC_BEDROOM1_PIN, HIGH);
  digitalWrite(AC_BEDROOM2_PIN, HIGH);

  // Khởi tạo I2C cho INA219 và OLED
  Wire.begin(I2C_SDA, I2C_SCL);
  if (!ina219.begin()) {
    Serial.println("❌ Không thể khởi tạo INA219");
  }
  u8g2.begin();
  u8g2.setFont(u8g2_font_ncenB08_tr); // Font nhỏ gọn, dễ đọc
  u8g2.clearBuffer();
  u8g2.drawStr(0, 10, "He thong nha thong minh");
  u8g2.sendBuffer();

  setup_wifi();
  syncTime();

  espClient.setInsecure(); // Tạm thời bỏ qua xác minh TLS, giống mã hoạt động
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);

  Serial.println("🎯 Hệ thống nhà thông minh trong nhà sẵn sàng!");
  Serial.println("📋 Các thiết bị khả dụng:");
  Serial.println("   💡 Tầng 1: Bếp, Phòng khách, Phòng ngủ");
  Serial.println("   💡 Tầng 2: Phòng ngủ góc, Phòng ngủ sân, Phòng thờ, Hành lang, Ban công");
  Serial.println("   🔌 INA219 & OLED trên I2C");
  
  // 🔍 Debug: Check initial pin states
  Serial.println("\n🔍 [DEBUG] Initial Pin States (HIGH=OFF/3.3V, LOW=ON/0V):");
  Serial.printf("  🍳 Kitchen (Pin %d): %s\n", LED_KITCHEN_PIN, digitalRead(LED_KITCHEN_PIN) ? "HIGH/OFF" : "LOW/ON");
  Serial.printf("  🛋️ Living Room (Pin %d): %s\n", LED_LIVING_ROOM_PIN, digitalRead(LED_LIVING_ROOM_PIN) ? "HIGH/OFF" : "LOW/ON");
  Serial.printf("  🛏️ Bedroom (Pin %d): %s\n", LED_BEDROOM_PIN, digitalRead(LED_BEDROOM_PIN) ? "HIGH/OFF" : "LOW/ON");
  Serial.printf("  🌀 Fan Living (Pin %d): %s\n", FAN_LIVING_ROOM_PIN, digitalRead(FAN_LIVING_ROOM_PIN) ? "HIGH/OFF" : "LOW/ON");
  Serial.printf("  ❄️ AC Living (Pin %d): %s\n", AC_LIVING_ROOM_PIN, digitalRead(AC_LIVING_ROOM_PIN) ? "HIGH/OFF" : "LOW/ON");
  Serial.printf("  ❄️ AC Bed1 (Pin %d): %s\n", AC_BEDROOM1_PIN, digitalRead(AC_BEDROOM1_PIN) ? "HIGH/OFF" : "LOW/ON");
  Serial.printf("  ❄️ AC Bed2 (Pin %d): %s\n", AC_BEDROOM2_PIN, digitalRead(AC_BEDROOM2_PIN) ? "HIGH/OFF" : "LOW/ON");
  Serial.println();
}

void loop() {
  if (!client.connected()) reconnect();
  client.loop();

  unsigned long now = millis();

  // Gửi dữ liệu cảm biến và cập nhật OLED mỗi 5 giây
  if (now - lastMsg > MSG_INTERVAL) {
    lastMsg = now;

    float busV = ina219.getBusVoltage_V();
    float current = ina219.getCurrent_mA();
    float power = ina219.getPower_mW();
    if (WiFi.status() == WL_CONNECTED && client.connected()) {
      client.publish(TOPIC_VOLTAGE, String(busV, 2).c_str());
      client.publish(TOPIC_CURRENT, String(current, 2).c_str());
      client.publish(TOPIC_POWER, String(power, 2).c_str());
    }
    Serial.printf("🔋 V: %.2fV, I: %.2fmA, P: %.2fmW\n", busV, current, power);

    // Cập nhật OLED
    u8g2.clearBuffer();
    char buffer[32];
    snprintf(buffer, sizeof(buffer), "V: %.2fV", busV);
    u8g2.drawStr(0, 10, buffer);
    snprintf(buffer, sizeof(buffer), "I: %.2fmA", current);
    u8g2.drawStr(0, 20, buffer);
    snprintf(buffer, sizeof(buffer), "P: %.2fmW", power);
    u8g2.drawStr(0, 30, buffer);
    u8g2.sendBuffer();
  }
}