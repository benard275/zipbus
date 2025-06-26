import 'package:flutter/material.dart';

class DeliveryTickWidget extends StatelessWidget {
  final String deliveryStatus;
  final double size;
  final Color? sentColor;
  final Color? deliveredColor;
  final Color? readColor;

  const DeliveryTickWidget({
    super.key,
    required this.deliveryStatus,
    this.size = 16.0,
    this.sentColor,
    this.deliveredColor,
    this.readColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultSentColor = sentColor ?? Colors.grey.shade400;
    final defaultDeliveredColor = deliveredColor ?? Colors.grey.shade400;
    final defaultReadColor = readColor ?? Colors.blue;

    return SizedBox(
      width: size * 1.5, // Accommodate double ticks
      height: size,
      child: CustomPaint(
        painter: DeliveryTickPainter(
          deliveryStatus: deliveryStatus,
          size: size,
          sentColor: defaultSentColor,
          deliveredColor: defaultDeliveredColor,
          readColor: defaultReadColor,
        ),
      ),
    );
  }
}

class DeliveryTickPainter extends CustomPainter {
  final String deliveryStatus;
  final double size;
  final Color sentColor;
  final Color deliveredColor;
  final Color readColor;

  DeliveryTickPainter({
    required this.deliveryStatus,
    required this.size,
    required this.sentColor,
    required this.deliveredColor,
    required this.readColor,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (deliveryStatus) {
      case 'sent':
        _drawSingleTick(canvas, paint, sentColor);
        break;
      case 'delivered':
        _drawDoubleTick(canvas, paint, deliveredColor);
        break;
      case 'read':
        _drawDoubleTick(canvas, paint, readColor);
        break;
      default:
        _drawSingleTick(canvas, paint, sentColor);
    }
  }

  void _drawSingleTick(Canvas canvas, Paint paint, Color color) {
    paint.color = color;
    
    final path = Path();
    final tickSize = size * 0.8;
    final startX = (size * 1.5 - tickSize) / 2;
    final startY = size * 0.6;
    
    // Draw single checkmark
    path.moveTo(startX, startY);
    path.lineTo(startX + tickSize * 0.4, startY + tickSize * 0.3);
    path.lineTo(startX + tickSize, startY - tickSize * 0.2);
    
    canvas.drawPath(path, paint);
  }

  void _drawDoubleTick(Canvas canvas, Paint paint, Color color) {
    paint.color = color;
    
    final tickSize = size * 0.6;
    final spacing = size * 0.3;
    
    // First tick (left)
    final path1 = Path();
    final startX1 = size * 0.1;
    final startY = size * 0.6;
    
    path1.moveTo(startX1, startY);
    path1.lineTo(startX1 + tickSize * 0.4, startY + tickSize * 0.3);
    path1.lineTo(startX1 + tickSize, startY - tickSize * 0.2);
    
    // Second tick (right, slightly overlapping)
    final path2 = Path();
    final startX2 = startX1 + spacing;
    
    path2.moveTo(startX2, startY);
    path2.lineTo(startX2 + tickSize * 0.4, startY + tickSize * 0.3);
    path2.lineTo(startX2 + tickSize, startY - tickSize * 0.2);
    
    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(DeliveryTickPainter oldDelegate) {
    return oldDelegate.deliveryStatus != deliveryStatus ||
           oldDelegate.sentColor != sentColor ||
           oldDelegate.deliveredColor != deliveredColor ||
           oldDelegate.readColor != readColor;
  }
}

/// Animated version of delivery tick widget
class AnimatedDeliveryTickWidget extends StatefulWidget {
  final String deliveryStatus;
  final double size;
  final Color? sentColor;
  final Color? deliveredColor;
  final Color? readColor;
  final Duration animationDuration;

  const AnimatedDeliveryTickWidget({
    super.key,
    required this.deliveryStatus,
    this.size = 16.0,
    this.sentColor,
    this.deliveredColor,
    this.readColor,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedDeliveryTickWidget> createState() => _AnimatedDeliveryTickWidgetState();
}

class _AnimatedDeliveryTickWidgetState extends State<AnimatedDeliveryTickWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(AnimatedDeliveryTickWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deliveryStatus != widget.deliveryStatus) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: DeliveryTickWidget(
            deliveryStatus: widget.deliveryStatus,
            size: widget.size,
            sentColor: widget.sentColor,
            deliveredColor: widget.deliveredColor,
            readColor: widget.readColor,
          ),
        );
      },
    );
  }
}

/// Helper function to get delivery status display text
String getDeliveryStatusText(String deliveryStatus) {
  switch (deliveryStatus) {
    case 'sent':
      return 'Sent';
    case 'delivered':
      return 'Delivered';
    case 'read':
      return 'Read';
    default:
      return 'Sent';
  }
}

/// Helper function to get appropriate tick color based on theme
Color getTickColor(BuildContext context, String deliveryStatus, {bool isMyMessage = true}) {
  if (!isMyMessage) {
    // For received messages, don't show delivery status
    return Colors.transparent;
  }

  switch (deliveryStatus) {
    case 'sent':
      return Colors.grey.shade400;
    case 'delivered':
      return Colors.grey.shade400;
    case 'read':
      return Colors.blue;
    default:
      return Colors.grey.shade400;
  }
}
