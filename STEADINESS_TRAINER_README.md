# Steadiness Trainer - Flutter Implementation

## Overview
The Steadiness Trainer is a Flutter implementation of the HTML-based steadiness trainer, designed to help users improve their grip steadiness and shooting accuracy using BLE sensor data instead of device motion sensors.

## Features

### 🎯 **Target System**
- **6 Concentric Rings**: Rings 10-5 representing accuracy levels
- **Ring 10**: Perfect center (0° movement)
- **Ring 5**: Minimum acceptable accuracy (0.10° movement)
- **Visual Crosshair**: Center reference lines

### 📱 **Sensor Integration**
- **BLE RT Sensor**: Uses connected sensor instead of device gyroscope
- **Real-time Movement**: Tracks X, Y, Z movement data
- **Smart Visibility**: Hysteresis-based dot visibility to prevent flickering

### 🎬 **Training Features**
- **Live Movement Tracking**: Real-time dot position based on sensor data
- **Shot Scoring**: Score based on current dot position when shot is taken
- **Movement Log**: Detailed log of all shots with timestamps and scores
- **Steady Hold Detection**: Measures time spent in stable position

### ⚙️ **Customizable Settings**
- **Trace Length**: Adjustable from 20-400 points
- **Dot Easing**: Smoothing factor from 0.0-0.5
- **Rate Limiting**: Prevents jarring movements

## How to Use

### 1. **Setup**
- Ensure RT Sensor is connected via BLE
- Navigate to Training → Quick Start → Steadiness Trainer

### 2. **Training Flow**
1. **Start Training**: Tap "Start Training" to begin sensor data collection
2. **Hold Steady**: Keep your firearm steady (dot should stay near center)
3. **Take Shot**: Tap "Shot" when ready to record your accuracy
4. **Review Score**: Check your score and movement data
5. **Stop Training**: End session when complete

### 3. **Scoring System**
- **Score 10**: Perfect center (≤0.01° movement)
- **Score 9-6**: Gradual degradation based on distance from center
- **Score 5**: Maximum acceptable movement (0.10°)
- **Score 0**: Movement exceeds acceptable range

## Technical Implementation

### **Architecture**
- **BLoC Pattern**: Uses existing TrainingSessionBloc and BleScanBloc
- **Custom Painters**: CrosshairPainter and TracePainter for visual elements
- **State Management**: Local state for training session and UI updates

### **Sensor Data Processing**
```dart
void _processSensorData(dynamic sensorPoint) {
  // Extract X, Y, Z coordinates from sensor
  // Calculate angular movement magnitude
  // Apply smoothing and rate limiting
  // Update dot position and visibility
}
```

### **Key Constants**
```dart
static const double TABLE_REST_DEG = 0.01;      // Resting threshold
static const double HOLD_STABLE_DEG = 0.10;     // Stability threshold
static const double VISUAL_RING5_DEG = 0.10;    // Visual mapping
static const int HYSTERESIS_DWELL_MS = 60;      // Hysteresis delay
```

### **Ring Calculation**
```dart
// Ring radii calculated dynamically
const double ring5Radius = 190.0;
const double bandWidth = ring5Radius / 5.5;
const double r10 = bandWidth / 2;

// Each ring gets equal width bands
_ringRadii[10] = r10;
_ringRadii[9] = r10 + 1 * bandWidth;
// ... etc
```

## Navigation

### **From Training Programs Page**
- Quick Start section now includes both Live Training and Steadiness Trainer
- Purple button for Steadiness Trainer when sensor is connected

### **From Live Training Page**
- Purple "Open Steadiness Trainer" button below training controls
- Direct access to steadiness training mode

## UI Components

### **Target Display**
- 400x400 circular target with concentric rings
- Real-time moving dot with glow effect
- Crosshair reference lines
- Trace path visualization

### **Control Panel**
- Start/Stop Training buttons
- Shot button for scoring
- Reset button to clear data
- Settings sliders for customization

### **Metrics Display**
- Live θ (angular movement) display
- Movement status indicator
- Steady hold timer
- Shot counter

### **Shot Log**
- Timestamp, angle, and score for each shot
- Color-coded score indicators
- Scrollable list of recent shots

## Dependencies

### **Required Packages**
- `flutter_bloc`: State management
- `flutter/services`: Haptic feedback
- `dart:math`: Mathematical calculations

### **Existing Dependencies**
- `TracePainter`: For movement trace visualization
- `BleScanBloc`: BLE connection management
- `TrainingSessionBloc`: Training session state

## Future Enhancements

### **Planned Features**
- [ ] Advanced analytics and progress tracking
- [ ] Multiple training modes (precision, speed, endurance)
- [ ] Export training data and reports
- [ ] Integration with training programs
- [ ] Custom target configurations

### **Potential Improvements**
- [ ] Enhanced trace visualization with different colors for shot phases
- [ ] Audio feedback for different score levels
- [ ] Calibration wizard for sensor setup
- [ ] Offline mode with device sensors as fallback

## Troubleshooting

### **Common Issues**
1. **Sensor Not Connected**: Ensure RT Sensor is paired and connected
2. **No Movement Detection**: Check sensor permissions and BLE status
3. **Inaccurate Scoring**: Verify sensor calibration and positioning
4. **Performance Issues**: Reduce trace length or disable advanced features

### **Debug Information**
- Check console for sensor data processing logs
- Verify BLE connection status in app
- Monitor sensor data flow in TrainingSessionBloc

## Contributing
This feature follows the existing project architecture and coding standards. When making changes:
1. Maintain BLoC pattern consistency
2. Follow existing color scheme and UI patterns
3. Add appropriate error handling and validation
4. Update documentation for any new features
