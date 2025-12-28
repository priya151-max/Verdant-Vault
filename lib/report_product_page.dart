// lib/report_product_page.dart

import 'package:flutter/material.dart';
import 'package:verdant_vault/constants.dart';
import 'package:verdant_vault/services/mongodb_service.dart';

class ReportProductPage extends StatefulWidget {
  final String productId;
  final String userId; // The ID of the user submitting the report

  const ReportProductPage({
    super.key,
    required this.productId,
    required this.userId,
  });

  @override
  State<ReportProductPage> createState() => _ReportProductPageState();
}

class _ReportProductPageState extends State<ReportProductPage> {
  final TextEditingController _commentController = TextEditingController();
  bool _isReporting = false;

  Future<void> _submitReport() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason or comment for the report.')),
      );
      return;
    }

    setState(() {
      _isReporting = true;
    });

    try {
      // Call the MongoDB service method to handle the report
      await MongoDBService.reportProduct(
        widget.productId,
        widget.userId,
        comment,
      );

      // Success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product reported successfully. Thank you for your feedback!')),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // Error handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      setState(() {
        _isReporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Product'),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reporting Product ID: ${widget.productId.substring(0, 8)}...',
              style: headingStyle.copyWith(fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide a detailed comment explaining why this product violates our eco-friendly standards or marketplace policies.',
              style: bodyTextStyle,
            ),
            const SizedBox(height: 30),

            TextFormField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Detailed Comment (Required)',
                hintText: 'e.g., "The material listed as bamboo is actually a rayon blend."',
                border: OutlineInputBorder(borderRadius: cardBorderRadius),
                enabledBorder: OutlineInputBorder(borderRadius: cardBorderRadius, borderSide: const BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderRadius: cardBorderRadius, borderSide: const BorderSide(color: primaryColor, width: 2)),
              ),
              maxLines: 5,
              maxLength: 500,
            ),
            const SizedBox(height: 40),

            _isReporting
                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                : ElevatedButton.icon(
              onPressed: _submitReport,
              icon: const Icon(Icons.flag, color: Colors.white),
              label: const Text('Submit Report', style: TextStyle(fontSize: 18, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Note: If this product receives 5 or more unique reports, it will be automatically removed from the marketplace.',
                textAlign: TextAlign.center,
                style: bodyTextStyle.copyWith(color: Colors.black54, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}