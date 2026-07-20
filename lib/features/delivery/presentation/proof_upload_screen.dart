import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/delivery_provider.dart';

class ProofUploadScreen extends ConsumerStatefulWidget {
  final String consignmentId;

  const ProofUploadScreen({super.key, required this.consignmentId});

  @override
  ConsumerState<ProofUploadScreen> createState() => _ProofUploadScreenState();
}

class _ProofUploadScreenState extends ConsumerState<ProofUploadScreen> {
  File? _image;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.any);

      if (result != null && result.files.single.path != null) {
        setState(() {
          _image = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting file: $e')),
      );
    }
  }

  void _uploadProof() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture a delivery photo proof')),
      );
      return;
    }

    setState(() => _isUploading = true);

    // Call actual CDN upload
    final imageUrl = await ref.read(deliveryProvider.notifier).uploadFileToCdn(
      filePath: _image!.path,
      type: 'delivery_slip', // Most likely type for delivery proof
      consignmentId: widget.consignmentId,
    );

    setState(() => _isUploading = false);
    if (mounted) {
      if (imageUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery proof uploaded successfully!'), backgroundColor: AppColors.statusGood),
        );
        context.go('/home'); // return to dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload proof. Try again.'), backgroundColor: AppColors.statusBad),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Proof', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Upload Delivery Proof Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a clear picture of the delivered parcel at the customer destination.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.greyDarker, fontSize: 13),
            ),
            const SizedBox(height: 32),

            // Captured Image Box
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.upload_file, size: 64, color: AppColors.greyDark),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              minimumSize: const Size(180, 48),
                            ),
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Upload File'),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),

            // Retake and Submit Row
            if (_image != null) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                ),
                onPressed: _pickFile,
                icon: const Icon(Icons.refresh),
                label: const Text('Select Different File'),
              ),
              const SizedBox(height: 16),
            ],

            ElevatedButton(
              onPressed: _isUploading ? null : _uploadProof,
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2),
                    )
                  : const Text('Complete Delivery'),
            ),
          ],
        ),
      ),
    );
  }
}
