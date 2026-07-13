import 'dart:async';
import 'package:flutter/material.dart';
import '../models/ayah.dart';
import '../services/quran_api.dart';
import '../widgets/ayah_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final QuranApiService _api = QuranApiService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<Ayah> _results = [];
  bool _isLoading = false;
  bool _searched = false;
  String? _errorMessage;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _searched = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _searched = true;
    });

    try {
      final results = await _api.search(query);
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث في القرآن'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'اكتب كلمة أو جزء من آية...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (!_searched) {
      return const Center(
        child: Text('اكتب حرفين على الأقل لبدء البحث', style: TextStyle(color: Colors.grey)),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: Text('لا توجد نتائج مطابقة'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) =>
          AyahCard(ayah: _results[index], showSurahName: true),
    );
  }
}
