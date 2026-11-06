import 'package:flutter/material.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/data/models/user_address.dart';
import 'package:sheetal_icecream/features/address/presentation/address_form_sheet.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

class SavedAddressesSheet extends StatefulWidget {
  const SavedAddressesSheet({
    super.key,
    this.selectedAddressId,
    this.isPicker = false,
  });

  final String? selectedAddressId;
  final bool isPicker;

  static Future<UserAddress?> show(
    BuildContext context, {
    String? selectedAddressId,
    bool isPicker = false,
  }) {
    return showModalBottomSheet<UserAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SavedAddressesSheet(
        selectedAddressId: selectedAddressId,
        isPicker: isPicker,
      ),
    );
  }

  @override
  State<SavedAddressesSheet> createState() => _SavedAddressesSheetState();
}

class _SavedAddressesSheetState extends State<SavedAddressesSheet> {
  List<UserAddress> _addresses = [];
  bool _loading = true;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedAddressId;
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);
    final list = await SupabaseService.instance.fetchAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        _loading = false;
        // If no selected address yet, default to the default address or first one
        if (_selectedId == null && list.isNotEmpty) {
          final def = list.firstWhere((a) => a.isDefault, orElse: () => list.first);
          _selectedId = def.id;
        }
      });
    }
  }

  Future<void> _setDefault(UserAddress address) async {
    try {
      await SupabaseService.instance.setDefaultAddress(address.id);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${address.label} set as default delivery address'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update default address'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _delete(UserAddress address) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address?'),
        content: Text('Are you sure you want to delete ${address.label} address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SupabaseService.instance.deleteAddress(address.id);
      await _loadAddresses();
    }
  }

  Future<void> _addNewAddress() async {
    final added = await AddressFormSheet.show(
      context,
      forceDefault: _addresses.isEmpty,
    );
    if (added != null) {
      await _loadAddresses();
      if (widget.isPicker && mounted) {
        Navigator.of(context).pop(added);
      }
    }
  }

  Future<void> _editAddress(UserAddress address) async {
    final updated = await AddressFormSheet.show(
      context,
      existingAddress: address,
    );
    if (updated != null) {
      await _loadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isPicker ? 'Select Delivery Address' : 'Saved Addresses',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.royalPurple,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: AppColors.softMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _addresses.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        itemCount: _addresses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final a = _addresses[i];
                          final isSelected = a.id == _selectedId;
                          return _addressCard(a, isSelected: isSelected);
                        },
                      ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _addNewAddress,
              icon: const Icon(Icons.add_rounded, color: AppColors.primary),
              label: const Text(
                'Add New Address',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 54, color: AppColors.softMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text(
            'No Saved Addresses',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.royalPurple),
          ),
          const SizedBox(height: 4),
          const Text(
            'Add your delivery address to place orders quickly',
            style: TextStyle(fontSize: 13, color: AppColors.softMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _addressCard(UserAddress a, {required bool isSelected}) {
    return InkWell(
      onTap: () {
        if (widget.isPicker) {
          setState(() => _selectedId = a.id);
          Navigator.of(context).pop(a);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFEEEEEE),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  a.label.toLowerCase() == 'work'
                      ? Icons.business_rounded
                      : a.label.toLowerCase() == 'home'
                          ? Icons.home_rounded
                          : Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  a.label,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(width: 8),
                if (a.isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                const Spacer(),
                if (widget.isPicker)
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: isSelected ? AppColors.primary : AppColors.softMuted,
                    size: 20,
                  )
                else
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      if (val == 'default') _setDefault(a);
                      if (val == 'edit') _editAddress(a);
                      if (val == 'delete') _delete(a);
                    },
                    itemBuilder: (_) => [
                      if (!a.isDefault)
                        const PopupMenuItem(
                          value: 'default',
                          child: Text('Set as Default'),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Color(0xFFD32F2F))),
                      ),
                    ],
                    child: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.softMuted),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${a.recipientName} • ${a.phone}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.deepInk),
            ),
            const SizedBox(height: 4),
            Text(
              a.formattedAddress,
              style: const TextStyle(fontSize: 12, color: AppColors.softMuted, height: 1.3),
            ),
            if (widget.isPicker && !a.isDefault) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _setDefault(a),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      'Make this Default',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
