import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final dynamic status; // Can be int or String

  const StatusBadge({super.key, required this.status});

  String _getStatusString() {
    if (status is int) {
      switch (status) {
        case 1:
          return 'PENDING';
        case 2:
          return 'DELIVERED';
        case 3:
          return 'ON HOLD';
        case 4:
          return 'RETURNED';
        default:
          return 'UNKNOWN';
      }
    }
    return status.toString();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    final String statusStr = _getStatusString().toUpperCase();

    switch (statusStr) {
      case 'DELIVERED':
      case 'RECEIVED':
      case 'COMPLETED':
        bgColor = AppColors.greenLightest;
        textColor = AppColors.greenDarker;
        break;
      case 'PENDING':
      case 'MARKED_AS_NEXT':
        bgColor = AppColors.yellowLighter;
        textColor = AppColors.yellowDarker;
        break;
      case 'ON HOLD':
      case 'ONHOLD':
      case 'PICKUP_ON_HOLD':
        bgColor = AppColors.orangeLight.withOpacity(0.2);
        textColor = AppColors.orangeDarker;
        break;
      case 'RETURNED':
      case 'PICKUP_REJECT':
      case 'FAILED':
        bgColor = AppColors.redLighter;
        textColor = AppColors.redDarker;
        break;
      case 'PARTIAL DELIVERY':
        bgColor = AppColors.violet.withOpacity(0.2);
        textColor = AppColors.violet;
        break;
      default:
        bgColor = AppColors.greyLight;
        textColor = AppColors.greyDarker;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusStr,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
