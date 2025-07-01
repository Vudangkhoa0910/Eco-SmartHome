class ElectricityCalculator {
  // Bậc thang giá điện sinh hoạt tại Việt Nam (VND/kWh)
  static const Map<String, double> electricityTiers = {
    'tier1': 1806, // 0-50 kWh
    'tier2': 1866, // 51-100 kWh
    'tier3': 2167, // 101-200 kWh
    'tier4': 2729, // 201-300 kWh
    'tier5': 3050, // 301-400 kWh
    'tier6': 3151, // Trên 400 kWh
  };

  /// Tính tiền điện theo bậc thang
  static double calculateElectricityBill(double kWh) {
    if (kWh <= 0) return 0;
    
    double totalBill = 0;
    double remainingKWh = kWh;
    
    // Bậc 1: 0-50 kWh
    if (remainingKWh > 0) {
      double tier1Usage = remainingKWh > 50 ? 50 : remainingKWh;
      totalBill += tier1Usage * electricityTiers['tier1']!;
      remainingKWh -= tier1Usage;
    }
    
    // Bậc 2: 51-100 kWh
    if (remainingKWh > 0) {
      double tier2Usage = remainingKWh > 50 ? 50 : remainingKWh;
      totalBill += tier2Usage * electricityTiers['tier2']!;
      remainingKWh -= tier2Usage;
    }
    
    // Bậc 3: 101-200 kWh
    if (remainingKWh > 0) {
      double tier3Usage = remainingKWh > 100 ? 100 : remainingKWh;
      totalBill += tier3Usage * electricityTiers['tier3']!;
      remainingKWh -= tier3Usage;
    }
    
    // Bậc 4: 201-300 kWh
    if (remainingKWh > 0) {
      double tier4Usage = remainingKWh > 100 ? 100 : remainingKWh;
      totalBill += tier4Usage * electricityTiers['tier4']!;
      remainingKWh -= tier4Usage;
    }
    
    // Bậc 5: 301-400 kWh
    if (remainingKWh > 0) {
      double tier5Usage = remainingKWh > 100 ? 100 : remainingKWh;
      totalBill += tier5Usage * electricityTiers['tier5']!;
      remainingKWh -= tier5Usage;
    }
    
    // Bậc 6: Trên 400 kWh
    if (remainingKWh > 0) {
      totalBill += remainingKWh * electricityTiers['tier6']!;
    }
    
    return totalBill;
  }

  /// Tính tiền điện đơn giản (dùng giá trung bình)
  static double calculateSimpleBill(double kWh) {
    const double averageRate = 2400; // VND/kWh
    return kWh * averageRate;
  }

  /// Chuyển đổi từ Watt sang kWh
  static double wattsToKWh(double watts, double hours) {
    return (watts * hours) / 1000;
  }

  /// Tính chi phí theo giờ
  static double calculateHourlyCost(double watts) {
    double kWh = wattsToKWh(watts, 1);
    return calculateSimpleBill(kWh);
  }

  /// Tính chi phí theo ngày
  static double calculateDailyCost(double watts, double hoursPerDay) {
    double kWh = wattsToKWh(watts, hoursPerDay);
    return calculateSimpleBill(kWh);
  }

  /// Tính chi phí theo tháng
  static double calculateMonthlyCost(double watts, double hoursPerDay) {
    double dailyCost = calculateDailyCost(watts, hoursPerDay);
    return dailyCost * 30;
  }

  /// Ước tính chi phí dựa trên usage percentage
  static double estimateCostFromUsage(double watts, double usagePercentage, String timeRange) {
    double hours = _getHoursFromTimeRange(timeRange);
    double actualHours = (usagePercentage / 100) * hours;
    double kWh = wattsToKWh(watts, actualHours);
    return calculateSimpleBill(kWh);
  }

  static double _getHoursFromTimeRange(String timeRange) {
    switch (timeRange) {
      case '1h':
        return 1;
      case '6h':
        return 6;
      case '24h':
        return 24;
      case '7d':
        return 24 * 7;
      case '30d':
        return 24 * 30;
      default:
        return 24;
    }
  }

  /// Format tiền tệ Việt Nam
  static String formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M ₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K ₫';
    } else {
      return '${amount.toStringAsFixed(0)} ₫';
    }
  }
}
