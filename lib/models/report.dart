// lib/models/report.dart

// This is a simple placeholder model. The actual report data is stored as a Map
// inside the 'reports' array in the Product document, but this class is needed
// to resolve the import in the service file.
class Report {
  // Define fields if you ever need to process reports outside of the service file
  // For now, it can remain empty or contain basic structure for clarity.
  final String userId;
  final String comment;
  final DateTime timestamp;

  Report({required this.userId, required this.comment, required this.timestamp});
}