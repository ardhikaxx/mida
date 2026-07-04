import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/icd_code.dart';

enum IcdClassification {
  icd10('ICD-10', 'assets/icd10.json'),
  icdMM('ICD-MM', 'assets/icd_mm.json'),
  icdPM('ICD-PM', 'assets/icd_pm.json'),
  icdO('ICD-O', 'assets/icd_o.json'),
  icd9CM('ICD-9-CM', 'assets/icd_9cm.json');

  final String label;
  final String assetPath;
  const IcdClassification(this.label, this.assetPath);

  static IcdClassification fromLabel(String label) {
    return IcdClassification.values.firstWhere((e) => e.label == label);
  }
}

class IcdService {
  final Map<IcdClassification, List<IcdCode>> _cache = {};

  Future<List<IcdCode>> load(IcdClassification type) async {
    if (_cache.containsKey(type)) return _cache[type]!;

    final jsonString = await rootBundle.loadString(type.assetPath);
    final List<dynamic> jsonList = json.decode(jsonString);
    final codes =
        jsonList.map((e) => IcdCode.fromJson(e, type.label)).toList();
    _cache[type] = codes;
    return codes;
  }

  Future<List<IcdCode>> search(IcdClassification type, String query) async {
    final codes = await load(type);
    if (query.isEmpty) return [];

    final q = query.toLowerCase();
    return codes.where((c) {
      return c.code.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          (c.chapter?.toLowerCase().contains(q) ?? false) ||
          (c.chapterTitle?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Future<IcdCode?> findByCode(IcdClassification type, String code) async {
    final codes = await load(type);
    return codes.cast<IcdCode?>().firstWhere(
          (c) => c!.code.toLowerCase() == code.toLowerCase(),
          orElse: () => null,
        );
  }
}
