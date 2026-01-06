import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/child_provider.dart';
import '../services/api_service.dart';

class ChildManagementScreen extends StatefulWidget {
  const ChildManagementScreen({super.key});

  @override
  State<ChildManagementScreen> createState() => _ChildManagementScreenState();
}

class _ChildManagementScreenState extends State<ChildManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController(); // Or DatePicker
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception("Not authenticated");

      // Call API to add child
      await ApiService.createChild(
        token,
        _nameController.text.trim(),
        int.parse(_ageController.text.trim()),
      );

      if (!mounted) return;
      
      // Refresh provider
      context.read<ChildProvider>().refreshChildren(token);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Child added successfully!")));
      Navigator.pop(context); // Return to previous screen

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Child")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nickname", border: OutlineInputBorder()),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: "Age (in months)", border: OutlineInputBorder(), hintText: "e.g. 72"),
                keyboardType: TextInputType.number,
                 validator: (val) {
                  if (val == null || val.isEmpty) return "Required";
                  if (int.tryParse(val) == null) return "Must be a number";
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading ? const CircularProgressIndicator() : const Text("Save Child"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
