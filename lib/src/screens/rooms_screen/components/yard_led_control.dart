import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/provider/getit.dart';

class YardLedControlWidget extends StatelessWidget {
  const YardLedControlWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = getIt<HomeScreenViewModel>();
    
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đèn sân vườn',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Điều khiển 2 bóng đèn LED',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: getProportionateScreenHeight(16)),
          
          // LED Controls
          Row(
            children: [
              Expanded(
                child: _buildLedControl(
                  context,
                  'LED 1',
                  model.isLightOn,
                  () => model.toggleLed1(),
                  Colors.amber,
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Expanded(
                child: _buildLedControl(
                  context,
                  'LED 2',
                  model.isACON, // Using AC variable for LED2
                  () => model.toggleLed2(),
                  Colors.lightBlue,
                ),
              ),
            ],
          ),
          
          SizedBox(height: getProportionateScreenHeight(12)),
          
          // Status bar
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(12),
              vertical: getProportionateScreenHeight(8),
            ),
            decoration: BoxDecoration(
              color: _isReallyConnected(model) 
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _isReallyConnected(model) ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: _isReallyConnected(model) ? Colors.green : Colors.red,
                ),
                SizedBox(width: getProportionateScreenWidth(8)),
                Text(
                  _isReallyConnected(model) 
                    ? 'Kết nối thành công'
                    : 'Mất kết nối IoT',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isReallyConnected(model) ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLedControl(
    BuildContext context,
    String name,
    bool isOn,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(12),
          vertical: getProportionateScreenHeight(12),
        ),
        decoration: BoxDecoration(
          // FIXED: LED Around logic ngược - isOn=true nghĩa là tắt đèn
          color: name == 'LED 2' ? 
            (isOn ? Colors.red.withOpacity(0.1) : color.withOpacity(0.1)) : // LED 2: ON=Tắt(đỏ), OFF=Mở
            (isOn ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1)), // LED 1: bình thường
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: name == 'LED 2' ? 
              (isOn ? Colors.red : color) : // LED 2: ON=Tắt(đỏ), OFF=Mở
              (isOn ? color : Colors.grey.withOpacity(0.3)), // LED 1: bình thường
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb,
              // FIXED: LED Around hiển thị màu đúng theo trạng thái thực tế
              color: name == 'LED 2' ? 
                (isOn ? Colors.red : color) : // LED 2: ON=Tắt(đỏ), OFF=Mở
                (isOn ? color : Colors.grey), // LED 1: bình thường
              size: 24,
            ),
            SizedBox(height: getProportionateScreenHeight(8)),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                // FIXED: LED Around hiển thị màu đúng
                color: name == 'LED 2' ? 
                  (isOn ? Colors.red : color) : // LED 2: ON=Tắt(đỏ), OFF=Mở
                  (isOn ? color : Colors.grey), // LED 1: bình thường
              ),
            ),
            SizedBox(height: getProportionateScreenHeight(4)),
            Text(
              // FIXED: Hiển thị trạng thái thực tế của đèn LED Around
              name == 'LED 2' ? (isOn ? 'Tắt' : 'Mở') : (isOn ? 'Bật' : 'Tắt'),
              style: TextStyle(
                fontSize: 10,
                color: name == 'LED 2' ? 
                  (isOn ? Colors.red : color) : // LED 2: ON=Tắt (đỏ), OFF=Mở (màu bình thường)
                  (isOn ? color : Colors.grey), // LED 1: giữ nguyên logic
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isReallyConnected(HomeScreenViewModel model) {
    // Check if we're receiving recent data to determine real connection status
    return model.isMqttConnected || 
      (model.sensorData.temperature > 0 || model.sensorData.humidity > 0 || model.sensorData.power > 0);
  }
}
