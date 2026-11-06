import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/data/admin/admin_repository.dart';

class AddProductSheet extends StatefulWidget {
  const AddProductSheet({
    super.key,
    required this.repository,
    required this.categories,
  });

  final AdminRepository repository;
  final List<String> categories;

  static Future<bool?> show(
    BuildContext context, {
    required AdminRepository repository,
    required List<String> categories,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddProductSheet(
        repository: repository,
        categories: categories,
      ),
    );
  }

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController(text: 'Regular pack');
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();

  String? _category;
  bool _saving = false;
  String? _error;

  Uint8List? _imageBytes;
  String _imageExtension = 'jpg';
  String _imageContentType = 'image/jpeg';

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _category = widget.categories.first;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      final name = file.name.toLowerCase();
      var extension = 'jpg';
      var contentType = 'image/jpeg';
      if (name.endsWith('.png')) {
        extension = 'png';
        contentType = 'image/png';
      } else if (name.endsWith('.webp')) {
        extension = 'webp';
        contentType = 'image/webp';
      }

      setState(() {
        _imageBytes = bytes;
        _imageExtension = extension;
        _imageContentType = contentType;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Could not open gallery: $e');
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final category = (_category ?? '').trim();
    final unit = _unitCtrl.text.trim();
    final price = int.tryParse(_priceCtrl.text.trim());
    final qty = int.tryParse(_qtyCtrl.text.trim());

    if (name.isEmpty || category.isEmpty) {
      setState(() => _error = 'Name and category are required.');
      return;
    }
    if (_imageBytes == null) {
      setState(() => _error = 'Product image is required. Pick from gallery.');
      return;
    }
    if (price == null || price < 0 || qty == null || qty < 0) {
      setState(() => _error = 'Enter a valid price and stock qty.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final imageUrl = await widget.repository.uploadProductImage(
        productName: name,
        bytes: _imageBytes!,
        contentType: _imageContentType,
        extension: _imageExtension,
      );

      await widget.repository.addProduct(
        name: name,
        category: category,
        unit: unit.isEmpty ? 'Regular pack' : unit,
        price: price,
        stockQty: qty,
        imageUrl: imageUrl,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add product',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.royalPurple,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  _field('Name *', _nameCtrl),
                  const SizedBox(height: 12),
                  Text(
                    'Category *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    items: [
                      for (final c in widget.categories)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) => setState(() => _category = v),
                    decoration: _decoration(),
                  ),
                  if (widget.categories.isEmpty) ...[
                    const SizedBox(height: 8),
                    TextField(
                      decoration: _decoration(hint: 'Type a category'),
                      onChanged: (v) => _category = v,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _field('Unit / pack size', _unitCtrl, hint: 'e.g. 200 g'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'Price (₹) *',
                          _priceCtrl,
                          keyboard: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          'Stock qty *',
                          _qtyCtrl,
                          keyboard: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Product image *',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _saving ? null : _pickFromGallery,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8FC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderPink),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _imageBytes == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 36,
                                  color: AppColors.primary,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Choose from gallery',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepInk,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Required · JPG / PNG',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.softMuted,
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(_imageBytes!, fit: BoxFit.cover),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: FilledButton.tonalIcon(
                                    onPressed:
                                        _saving ? null : _pickFromGallery,
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Change'),
                                    style: FilledButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field('Description (optional)', _descCtrl, maxLines: 3),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save product',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          decoration: _decoration(hint: hint),
        ),
      ],
    );
  }

  InputDecoration _decoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFFFF8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderPink),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderPink),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}
