class ApiEndpoints {
  static const String talariaBase = 'https://api-hermes.pathao.com/talaria';
  static const String omsBase = 'https://api-hermes.pathao.com/api/agents/v1/oms';
  static const String cdnBase = 'https://cdn.pathao.com';

  // Auth
  static const String token = '/api/v1/issue-token';
  static const String logout = '/api/v1/logout';
  static const String resetPassword = '/api/v1/user/reset-password';

  // Profile & Ratings
  static const String userProfile = '/api/v1/user';
  static const String profileImage = '/api/v1/user/profile-image';
  static const String profileToggle = '/api/v1/user/profile-toggle';
  static const String deleteAccount = '/api/v1/user/delete-account';
  static const String agentRatings = '/api/v1/user/agent-ratings';
  static const String agentReviews = '/api/v1/user/agent-reviews';

  // Dashboard & Attendance
  static const String dashboard = '/api/v1/dashboard';
  static const String dailyAttendance = '/api/v1/attendances/daily';
  static const String attendanceEntry = '/api/v1/attendances/submit/entry';
  static const String attendanceExit = '/api/v1/attendances/submit/exit';

  // Deliveries
  static const String deliveryList = '/api/v1/user/delivery';
  static const String deliveryDetails = '/api/v1/user/delivery/{consignmentId}';
  static const String deliveryUpdate = '/api/v1/user/delivery';
  static const String deliveryComplete = '/api/v1/user/delivery/check';
  static const String deliveryQcOtp = '/api/v1/user/delivery/check/qc-otp';
  static const String deliverySmsResend = '/api/v1/user/delivery/sms-resend';
  static const String sortDelivery = '/api/v1/user/sort-delivery';
  static const String approveDelivery = '/api/v1/user/deliveries/{runRouteOrderId}/approve';
  static const String holdReasons = '/api/v1/delivery/hold-reasons';
  static const String returnReasons = '/api/v1/delivery/return-reasons';

  // Pickups
  static const String pickupList = '/api/v1/user/pickup';
  static const String nextPickup = '/api/v1/user/pickup/{id}';
  static const String merchantDetails = '/api/v1/user/pickup/{storeId}';
  static const String merchantPackageUpdate = '/api/v1/user/pickup';
  static const String pickupDone = '/api/v1/user/pickup-done';
  static const String pickupDoneCheck = '/api/v1/user/pickup-done-check';
  static const String pickupSmsResend = '/api/v1/user/pickup-sms-resend';
  static const String slotPickupDone = '/api/v1/user/slot-pickup/done';
  static const String slotPickupConfirm = '/api/v1/user/slot-pickup/confirm';
  static const String slotPickupPickAgain = '/api/v1/user/slot-pickup/pick-again';
  static const String sortPickup = '/api/v1/user/sort-pickup';

  // Returns
  static const String returnList = '/api/v1/user/return';
  static const String nextPickupReturn = '/api/v1/user/return/{storeId}';
  static const String returnStatusUpdate = '/api/v1/user/return';
  static const String returnDone = '/api/v1/user/return-done';
  static const String returnDoneCheck = '/api/v1/user/return-done-check';
  static const String returnSmsResend = '/api/v1/user/return-sms-resend';
  static const String sortReturn = '/api/v1/user/sort-return';

  // Runs, Sorting & VDA Transfers
  static const String runDetails = '/api/v1/user/runs/{runRouteId}';
  static const String transfers = '/api/v1/user/transfers';
  static const String transferStatus = '/api/v1/user/transfers/{runRouteId}';
  static const String pickMerchantOrders = '/api/v1/user/pick-merchant-orders';
  static const String pickMerchantOrdersDone = '/api/v1/user/pick-merchant-orders-done';

  // C2C Pickup
  static const String c2cPickupList = '/api/v1/user/c2c-pickup';
  static const String c2cPickupDetails = '/api/v1/user/c2c-pickup/{runRouteOrderId}';
  static const String c2cPickupConfirm = '/api/v1/user/c2c-pickup';
  static const String updateC2cPickupAttempt = '/dispatches/attempts/{attemptId}/status';

  // Cash & Payments
  static const String earnings = '/api/v1/user/earnings';
  static const String paymentInfo = '/api/v1/user/payment-info';
  static const String sendPaymentLink = '/api/v1/user/payments/send-link';
  static const String walletList = '/api/v1/wallet-list';
  static const String walletBranchList = '/api/v1/wallet-list/{walletId}/branch';
  static const String xdpPaymentInfo = '/api/v1/xdp-payment-info/{agentId}';
  static const String merchantSearch = '/api/v1/user/merchant-search';

  // Location & Pings
  static const String latlon = '/api/v1/user/latlon';
  static const String pings = '/api/v1/pings';
  static const String pingsConfig = '/api/v1/pings/config';

  // Messages
  static const String allMessages = '/api/v1/user/deliveries/messages';
  static const String consignmentMessages = '/api/v1/user/deliveries/{consignment_id}/messages';
  static const String sendNewMessage = '/api/v1/user/deliveries/{consignment_id}/messages';
  static const String markMessageSeen = '/api/v1/user/deliveries/{consignment_id}/messages';

  // Push Notification & Broadcast
  static const String pushSubscribe = '/api/v1/user/push/subscribe';
  static const String pushUnsubscribe = '/api/v1/user/push/unsubscribe';
  static const String broadcastUserAuth = '/api/v1/broadcast/user-auth/agent';
  static const String broadcastChannelAuth = '/api/v1/broadcast/auth/agent';

  // QC & Upload
  static const String qcRequest = '/api/v1/qc-request';
  static const String cdnUpload = '/api/v1/cdn/upload';
}
