# ECO - SMARTHOME 

Hệ thống nhà thông minh toàn diện sử dụng Firebase Firestore để lưu trữ dữ liệu.

## ✨ Tính năng chính

- 📊 **Phân tích thông minh**: Theo dõi và phân tích dữ liệu cảm biến real-time
- 🏠 **Điều khiển thiết bị**: Quản lý đèn LED, motor và các thiết bị IoT
- ⚡ **Giám sát điện năng**: Theo dõi tiêu thụ điện và tính toán hóa đơn
- 🔄 **MQTT Integration**: Kết nối với ESP32 qua MQTT protocol
- 🔥 **Firebase Backend**: Lưu trữ dữ liệu trên cloud an toàn và đáng tin cậy

## 🚀 Cập nhật mới nhất

**Migration từ InfluxDB sang Firebase Firestore:**
- ✅ Chuyển đổi toàn bộ dữ liệu lưu trữ từ InfluxDB sang Firebase Firestore
- ✅ Cải thiện bảo mật với Firebase Authentication
- ✅ Tối ưu hóa hiệu suất với Firestore indexes
- ✅ Real-time data synchronization
- ✅ Offline support với Firestore cache

## 📱 Cấu trúc dữ liệu Firebase

### Collections:
- `sensor_data`: Dữ liệu cảm biến (nhiệt độ, độ ẩm, điện áp, dòng điện)
- `device_states`: Trạng thái thiết bị (ON/OFF, motor direction)
- `power_consumption`: Dữ liệu tiêu thụ điện năng
- `energy_consumption`: Chi tiết tiêu thụ năng lượng theo thời gian
- `electricity_bills`: Hóa đơn điện và phân tích chi phí

## 🛠️ Cài đặt

1. Clone repository
2. Cài đặt dependencies: `flutter pub get`
3. Cấu hình Firebase project
4. Deploy Firestore rules: `firebase deploy --only firestore:rules`
5. Chạy ứng dụng: `flutter run`

## 📊 Analytics & Monitoring

Hệ thống cung cấp dashboard phân tích chi tiết:
- Biểu đồ tiêu thụ điện theo thời gian
- Thống kê sử dụng thiết bị
- Dự báo chi phí điện hàng tháng
- Báo cáo hiệu quả năng lượng

## 🔗 Kết nối

- **MQTT Broker**: EMQX Cloud
- **Backend**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Hardware**: ESP32 + various sensors

---

### Coming Soon
🚀 Nhiều tính năng mới đang được phát triển...