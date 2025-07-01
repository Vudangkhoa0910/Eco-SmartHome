# InfluxDB Cloud Setup Instructions

## 🚀 Hướng dẫn thiết lập InfluxDB Cloud

### Bước 1: Tạo tài khoản InfluxDB Cloud FREE
1. Truy cập: https://cloud2.influxdata.com/signup
2. Chọn **Free Plan** (30 days retention, 5MB/5min write rate)
3. Chọn region **AWS US East** (tốc độ tối ưu)

### Bước 2: Tạo Organization và Bucket
1. Sau khi đăng nhập, tạo Organization: `smart-home-org`
2. Tạo Bucket: `smart-home-data`
3. Set retention policy: `30 days` (hoặc theo nhu cầu)

### Bước 3: Tạo API Token
1. Vào **Data > API Tokens**
2. Click **Generate API Token**
3. Chọn **Read/Write Token**
4. Permissions:
   - **Write**: `smart-home-data` bucket
   - **Read**: `smart-home-data` bucket
5. Copy token và lưu an toàn

### Bước 4: Cấu hình trong ứng dụng
Mở file `lib/service/influxdb_service.dart` và cập nhật:

```dart
class InfluxDBService {
  static const String _baseUrl = 'https://us-east-1-1.aws.cloud2.influxdata.com'; // Your cluster URL
  static const String _org = 'your-org-id'; // Your Organization ID
  static const String _bucket = 'smart-home-data';
  static const String _token = 'your-api-token-here'; // Your API Token
  
  // ... rest of the code
}
```

### Bước 5: Test kết nối
1. Chạy app và kiểm tra logs
2. Xem data trong InfluxDB UI: **Data Explorer**
3. Query test:
```flux
from(bucket: "smart-home-data")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "sensor_data")
```

## 📊 Data Schema

### Sensor Data (measurement: sensor_data)
```
sensor_data,location=home temperature=25.5,humidity=60.2,voltage=220.1,current=0.5,power=110.05 1640995200
```

### Device State (measurement: device_state)
```
device_state,device=led1,room=living_room,type=light state="ON",value=1 1640995200
```

## 🔍 Query Examples

### Nhiệt độ trung bình 24h qua
```flux
from(bucket: "smart-home-data")
  |> range(start: -24h)
  |> filter(fn: (r) => r["_measurement"] == "sensor_data")
  |> filter(fn: (r) => r["_field"] == "temperature")
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
```

### Thống kê sử dụng LED1 7 ngày qua
```flux
from(bucket: "smart-home-data")
  |> range(start: -7d)
  |> filter(fn: (r) => r["_measurement"] == "device_state")
  |> filter(fn: (r) => r["device"] == "led1")
  |> filter(fn: (r) => r["_field"] == "value")
  |> aggregateWindow(every: 1h, fn: mean, createEmpty: false)
```

## 💡 Tính năng Analytics có thể phát triển

### 📈 Hiện tại đã implement:
- ✅ Real-time sensor data logging
- ✅ Device state tracking  
- ✅ Usage statistics (% thời gian bật/tắt)
- ✅ Temperature & Power consumption charts
- ✅ Historical data queries

### 🔮 Tương lai có thể mở rộng:
- 📊 **Energy Cost Calculator**: Tính toán chi phí điện
- 🔔 **Smart Alerts**: Cảnh báo khi nhiệt độ/điện năng bất thường
- 🤖 **ML Predictions**: Dự đoán pattern sử dụng thiết bị
- 📱 **Mobile Notifications**: Push notifications
- 📋 **Reports**: Báo cáo tự động hàng tuần/tháng
- 🏠 **Room Comparison**: So sánh hiệu suất giữa các phòng
- ⚡ **Peak Usage Analysis**: Phân tích giờ cao điểm
- 🌡️ **Climate Control**: Tự động điều chỉnh dựa trên data
- 💾 **Data Export**: Xuất CSV/PDF reports
- 🔄 **Automation Rules**: Tự động bật/tắt dựa trên điều kiện

## ⚙️ Configuration Options

```dart
// Cấu hình retention và batching
class InfluxDBConfig {
  static const Duration batchInterval = Duration(seconds: 10);
  static const int maxBatchSize = 100;
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const bool enableBatching = true;
  static const bool enableRetry = true;
  static const int maxRetries = 3;
}
```

## 🔐 Security Best Practices

1. **API Token**: Chỉ cấp quyền cần thiết (Read/Write cho bucket cụ thể)
2. **Environment Variables**: Không hardcode token trong source code
3. **Network**: Sử dụng HTTPS cho mọi request
4. **Rate Limiting**: Tuân thủ limits của Free Tier
5. **Error Handling**: Graceful handling khi service không available

## 📝 Migration Plan

Nếu cần migrate sau này:
1. **InfluxDB → Supabase**: Export data via API, transform và import
2. **InfluxDB → Firebase**: Tương tự, cần restructure data
3. **Hybrid**: Giữ InfluxDB cho time series, Supabase cho metadata

## 🎯 Kết luận

InfluxDB Cloud là lựa chọn tối ưu vì:
- ✅ **Specialized** cho IoT time series data
- ✅ **Scalable** từ prototype → production
- ✅ **Cost-effective** với Free Tier generous
- ✅ **Performance** vượt trội cho analytics queries
- ✅ **Future-proof** với ecosystem mạnh mẽ

Free Tier đủ để phát triển và test hầu hết tính năng, có thể upgrade sau khi có user base lớn.
