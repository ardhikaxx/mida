import 'package:flutter/material.dart';
import '../models/icd_code.dart';

class DetailScreen extends StatelessWidget {
  final IcdCode code;

  const DetailScreen({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(code.classification)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  code.code,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              code.description,
              style: theme.textTheme.titleLarge?.copyWith(height: 1.4),
            ),
            if (code.chapter != null) ...[
              const SizedBox(height: 32),
              _infoRow(theme, 'Chapter', code.chapter!),
            ],
            if (code.chapterTitle != null) ...[
              const SizedBox(height: 16),
              _infoRow(theme, 'Category', code.chapterTitle!),
            ],
            const SizedBox(height: 16),
            _infoRow(theme, 'Classification', code.classification),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          )),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodyLarge),
        ),
      ],
    );
  }
}
