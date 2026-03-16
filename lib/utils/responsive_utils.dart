import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Responsive utility class for consistent sizing across different screen sizes
class ResponsiveUtils {
  final BuildContext context;
  
  ResponsiveUtils(this.context);

  /// Get screen width
  double get screenWidth => MediaQuery.of(context).size.width;
  
  /// Get screen height
  double get screenHeight => MediaQuery.of(context).size.height;
  
  /// Get screen size category
  ScreenSize get screenSize {
    if (screenWidth < 360) return ScreenSize.small;
    if (screenWidth < 400) return ScreenSize.medium;
    if (screenWidth < 600) return ScreenSize.large;
    return ScreenSize.tablet;
  }
  
  /// Responsive font size based on screen width
  /// Uses a base size and scales proportionally with constraints
  double fontSize(double baseSize) {
    // Base reference width (typical phone width)
    const double baseWidth = 375.0;
    
    // Calculate scale factor
    double scaleFactor = screenWidth / baseWidth;
    
    // Apply constraints to prevent extreme sizes
    scaleFactor = math.max(0.8, math.min(scaleFactor, 1.3));
    
    return baseSize * scaleFactor;
  }
  
  /// Responsive spacing (for padding, margin, etc.)
  double spacing(double baseSpacing) {
    const double baseWidth = 375.0;
    double scaleFactor = screenWidth / baseWidth;
    
    // Less aggressive scaling for spacing
    scaleFactor = math.max(0.85, math.min(scaleFactor, 1.2));
    
    return baseSpacing * scaleFactor;
  }
  
  /// Responsive icon size
  double iconSize(double baseSize) {
    const double baseWidth = 375.0;
    double scaleFactor = screenWidth / baseWidth;
    
    scaleFactor = math.max(0.8, math.min(scaleFactor, 1.25));
    
    return baseSize * scaleFactor;
  }
  
  /// Responsive button height
  double buttonHeight(double baseHeight) {
    return spacing(baseHeight);
  }
  
  /// Responsive width percentage
  double widthPercent(double percent) {
    return screenWidth * (percent / 100);
  }
  
  /// Responsive height percentage
  double heightPercent(double percent) {
    return screenHeight * (percent / 100);
  }
  
  /// Get min dimension (useful for square or circular elements)
  double get minDimension => math.min(screenWidth, screenHeight);
  
  /// Responsive size based on min dimension (for maintaining aspect ratio)
  double sizeFromMinDimension(double percent) {
    return minDimension * (percent / 100);
  }
  
  /// Check if screen is small
  bool get isSmallScreen => screenWidth < 360;
  
  /// Check if screen is tablet
  bool get isTablet => screenWidth >= 600;
}

/// Extension for easy access to ResponsiveUtils from any BuildContext
extension ResponsiveContext on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
}

/// Screen size categories
enum ScreenSize {
  small,   // < 360
  medium,  // 360-400
  large,   // 400-600
  tablet,  // >= 600
}
