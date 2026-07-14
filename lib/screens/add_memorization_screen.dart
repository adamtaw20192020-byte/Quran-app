import 'package:flutter/material.dart';
import '../models/memorization_entry.dart';
import '../services/memorization_service.dart';
import '../widgets/surah_picker_dialog.dart';

class AddMemorizationScreen extends StatefulWidget {
  const AddMemorizationScreen({super.key});

  @override
  State<AddMemorizationScreen> createState() => _AddMemorizationScreenState();
}

class _AddMemorizationScreenState extends State<AddMemorizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final MemorizationService _service = MemorizationService();

  final _nameController = TextEditingController();
  final _newMemController = TextEditingController();
  final _reviewController = TextEditingController();
  final _notesController = TextEditingController();

  String _rating = MemorizationEntry.ratingLevels[0];
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _newMemController.dispose();
    _reviewController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickSurah(TextEditingController controller) async {
    final result = await showSurahPickerDialog(context);
    if (result == null) return;

    setState(() {
      if (controller.text.trim().isEmpty) {
        controller.text = result;
      } else {
        controller.text = '${controller.text.trim()}، $result';
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final entry = MemorizationEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      studentName: _nameController.text.trim(),
      date: _selectedDate,
      newMemorization: _newMemController.text.trim(),
      review: _reviewController.text.trim(),
      rating: _rating,
      notes: _notesController.text.trim(),
    );

    await _service.addEntry(entry);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _formatDate(DateTime d) {
    return '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل متابعة جديد')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الطالب',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال اسم الطالب';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(_formatDate(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _newMemController,
              decoration: InputDecoration(
                labelText: 'الحفظ الجديد',
                hintText: 'مثال: سورة البقرة من آية 1 إلى 10',
                prefixIcon: const Icon(Icons.menu_book_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'اختيار سريع من قائمة السور',
                  onPressed: () => _pickSurah(_newMemController),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال الحفظ الجديد';
                }
                return null;
              },
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _reviewController,
              decoration: InputDecoration(
                labelText: 'المراجعة',
                hintText: 'مثال: سورة الفاتحة كاملة',
                prefixIcon: const Icon(Icons.refresh),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'اختيار سريع من قائمة السور',
                  onPressed: () => _pickSurah(_reviewController),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            const Text(
              'التقييم',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            _buildRatingSelector(),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                prefixIcon: Icon(Icons.notes_outlined),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ السجل'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: MemorizationEntry.ratingLevels.map((level) {
        final isSelected = level == _rating;
        return ChoiceChip(
          label: Text(level),
          selected: isSelected,
          onSelected: (_) => setState(() => _rating = level),
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}
