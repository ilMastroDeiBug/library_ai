import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:library_ai/domain/use_cases/import_letterboxd_use_case.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class ImportLetterboxdPage extends StatefulWidget {
  const ImportLetterboxdPage({super.key});

  @override
  State<ImportLetterboxdPage> createState() => _ImportLetterboxdPageState();
}

class _ImportLetterboxdPageState extends State<ImportLetterboxdPage> {
  bool _isImporting = false;
  int _totalRows = 0;
  int _processedRows = 0;

  Future<void> _importFromLetterboxd() async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.importLetterboxdLoginRequired)),
      );
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _isImporting = true;
          _processedRows = 0;
          _totalRows = 0;
        });

        File file = File(result.files.single.path!);
        final input = await file.readAsString();

        List<List<dynamic>> rowsAsListOfValues =
            const CsvToListConverter().convert(input);

        if (rowsAsListOfValues.isNotEmpty) {
          setState(() {
            _totalRows = rowsAsListOfValues.length - 1; // escludo header
          });

          await sl<ImportLetterboxdUseCase>().importData(
            rows: rowsAsListOfValues,
            userId: user.id,
            fileName: result.files.single.name,
            onProgress: (total, processed) {
              if (mounted) {
                setState(() {
                  _totalRows = total;
                  _processedRows = processed;
                });
              }
            },
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.importLetterboxdSuccess),
                backgroundColor: Colors.white,
              ),
            );
            Navigator.pop(context); // Torna indietro alla fine
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.importLetterboxdError(e.toString())),
            backgroundColor: Colors.white,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.importLetterboxdTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.importLetterboxdHeadline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.importLetterboxdSubtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              _buildStepRow('1', AppLocalizations.of(context)!.importLetterboxdStep1),
              _buildStepRow('2', AppLocalizations.of(context)!.importLetterboxdStep2),
              _buildStepRow('3', AppLocalizations.of(context)!.importLetterboxdStep3),
              const Spacer(),
              if (_isImporting)
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _totalRows > 0 ? _processedRows / _totalRows : null,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.importLetterboxdProgress(_processedRows, _totalRows),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _importFromLetterboxd,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: Text(
                      AppLocalizations.of(context)!.importLetterboxdButton,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String stepNumber, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Text(
                stepNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
