# ECO - SMARTHOME

Hệ thống nhà thông minh toàn diện đa tích hợp, biến tổ hợp thiết bị thông thường trở nên thông minh và có thể điều khiển, giám sát và quản lý qua phần mềm từ bất cứ đâu.

## Tính năng chính

- **Phân tích thông minh**: Theo dõi và phân tích dữ liệu cảm biến real-time với AI
- **Điều khiển thiết bị**: Quản lý đèn, quạt, điều hòa và các thiết bị IoT khác
- **Giám sát điện năng**: Theo dõi tiêu thụ điện và tính toán hóa đơn
- **Trợ lý giọng nói**: Điều khiển bằng giọng nói với tích hợp Gemini AI
- **Tự động hóa**: Thiết lập kịch bản tự động dựa trên thời gian và điều kiện

## Kiến trúc hệ thống

### Backend

- **Firebase Firestore**: Lưu trữ dữ liệu cảm biến, trạng thái thiết bị và cấu hình
- **Firebase Authentication**: Xác thực và quản lý người dùng
- **MQTT**: Giao thức truyền thông giữa thiết bị và ứng dụng
- **Gemini AI**: Tích hợp trí tuệ nhân tạo cho phân tích và trợ lý giọng nói

### Hardware

- **ESP32**: Vi điều khiển chính cho các thiết bị IoT
- **Cảm biến**: Nhiệt độ, độ ẩm, điện áp, dòng điện
- **Thiết bị điều khiển**: Rơ-le, động cơ, đèn LED
- **Mô-đun chuyển đổi**: Các mạch điện tử kết nối thiết bị thông thường với hệ thống thông minh

## Cấu trúc dữ liệu Firebase

### Collections

- `sensor_data`: Dữ liệu cảm biến (nhiệt độ, độ ẩm, điện áp, dòng điện)
- `device_states`: Trạng thái thiết bị (ON/OFF, motor direction)
- `power_consumption`: Dữ liệu tiêu thụ điện năng
- `energy_consumption`: Chi tiết tiêu thụ năng lượng theo thời gian
- `electricity_bills`: Hóa đơn điện và phân tích chi phí
- `analytics`: Dữ liệu phân tích và dự báo
- `chat_history`: Lịch sử tương tác với trợ lý giọng nói

## Tính năng AI và Phân tích

- **Phân tích tiêu thụ điện**: Theo dõi và dự báo chi phí điện năng
- **Gợi ý tối ưu hóa**: Đề xuất cách tiết kiệm năng lượng
- **Trợ lý giọng nói**: Điều khiển thiết bị và trả lời câu hỏi tổng quát
- **Phát hiện bất thường**: Cảnh báo khi phát hiện tiêu thụ điện bất thường

## Cài đặt

1. Clone repository
2. Cài đặt dependencies: `flutter pub get`
3. Cấu hình Firebase project
4. Deploy Firestore rules: `firebase deploy --only firestore:rules`
5. Chạy ứng dụng: `flutter run`

## Yêu cầu hệ thống

- Flutter SDK: >=2.19.0 <3.0.0
- Firebase project
- MQTT Broker (EMQX Cloud)
- ESP32 với firmware tương thích

## Phân tích và Giám sát

Hệ thống cung cấp dashboard phân tích chi tiết:
- Biểu đồ tiêu thụ điện theo thời gian
- Thống kê sử dụng thiết bị
- Dự báo chi phí điện hàng tháng
- Báo cáo hiệu quả năng lượng

## Kết nối

- **MQTT Broker**: EMQX Cloud
- **Backend**: Firebase Firestore
- **Authentication**: Firebase Auth
- **Hardware**: ESP32 + various sensors

## Giải pháp chuyển đổi thiết bị thông thường

Khác với các giải pháp sử dụng từng thiết bị thông minh đơn lẻ, ECO-SMARTHOME cung cấp giải pháp toàn diện để:
- Biến các thiết bị điện thông thường thành thiết bị thông minh có thể điều khiển từ xa
- Tích hợp các thiết bị riêng lẻ vào một hệ thống quản lý tập trung
- Giám sát và phân tích dữ liệu từ tất cả thiết bị trong nhà
- Tối ưu hóa việc sử dụng năng lượng dựa trên dữ liệu thực tế

## Phát triển tương lai

- Tích hợp thêm các thiết bị thông minh
- Cải thiện thuật toán dự báo tiêu thụ điện
- Mở rộng tính năng trợ lý giọng nói
- Tối ưu hóa hiệu suất và bảo mật