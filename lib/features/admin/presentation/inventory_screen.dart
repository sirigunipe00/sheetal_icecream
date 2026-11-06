import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/core/widgets/product_image.dart';
import 'package:sheetal_icecream/data/admin/admin_repository.dart';
import 'package:sheetal_icecream/data/models/product.dart';
import 'package:sheetal_icecream/features/admin/presentation/add_product_sheet.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_cubit.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, this.embedded = false});

  /// When true (admin bottom nav), hide the back button.
  final bool embedded;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _repo = AdminRepository();
  final _searchCtrl = TextEditingController();

  List<InventoryProduct> _items = const [];
  List<String> _categories = const [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _repo.fetchInventory(query: _query),
        _repo.fetchCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = results[0] as List<InventoryProduct>;
        _categories = results[1] as List<String>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openAdd() async {
    final created = await AddProductSheet.show(
      context,
      repository: _repo,
      categories: _categories,
    );
    if (created == true) {
      await _load();
      if (mounted) {
        context.read<CatalogCubit>().loadFromSupabase();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _edit(InventoryProduct item) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditInventorySheet(
        item: item,
        repository: _repo,
      ),
    );

    if (saved == true && mounted) {
      await _load();
      if (!mounted) return;
      context.read<CatalogCubit>().loadFromSupabase();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inventory updated'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.pageGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: !widget.embedded,
          iconTheme: const IconThemeData(color: AppColors.royalPurple),
          title: const Text(
            'Inventory',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.royalPurple,
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Add product',
              onPressed: _openAdd,
              icon: const Icon(Icons.add_box_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAdd,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add product'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  _query = v;
                  _load();
                },
                decoration: InputDecoration(
                  hintText: 'Search products',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderPink),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderPink),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFE53935)),
                            ),
                          ),
                        )
                      : _items.isEmpty
                          ? const Center(child: Text('No products found'))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  4,
                                  16,
                                  100,
                                ),
                                itemCount: _items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final item = _items[index];
                                  return _InventoryTile(
                                    item: item,
                                    onTap: () => _edit(item),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditInventorySheet extends StatefulWidget {
  const _EditInventorySheet({
    required this.item,
    required this.repository,
  });

  final InventoryProduct item;
  final AdminRepository repository;

  @override
  State<_EditInventorySheet> createState() => _EditInventorySheetState();
}

class _EditInventorySheetState extends State<_EditInventorySheet> {
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: '${widget.item.price}');
    _qtyCtrl = TextEditingController(text: '${widget.item.stockQty}');
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = int.tryParse(_priceCtrl.text.trim());
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (price == null || price < 0 || qty == null || qty < 0) {
      setState(() => _error = 'Enter valid price and stock qty.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.repository.updateInventory(
        productId: widget.item.id,
        price: price,
        stockQty: qty,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final item = widget.item;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.royalPurple,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.category} · ${item.unit}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.softMuted,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inventory edit: price and stock qty only',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.softMuted,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Price (₹)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Stock qty',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFE53935),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item, required this.onTap});

  final InventoryProduct item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = Product(
      id: item.id,
      name: item.name,
      unit: item.unit,
      price: item.price,
      category: item.category,
      image: item.imageUrl,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderPink),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: ProductImage(product: product, showProgress: false),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.deepInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.category} · ${item.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.softMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.price}  ·  Stock ${item.stockQty}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.royalPurple,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: AppColors.softMuted),
            ],
          ),
        ),
      ),
    );
  }
}
