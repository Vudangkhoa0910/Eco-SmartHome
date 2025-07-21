import 'package:flutter/material.dart';
import 'package:smart_home/service/theme_service.dart';
import 'package:smart_home/config/size_config.dart';

class ThemeColorPicker extends StatefulWidget {
  final Function(ColorTheme)? onThemeChanged;
  
  const ThemeColorPicker({
    Key? key,
    this.onThemeChanged,
  }) : super(key: key);

  @override
  State<ThemeColorPicker> createState() => _ThemeColorPickerState();
}

class _ThemeColorPickerState extends State<ThemeColorPicker>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  ColorTheme? _selectedTheme;

  @override
  void initState() {
    super.initState();
    _selectedTheme = ThemeService.instance.currentTheme;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectTheme(ColorTheme theme) async {
    setState(() {
      _selectedTheme = theme;
    });
    
    // Apply theme with animation
    await ThemeService.instance.changeTheme(theme);
    
    // Notify parent widget
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(theme);
    }
    
    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Đã áp dụng theme "${ThemeService.instance.allPalettes[theme]!.name}"'),
            ],
          ),
          backgroundColor: ThemeService.instance.currentPalette.primaryColor,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với handle để kéo
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: ThemeService.instance.currentPalette.gradientColors.take(2).toList(),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.palette,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: getProportionateScreenWidth(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chọn Theme Màu Sắc',
                            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Tùy chỉnh giao diện theo sở thích',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: getProportionateScreenHeight(16)),
                
                // Theme Grid - Responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: getProportionateScreenWidth(10),
                        mainAxisSpacing: getProportionateScreenHeight(10),
                        childAspectRatio: 1.3,
                      ),
                      itemCount: ThemeService.instance.allPalettes.length,
                      itemBuilder: (context, index) {
                        final theme = ColorTheme.values[index];
                        final palette = ThemeService.instance.allPalettes[theme]!;
                        final isSelected = _selectedTheme == theme;
                        
                        return _buildThemeCard(theme, palette, isSelected);
                      },
                    );
                  },
                ),
                
                SizedBox(height: getProportionateScreenHeight(12)),
                
                // Current selection info - Compact
                if (_selectedTheme != null) ...[
                  Divider(height: 1),
                  SizedBox(height: getProportionateScreenHeight(8)),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: ThemeService.instance.currentPalette.primaryColor,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Theme: ${ThemeService.instance.allPalettes[_selectedTheme]!.name}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: ThemeService.instance.currentPalette.primaryColor,
                                ),
                              ),
                              Text(
                                ThemeService.instance.allPalettes[_selectedTheme]!.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeCard(ColorTheme theme, ThemeColorPalette palette, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectTheme(theme),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: palette.gradientColors.take(2).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: palette.primaryColor.withOpacity(isSelected ? 0.3 : 0.1),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 6 : 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(getProportionateScreenWidth(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          palette.icon,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      Spacer(),
                      if (isSelected)
                        Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.check,
                            color: palette.primaryColor,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  
                  Spacer(),
                  
                  Text(
                    palette.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  SizedBox(height: 4),
                  
                  // Color preview dots
                  Row(
                    children: palette.gradientColors.take(3).map((color) {
                      return Container(
                        margin: EdgeInsets.only(right: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // Ripple effect overlay
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectTheme(theme),
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
