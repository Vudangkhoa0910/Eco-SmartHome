# Hướng dẫn Kiểm tra Dữ liệu InfluxDB

## Tổng quan
App Smart Home đã được nâng cấp để lưu trữ dữ liệu năng lượng thực tế lên InfluxDB Cloud, bao gồm:

### 1. Dữ liệu Sensor (Measurement: `sensor_data`)
- **Nhiệt độ** (temperature)
- **Độ ẩm** (humidity) 
- **Dòng điện** (current)
- **Điện áp** (voltage)
- **Công suất** (power)

### 2. Dữ liệu Tiêu thụ Năng lượng (Measurement: `energy_consumption`)
- **Công suất thực tế** từ sensor (power)
- **Điện áp, dòng điện** thực tế (voltage, current)
- **Năng lượng tiêu thụ** (energy_kwh) - tính theo phút
- **Chi phí điện** (cost_vnd) - theo bậc giá Việt Nam
- **Giá điện áp dụng** (rate_vnd_per_kwh)
- **Nhiệt độ và độ ẩm** môi trường

### 3. Dữ liệu Công suất theo Thiết bị (Measurement: `power_consumption`)
- **Từng thiết bị** (device_id: led1, led2, motor, total_system)
- **Công suất thực tế** (power, power_kw)
- **Điện áp, dòng điện** (voltage, current)
- **Hiệu suất** (efficiency)
- **Metadata**: phòng, loại thiết bị, zone, trạng thái

### 4. Trạng thái Thiết bị (Measurement: `device_state`)
- **Trạng thái ON/OFF** của các thiết bị
- **Metadata**: phòng, loại, zone

## Cách Kiểm tra Dữ liệu trên InfluxDB Cloud

### 1. Truy cập InfluxDB Cloud
```
URL: https://us-east-1-1.aws.cloud2.influxdata.com
Organization: 01533c5374ba7af6
Bucket: smart_home
```

### 2. Các Query Flux để kiểm tra dữ liệu

#### Kiểm tra dữ liệu sensor mới nhất:
```flux
from(bucket: "smart_home")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "sensor_data")
  |> last()
```

#### Xem dữ liệu tiêu thụ năng lượng thực tế:
```flux
from(bucket: "smart_home")
  |> range(start: -24h)
  |> filter(fn: (r) => r["_measurement"] == "energy_consumption")
  |> filter(fn: (r) => r["_field"] == "power" or r["_field"] == "energy_kwh" or r["_field"] == "cost_vnd")
  |> yield(name: "energy_data")
```

#### Xem công suất theo từng thiết bị:
```flux
from(bucket: "smart_home")
  |> range(start: -6h)
  |> filter(fn: (r) => r["_measurement"] == "power_consumption")
  |> filter(fn: (r) => r["_field"] == "power")
  |> group(columns: ["device_id"])
  |> aggregateWindow(every: 10m, fn: mean, createEmpty: false)
```

#### Tính tổng chi phí điện trong 24h:
```flux
from(bucket: "smart_home")
  |> range(start: -24h)
  |> filter(fn: (r) => r["_measurement"] == "energy_consumption")
  |> filter(fn: (r) => r["_field"] == "cost_vnd")
  |> sum()
```

#### So sánh hiệu suất thiết bị:
```flux
from(bucket: "smart_home")
  |> range(start: -2h)
  |> filter(fn: (r) => r["_measurement"] == "power_consumption")
  |> filter(fn: (r) => r["_field"] == "efficiency")
  |> group(columns: ["device_id"])
  |> mean()
```

## Cấu trúc Dữ liệu Chi tiết

### Energy Consumption (Thời gian thực)
```
Measurement: energy_consumption
Tags: location=home, measurement_type=real_time
Fields:
  - power: [watts] - Công suất thực từ sensor
  - voltage: [volts] - Điện áp thực
  - current: [amps] - Dòng điện thực
  - energy_kwh: [kWh] - Năng lượng tiêu thụ/phút
  - cost_vnd: [VND] - Chi phí theo bậc giá VN
  - rate_vnd_per_kwh: [VND/kWh] - Giá điện áp dụng
  - temperature: [°C] - Nhiệt độ môi trường
  - humidity: [%] - Độ ẩm môi trường
```

### Power Consumption (Theo thiết bị)
```
Measurement: power_consumption
Tags: device_id, location, type, zone, room, state
Fields:
  - power: [watts] - Công suất thiết bị
  - voltage: [volts] - Điện áp
  - current: [amps] - Dòng điện
  - power_kw: [kW] - Công suất (kW)
  - efficiency: [%] - Hiệu suất thiết bị
```

## Tần suất Ghi Dữ liệu
- **Sensor Data**: Mỗi khi có dữ liệu mới từ ESP32 (~1-5 giây)
- **Energy Consumption**: Mỗi khi có dữ liệu sensor mới 
- **Power Consumption**: 
  - Total System: Khi có dữ liệu sensor mới
  - Devices: Khi thay đổi trạng thái (ON/OFF)

## Troubleshooting

### Nếu không thấy dữ liệu mới:
1. Kiểm tra `_enableInfluxDB = true` trong MqttService
2. Kiểm tra kết nối MQTT
3. Kiểm tra log console cho lỗi InfluxDB
4. Verify InfluxDB credentials

### Các Error phổ biến:
- **Timeout Error**: Mạng chậm hoặc InfluxDB busy
- **Auth Error**: Token hoặc credentials sai
- **Parse Error**: Dữ liệu sensor không hợp lệ

### Monitoring:
- Xem console logs cho các message:
  - `✅ InfluxDB: * written successfully`
  - `⚠️ InfluxDB * error: *`
  - `📊 Writing energy consumption: *`

## Dashboard Trong App

App có các màn hình để xem dữ liệu:
- **Analytics Screen**: Biểu đồ từ InfluxDB
- **Energy Dashboard**: Chi tiết năng lượng và chi phí
- **Zone Management**: Quản lý thiết bị theo khu vực

Tất cả dữ liệu đều được lấy từ InfluxDB Cloud để đảm bảo tính chính xác và đồng bộ.
