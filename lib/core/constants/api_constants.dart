class ApiConstants {
  // Use 10.0.2.2 for Android emulator to access localhost, 
  // or your machine's local IP (e.g. 192.168.1.x) for physical devices.
  static const String baseUrlDev = 'http://10.0.2.2:5000/api';
  
  // Update this to your deployed Render URL
  static const String baseUrlProd = 'https://pulse-backend-j86c.onrender.com/api';

  // Toggle this depending on the environment
  static const String baseUrl = baseUrlProd;
}
