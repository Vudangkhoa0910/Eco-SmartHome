import 'package:smart_home/config/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MusicWidget extends StatelessWidget {
  const MusicWidget({Key? key, this.isCompact = false}) : super(key: key);

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        print('Music widget constraints: ${constraints.maxWidth}');
        
        return Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: getProportionateScreenHeight(isCompact ? 60 : 90),
            maxHeight: getProportionateScreenHeight(isCompact ? 80 : 110),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isCompact ? 12 : 20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: isCompact ? 10 : 20,
                offset: Offset(0, isCompact ? 2 : 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(isCompact ? 8 : 12)),
            child: Row(
              children: [
                // Album Art
                Container(
                  width: getProportionateScreenHeight(isCompact ? 35 : 50),
                  height: getProportionateScreenHeight(isCompact ? 35 : 50),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B73FF), Color(0xFF9C88FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B73FF).withOpacity(0.3),
                        blurRadius: isCompact ? 6 : 10,
                        offset: Offset(0, isCompact ? 2 : 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: Colors.white,
                    size: isCompact ? 16 : 24,
                  ),
                ),
                
                SizedBox(width: getProportionateScreenWidth(isCompact ? 8 : 12)),
                
                // Song Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Nhạc thư giãn',
                        style: TextStyle(
                          fontSize: isCompact ? 11 : 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2D3748),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (!isCompact) ...[
                        SizedBox(height: 2),
                        Text(
                          'Âm thanh thông minh',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF9E9E9E),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        SizedBox(height: 6),
                        // Progress Bar
                        Container(
                          width: double.infinity,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.6, // 60% progress
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6B73FF), Color(0xFF9C88FF)],
                                ),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(width: getProportionateScreenWidth(8)),
                
                // Control Buttons
                if (!isCompact)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildControlButton(Icons.skip_previous, () {
                        print('Previous button tapped');
                      }),
                      SizedBox(width: 4),
                      _buildControlButton(Icons.play_arrow, () {
                        print('Play button tapped');
                      }, isPlay: true),
                      SizedBox(width: 4),
                      _buildControlButton(Icons.skip_next, () {
                        print('Next button tapped');
                      }),
                    ],
                  )
                else
                  // Compact control - just play button
                  _buildControlButton(Icons.play_arrow, () {
                    print('Play button tapped');
                  }, isPlay: true, isCompact: isCompact),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildControlButton(IconData icon, VoidCallback onTap, {bool isPlay = false, bool isCompact = false}) {
    return GestureDetector(
      onTap: () {
        print('Music control button tapped: ${icon.toString()}');
        onTap();
      },
      child: Container(
        width: isCompact ? (isPlay ? 24 : 20) : (isPlay ? 32 : 28),
        height: isCompact ? (isPlay ? 24 : 20) : (isPlay ? 32 : 28),
        decoration: BoxDecoration(
          color: isPlay 
            ? const Color(0xFF6B73FF) 
            : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(isCompact ? (isPlay ? 12 : 10) : (isPlay ? 16 : 14)),
          boxShadow: isPlay ? [
            BoxShadow(
              color: const Color(0xFF6B73FF).withOpacity(0.3),
              blurRadius: isCompact ? 4 : 8,
              offset: Offset(0, isCompact ? 2 : 3),
            ),
          ] : [],
        ),
        child: Icon(
          icon,
          color: isPlay ? Colors.white : const Color(0xFF9E9E9E),
          size: isCompact ? (isPlay ? 12 : 10) : (isPlay ? 16 : 14),
        ),
      ),
    );
  }
}
