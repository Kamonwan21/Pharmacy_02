import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';
import 'api_service.dart';
import 'login.dart';

class Functionmonth extends StatefulWidget {
  final String hn;
  const Functionmonth({super.key, required this.hn});

  @override
  State<Functionmonth> createState() => _FunctionmonthState();
}

class _FunctionmonthState extends State<Functionmonth> {
  Map<String, dynamic>? patientDetails;
  Map<String, List<dynamic>>? groupedMedications;
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _fetchPatientDetails();
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _fetchPatientDetails() async {
    final apiService = ApiService();
    try {
      final jsonResponse = await apiService.fetchPatientMonth(widget.hn);

      if (jsonResponse['status'] == '200') {
        setState(() {
          patientDetails = (jsonResponse['detailsH'] as List<dynamic>?)?.first;
          _groupMedications(jsonResponse['detailsB'] as List<dynamic>?);
        });
      } else {
        _showSnackBar(
            'Failed to load patient details: ${jsonResponse['message']}');
      }
    } catch (e) {
      _showSnackBar('An error occurred while fetching patient details.');
    }
  }

  void _groupMedications(List<dynamic>? medications) {
    if (medications == null) return;

    groupedMedications = {};
    for (var medication in medications) {
      final visitId = medication['visit_id'];
      if (groupedMedications!.containsKey(visitId)) {
        groupedMedications![visitId]!.add(medication);
      } else {
        groupedMedications![visitId] = [medication];
      }
    }

    // Optional: Sort the groups by visit_id if necessary
    groupedMedications = Map.fromEntries(
      groupedMedications!.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String _getCurrentLanguage() {
    if (patientDetails == null ||
        !patientDetails!.containsKey('base_communication_language_id')) {
      return 'EN';
    }
    return patientDetails!['base_communication_language_id'];
  }

  String getText(String thaiText, String englishText) {
    final languageId = _getCurrentLanguage();
    return languageId == 'TH' ? thaiText : englishText;
  }

  Future<void> _speak(String text) async {
    text = text.replaceAll("พ.ญ.", "แพทย์หญิง");
    text = text.replaceAll("นพ.", "นายแพทย์");
    text = text.replaceAll("ชม.", "ชั่วโมง");
    text = _removeThaiSpaces(text);
    final textParts = _splitTextByLanguage(text);
    for (final part in textParts) {
      final language = _detectLanguage(part);
      await _flutterTts.setLanguage(language == 'TH' ? 'th-TH' : 'en-US');
      await _flutterTts.setSpeechRate(1.2); // Adjust speech rate here
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(part);
      await _flutterTts.awaitSpeakCompletion(true);
    }
  }

  String _removeThaiSpaces(String text) {
    final thaiRegex = RegExp(r'[\u0E00-\u0E7F]');
    final buffer = StringBuffer();

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (thaiRegex.hasMatch(char) &&
          i > 0 &&
          thaiRegex.hasMatch(text[i - 1])) {
        buffer.write(char);
      } else {
        buffer.write(char == ' ' ? '' : char);
      }
    }

    return buffer.toString();
  }

  String _detectLanguage(String text) {
    final thaiRegex = RegExp(r'[\u0E00-\u0E7F]');
    final numberRegex = RegExp(r'[0-9]');

    if (thaiRegex.hasMatch(text)) {
      return 'TH';
    } else if (numberRegex.hasMatch(text)) {
      return _getCurrentLanguage();
    } else {
      return 'EN';
    }
  }

  List<String> _splitTextByLanguage(String text) {
    final parts = <String>[];
    final buffer = StringBuffer();
    String? currentLanguage;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final charLanguage = _detectLanguage(char);
      if (currentLanguage == null || charLanguage == currentLanguage) {
        buffer.write(char);
        currentLanguage = charLanguage;
      } else {
        parts.add(buffer.toString().replaceAll('', ''));
        buffer.clear();
        buffer.write(char);
        currentLanguage = charLanguage;
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString().replaceAll('', ''));
    }

    return parts;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            getText('รายการยาย้อนหลัง', 'Previous medicine list'),
            style: const TextStyle(
                fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.blue[900],
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () async {
                await _flutterTts.stop();
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              },
              icon: const Icon(Icons.logout),
              color: Colors.white,
            ),
          ],
        ),
        body: patientDetails != null && groupedMedications != null
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedMedications!.entries.map((entry) {
                    final visitId = entry.key;
                    final medications = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Visit ID: $visitId',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: medications.length,
                          itemBuilder: (context, index) {
                            final medication = medications[index];

                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildMedicationImage(
                                        medication['profileimage']),
                                    const SizedBox(height: 10),
                                    _buildMedicationDetails(medication),
                                    Center(
                                      child: IconButton(
                                        icon: const Icon(Icons.volume_up),
                                        onPressed: () async {
                                          String medicationText = """
                            ${medication['item_name']}
                            ${medication['th_name']}
                            ${getText('คำแนะนำ', 'Instructions')} : ${medication['instruction_text_line1']} ${medication['instruction_text_line2']} ${medication['instruction_text_line3']}
                          """;
                                          if (medication['item_deacription'] !=
                                                  null &&
                                              medication['item_deacription']
                                                  .isNotEmpty) {
                                            medicationText += """
                              ${getText('คำอธิบาย', 'Description')} : ${medication['item_deacription']}
                            """;
                                          }
                                          if (medication['item_caution'] !=
                                                  null &&
                                              medication['item_caution']
                                                  .isNotEmpty) {
                                            medicationText += """
                              ${getText('คำเตือน', 'Caution')} : ${medication['item_caution']}
                            """;
                                          }
                                          medicationText += """
                            ${getText('ชื่อแพทย์', 'Doctor Name')} : ${medication['opddoctorname']}
                          """;
                                          await _speak(medicationText);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }).toList(),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildMedicationImage(String? base64Image) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5.0),
        child: base64Image != null && base64Image.isNotEmpty
            ? Image.memory(
                base64Decode(base64Image),
                width: 150,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 150);
                },
              )
            : const Icon(Icons.image, size: 150),
      ),
    );
  }

  Widget _buildMedicationDetails(Map<String, dynamic> medication) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${medication['item_name']}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          '${medication['th_name']}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          '${getText('คำแนะนำ', 'Instructions')} : ${medication['instruction_text_line1']}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          '${medication['instruction_text_line2']}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          '${medication['instruction_text_line3']}',
          style: const TextStyle(fontSize: 16),
        ),
        if (medication['item_deacription'] != null &&
            medication['item_deacription'].isNotEmpty)
          Text(
            '${getText('คำอธิบาย', 'Description')} : ${medication['item_deacription']}',
            style: const TextStyle(fontSize: 16),
          ),
        if (medication['item_caution'] != null &&
            medication['item_caution'].isNotEmpty)
          Text(
            '${getText('คำเตือน', 'Caution')} : ${medication['item_caution']}',
            style: const TextStyle(fontSize: 16),
          ),
        Text(
          '${getText('ชื่อแพทย์', 'Doctor Name')} : ${medication['opddoctorname']}',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
