import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';

class NoteInputScreen extends StatefulWidget {
  final String initialNote;

  const NoteInputScreen({super.key, this.initialNote = ''});

  @override
  State<NoteInputScreen> createState() => _NoteInputScreenState();
}

class _NoteInputScreenState extends State<NoteInputScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveNote() {
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context, widget.initialNote),
        ),
        title: const Text(
          'Note',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _saveNote,
            child: const Text(
              'SAVE',
              style: TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: TextField(
          controller: _controller,
          autofocus: true,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontSize: 16, color: AppColors.textDark),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Write your note here...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
