class ElectricityBillService {
  static final ElectricityBillService _instance = ElectricityBillService._internal();
  factory ElectricityBillService() => _instance;
  ElectricityBillService._internal();

  // Electricity rate tiers (VND per kWh)
  Map<String, ElectricityTier> _rateTiers = {
    'residential': ElectricityTier(
      name: 'Sinh hoạt',
      tiers: [
        TierRate(from: 0, to: 50, rate: 1678),
        TierRate(from: 51, to: 100, rate: 1734),
        TierRate(from: 101, to: 200, rate: 2014),
        TierRate(from: 201, to: 300, rate: 2536),
        TierRate(from: 301, to: 400, rate: 2834),
        TierRate(from: 401, to: double.infinity, rate: 2927),
      ],
    ),
    'business': ElectricityTier(
      name: 'Kinh doanh',
      tiers: [
        TierRate(from: 0, to: double.infinity, rate: 2500),
      ],
    ),
    'industrial': ElectricityTier(
      name: 'Công nghiệp',
      tiers: [
        TierRate(from: 0, to: double.infinity, rate: 1800),
      ],
    ),
  };

  String _currentTierType = 'residential';
  String get currentTierType => _currentTierType;

  ElectricityTier get currentTier => _rateTiers[_currentTierType]!;
  Map<String, ElectricityTier> get allTiers => _rateTiers;

  void setTierType(String tierType) {
    if (_rateTiers.containsKey(tierType)) {
      _currentTierType = tierType;
    }
  }

  /// Calculate electricity bill based on kWh usage
  ElectricityBill calculateBill(double totalKwh) {
    final tier = _rateTiers[_currentTierType]!;
    return _calculateTieredBill(totalKwh, tier);
  }

  ElectricityBill _calculateTieredBill(double totalKwh, ElectricityTier tier) {
    double totalCost = 0;
    double remainingKwh = totalKwh;
    Map<String, TierUsage> tierUsages = {};

    for (var tierRate in tier.tiers) {
      if (remainingKwh <= 0) break;

      double tierCapacity = tierRate.to - tierRate.from;
      double usedInTier = remainingKwh > tierCapacity ? tierCapacity : remainingKwh;
      
      double tierCost = usedInTier * tierRate.rate;
      totalCost += tierCost;
      remainingKwh -= usedInTier;

      tierUsages['${tierRate.from.toInt()}-${tierRate.to == double.infinity ? '∞' : tierRate.to.toInt()}'] = 
          TierUsage(
            kwh: usedInTier,
            rate: tierRate.rate,
            cost: tierCost,
          );
    }

    return ElectricityBill(
      totalKwh: totalKwh,
      totalCost: totalCost,
      tierType: _currentTierType,
      tierUsages: tierUsages,
      calculatedAt: DateTime.now(),
    );
  }

  /// Calculate cost for a specific power reading (instantaneous)
  double calculateInstantCost(double powerWatts, Duration duration) {
    final powerKw = powerWatts / 1000.0;
    final energyKwh = powerKw * (duration.inMilliseconds / 3600000.0); // Convert to hours
    
    // Use simple average rate for instant calculation
    final avgRate = _getAverageRate();
    return energyKwh * avgRate;
  }

  double _getAverageRate() {
    final tier = _rateTiers[_currentTierType]!;
    if (tier.tiers.length == 1) {
      return tier.tiers.first.rate;
    }
    
    // Calculate weighted average for residential tiers
    double totalRate = 0;
    int count = 0;
    
    for (var tierRate in tier.tiers) {
      if (tierRate.to != double.infinity) {
        totalRate += tierRate.rate;
        count++;
      }
    }
    
    return count > 0 ? totalRate / count : 2000; // Default fallback
  }

  /// Get daily/monthly cost estimation based on current power usage
  Map<String, double> getUsageEstimation(double currentPowerWatts) {
    final currentPowerKw = currentPowerWatts / 1000.0;
    
    // Estimate daily usage (24 hours)
    final dailyKwh = currentPowerKw * 24;
    final dailyBill = calculateBill(dailyKwh);
    
    // Estimate monthly usage (30 days)
    final monthlyKwh = dailyKwh * 30;
    final monthlyBill = calculateBill(monthlyKwh);
    
    return {
      'daily_kwh': dailyKwh,
      'daily_cost': dailyBill.totalCost,
      'monthly_kwh': monthlyKwh,
      'monthly_cost': monthlyBill.totalCost,
      'avg_rate': _getAverageRate(),
    };
  }
}

class ElectricityTier {
  final String name;
  final List<TierRate> tiers;

  ElectricityTier({
    required this.name,
    required this.tiers,
  });
}

class TierRate {
  final double from;
  final double to;
  final double rate; // VND per kWh

  TierRate({
    required this.from,
    required this.to,
    required this.rate,
  });
}

class TierUsage {
  final double kwh;
  final double rate;
  final double cost;

  TierUsage({
    required this.kwh,
    required this.rate,
    required this.cost,
  });
}

class ElectricityBill {
  final double totalKwh;
  final double totalCost;
  final String tierType;
  final Map<String, TierUsage> tierUsages;
  final DateTime calculatedAt;

  ElectricityBill({
    required this.totalKwh,
    required this.totalCost,
    required this.tierType,
    required this.tierUsages,
    required this.calculatedAt,
  });

  double get averageRate => totalKwh > 0 ? totalCost / totalKwh : 0;
}
