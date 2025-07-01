# 🔧 Hướng dẫn Debug và Kiểm tra InfluxDB Cloud

## 📊 **Kiểm tra dữ liệu trong InfluxDB Cloud**

### 1. Truy cập InfluxDB Cloud
- Đăng nhập vào: https://cloud2.influxdata.com/
- Chọn Organization: `Smart Home`
- Chọn Bucket: `iot_data`

### 2. Sử dụng Data Explorer
```
1. Vào Data Explorer (biểu tượng tia chớp)
2. Chọn Bucket: iot_data
3. Chọn _measurement: sensor_data hoặc device_state
4. Chọn _field: temperature, humidity, current, etc.
5. Chọn thời gian: Last 1h
6. Click Submit
```

### 3. Truy vấn Flux để kiểm tra dữ liệu

#### Kiểm tra sensor data:
```flux
from(bucket: "iot_data")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "sensor_data")
  |> yield(name: "sensor_data")
```

#### Kiểm tra device state:
```flux
from(bucket: "iot_data")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "device_state")
  |> yield(name: "device_state")
```

#### Kiểm tra power consumption data:
```flux
from(bucket: "iot_data")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "power_consumption")
  |> yield(name: "power_consumption")
```

#### Kiểm tra electricity bill data:
```flux
from(bucket: "iot_data")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "electricity_bill")
  |> yield(name: "electricity_bill")
```

#### Tính tổng chi phí điện theo ngày:
```flux
from(bucket: "iot_data")
  |> range(start: -7d)
  |> filter(fn: (r) => r["_measurement"] == "power_consumption")
  |> filter(fn: (r) => r["_field"] == "cost")
  |> aggregateWindow(every: 1d, fn: sum, createEmpty: false)
  |> yield(name: "daily_cost")
```

## 🐛 **Debug Logs**

### 1. Xem logs trong Flutter
```bash
flutter logs --verbose
```

### 2. Tìm kiếm logs InfluxDB:
```bash
# Tìm logs thành công
flutter logs | grep "InfluxDB.*written successfully"

# Tìm logs lỗi
flutter logs | grep "InfluxDB.*error"
```

### 3. Kiểm tra log patterns:
```
✅ InfluxDB: Sensor data written successfully
✅ InfluxDB: Device state [led1: OFF] written successfully
❌ InfluxDB write error: [lỗi]
```

## 🔧 **Troubleshooting**

### 1. Nếu không thấy dữ liệu:
- Kiểm tra `_enabled = true` trong `influxdb_service.dart`
- Kiểm tra token và URL có đúng không
- Kiểm tra network connectivity
- Kiểm tra logs có lỗi gì không

### 2. Nếu app bị lag:
- Giảm timeout xuống 3 giây
- Kiểm tra network có chậm không
- Temporarily disable InfluxDB: `_enabled = false`

### 3. Nếu connection status sai:
- Kiểm tra logs connection status
- Restart app để reset connection state
- Kiểm tra MQTT stream có đang hoạt động không

## 📈 **Tạo Dashboard**

### 1. Vào Dashboard tab
```
1. Click Create Dashboard
2. Add Cell
3. Chọn Graph visualization
4. Dùng query builder hoặc Script Editor
```

### 2. Query mẫu cho Temperature Graph:
```flux
from(bucket: "iot_data")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "sensor_data")
  |> filter(fn: (r) => r["_field"] == "temperature")
  |> aggregateWindow(every: v.windowPeriod, fn: mean, createEmpty: false)
  |> yield(name: "temperature")
```

### 3. Query mẫu cho Device Status:
```flux
from(bucket: "iot_data")
  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)
  |> filter(fn: (r) => r["_measurement"] == "device_state")
  |> filter(fn: (r) => r["_field"] == "state")
  |> last()
  |> yield(name: "device_status")
```

## 🚀 **Tối ưu Performance**

### 1. Batch Writing (nếu cần):
```dart
// Gom data và ghi một lượt
List<String> batch = [];
batch.add(_convertToLineProtocol(data1));
batch.add(_convertToLineProtocol(data2));
// Ghi toàn bộ batch
```

### 2. Retry Logic:
```dart
// Thử lại khi gặp lỗi network
for (int i = 0; i < 3; i++) {
  try {
    await _writeToInflux(data);
    break;
  } catch (e) {
    if (i == 2) rethrow;
    await Future.delayed(Duration(seconds: 1));
  }
}
```

### 3. Caching Offline:
```dart
// Lưu data khi offline, sync khi online
if (await _checkConnection()) {
  await _writeToInflux(data);
} else {
  await _saveToLocalCache(data);
}
```

## 🎯 **Thử nghiệm Real-time**

1. **Mở app** - kiểm tra logs
2. **Bật/tắt LED** - kiểm tra device_state data
3. **Xem sensor data** - kiểm tra sensor_data 
4. **Vào InfluxDB UI** - kiểm tra data có xuất hiện không
5. **Tạo dashboard** - visualize data

## 📝 **Checklist**

- [ ] App khởi động không bị treo
- [ ] MQTT connection status hiển thị đúng
- [ ] Sensor data được nhận và hiển thị
- [ ] Device control hoạt động (LED, Motor)
- [ ] InfluxDB logs hiển thị "written successfully"
- [ ] Dữ liệu xuất hiện trong InfluxDB Cloud
- [ ] Dashboard hiển thị charts
- [ ] Performance không bị lag

## 🔍 **Commands hữu ích**

```bash
# Chạy app với logs verbose
flutter run --verbose

# Chỉ xem logs InfluxDB
flutter logs | grep -i influx

# Chỉ xem logs MQTT
flutter logs | grep -i mqtt

# Chỉ xem logs connection
flutter logs | grep -i "connection\|connect"

# Clear logs và chạy lại
flutter clean && flutter run
```
