import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SystemSettingsPage extends StatefulWidget {
  const SystemSettingsPage({super.key});

  static const routeName = '/admin/settings';

  @override
  State<SystemSettingsPage> createState() => _SystemSettingsPageState();
}

class _SystemSettingsPageState extends State<SystemSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController(
    text: '0.20',
  );
  String _currency = 'TRY';
  String _dateFormat = 'dd.MM.yyyy';
  String? _logoUrl;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await _firestore
        .collection('system_settings')
        .doc('general')
        .get();
    final data = doc.data();
    if (data != null) {
      _companyNameController.text = (data['company_name'] as String? ?? '')
          .trim();
      _taxRateController.text =
          ((data['default_tax_rate'] as num?)?.toDouble() ?? 0.20)
              .toStringAsFixed(2);
      _currency = (data['default_currency'] as String? ?? 'TRY').trim();
      _dateFormat = (data['date_format'] as String? ?? 'dd.MM.yyyy').trim();
      _logoUrl = data['logo_url'] as String?;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sistem Ayarları')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(labelText: 'Şirket Adı'),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Şirket adı zorunludur.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownMenu<String>(
                    initialSelection: _currency,
                    label: const Text('Varsayılan Para Birimi'),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'TRY', label: 'TRY'),
                      DropdownMenuEntry(value: 'USD', label: 'USD'),
                      DropdownMenuEntry(value: 'EUR', label: 'EUR'),
                    ],
                    onSelected: (value) {
                      if (value != null) {
                        setState(() => _currency = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taxRateController,
                    decoration: const InputDecoration(
                      labelText: 'Varsayılan KDV Oranı (örn. 0.20)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(
                        (value ?? '').replaceAll(',', '.'),
                      );
                      if (parsed == null || parsed < 0) {
                        return 'Geçerli bir oran giriniz.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownMenu<String>(
                    initialSelection: _dateFormat,
                    label: const Text('Tarih Formatı'),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(
                        value: 'dd.MM.yyyy',
                        label: 'dd.MM.yyyy',
                      ),
                      DropdownMenuEntry(
                        value: 'yyyy-MM-dd',
                        label: 'yyyy-MM-dd',
                      ),
                      DropdownMenuEntry(
                        value: 'MM/dd/yyyy',
                        label: 'MM/dd/yyyy',
                      ),
                    ],
                    onSelected: (value) {
                      if (value != null) {
                        setState(() => _dateFormat = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logo',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundImage: _logoUrl != null
                                    ? NetworkImage(_logoUrl!)
                                    : null,
                                child: _logoUrl == null
                                    ? const Icon(Icons.image_outlined)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              FilledButton.icon(
                                onPressed: _isSaving ? null : _pickLogo,
                                icon: const Icon(Icons.upload_outlined),
                                label: const Text('Logo Yükle'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) return;

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'system_settings/logo_${DateTime.now().millisecondsSinceEpoch}.${file.extension ?? 'png'}',
      );
      await storageRef.putData(bytes);
      final url = await storageRef.getDownloadURL();
      setState(() => _logoUrl = url);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logo yüklenemedi: $error')));
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _isSaving = true);

    final taxRate =
        double.tryParse(_taxRateController.text.replaceAll(',', '.')) ?? 0;

    try {
      await _firestore.collection('system_settings').doc('general').set({
        'company_name': _companyNameController.text.trim(),
        'default_currency': _currency,
        'default_tax_rate': taxRate,
        'date_format': _dateFormat,
        'logo_url': _logoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ayarlar kaydedildi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydetme başarısız: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
