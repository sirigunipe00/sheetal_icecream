import 'package:flutter/material.dart';
import 'package:sheetal_icecream/core/theme/app_colors.dart';
import 'package:sheetal_icecream/data/models/user_address.dart';
import 'package:sheetal_icecream/services/device_location.dart';
import 'package:sheetal_icecream/services/supabase_service.dart';

class AddressFormSheet extends StatefulWidget {
  const AddressFormSheet({
    super.key,
    this.existingAddress,
    this.forceDefault = false,
  });

  final UserAddress? existingAddress;
  final bool forceDefault;

  static Future<UserAddress?> show(
    BuildContext context, {
    UserAddress? existingAddress,
    bool forceDefault = false,
  }) {
    return showModalBottomSheet<UserAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressFormSheet(
        existingAddress: existingAddress,
        forceDefault: forceDefault,
      ),
    );
  }

  @override
  State<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _label = widget.existingAddress?.label ?? 'Home';
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.existingAddress?.recipientName ?? '');
  late final TextEditingController _phoneCtrl =
      TextEditingController(text: widget.existingAddress?.phone ?? '');
  late final TextEditingController _houseCtrl =
      TextEditingController(text: widget.existingAddress?.house ?? '');
  late final TextEditingController _streetCtrl =
      TextEditingController(text: widget.existingAddress?.street ?? '');
  late final TextEditingController _localityCtrl =
      TextEditingController(text: widget.existingAddress?.locality ?? '');
  late final TextEditingController _landmarkCtrl =
      TextEditingController(text: widget.existingAddress?.landmark ?? '');
  late final TextEditingController _cityCtrl =
      TextEditingController(text: widget.existingAddress?.city ?? '');
  late final TextEditingController _pincodeCtrl =
      TextEditingController(text: widget.existingAddress?.postalCode ?? '');
  late bool _isDefault =
      widget.forceDefault || (widget.existingAddress?.isDefault ?? false);

  bool _loading = false;
  bool _detectingLocation = false;
  String? _errorMessage;
  String? _locationPreview;
  String? _locationError;

  bool get _isEdit => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    // Blinkit-style: autofill from GPS when adding a new address.
    if (!_isEdit) {
      _useCurrentLocation();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _houseCtrl.dispose();
    _streetCtrl.dispose();
    _localityCtrl.dispose();
    _landmarkCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _detectingLocation = true;
      _locationError = null;
    });

    try {
      final details = await DeviceLocation.currentDetails();
      if (!mounted) return;

      // Autofill location fields (Blinkit-style). House / name / phone stay manual.
      if (details.street != null && details.street!.trim().isNotEmpty) {
        _streetCtrl.text = details.street!.trim();
      }
      final locality = details.locality ?? details.subLocality;
      if (locality != null && locality.trim().isNotEmpty) {
        _localityCtrl.text = locality.trim();
      }
      if (details.city != null && details.city!.trim().isNotEmpty) {
        _cityCtrl.text = details.city!.trim();
      }
      if (details.postalCode != null && details.postalCode!.trim().isNotEmpty) {
        _pincodeCtrl.text = details.postalCode!.trim();
      }
      if (_landmarkCtrl.text.trim().isEmpty &&
          details.landmark != null &&
          details.landmark!.trim().isNotEmpty) {
        _landmarkCtrl.text = details.landmark!.trim();
      }

      setState(() {
        _locationPreview = details.preview;
        _detectingLocation = false;
      });
    } on DeviceLocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _detectingLocation = false;
        _locationError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detectingLocation = false;
        _locationError = 'Could not detect location. Fill address manually.';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final address = UserAddress(
        id: widget.existingAddress?.id ?? '',
        userId: SupabaseService.instance.currentUserId,
        label: _label,
        recipientName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        house: _houseCtrl.text.trim(),
        street:
            _streetCtrl.text.trim().isNotEmpty ? _streetCtrl.text.trim() : null,
        locality: _localityCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim().isNotEmpty
            ? _landmarkCtrl.text.trim()
            : null,
        city: _cityCtrl.text.trim().isNotEmpty
            ? _cityCtrl.text.trim()
            : 'Bengaluru',
        state: widget.existingAddress?.state ?? 'Karnataka',
        postalCode: _pincodeCtrl.text.trim(),
        isDefault: _isDefault,
      );

      final saved = await SupabaseService.instance.saveAddress(address);
      if (mounted) {
        Navigator.of(context).pop(saved ?? address);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not save address. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                    _isEdit ? 'Edit Address' : 'Add Delivery Address',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.royalPurple,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.softMuted,
                    ),
                  ),
                ],
              ),

              // Blinkit-style current location card
              _LocationDetectCard(
                detecting: _detectingLocation,
                preview: _locationPreview,
                error: _locationError,
                onUseCurrent: _useCurrentLocation,
              ),
              const SizedBox(height: 14),

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFD32F2F),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Text(
                'Address Label',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Home', 'Work', 'Other'].map((l) {
                  final selected = _label == l;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(l),
                      selected: selected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color:
                            selected ? AppColors.primary : AppColors.softMuted,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      onSelected: (_) => setState(() => _label = l),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              _field(
                controller: _nameCtrl,
                label: 'Recipient Name',
                icon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter name' : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _phoneCtrl,
                label: '10-Digit Mobile Number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim())) {
                    return 'Enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _field(
                controller: _houseCtrl,
                label: 'Flat / House / Floor / Building *',
                icon: Icons.home_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter flat/house no.'
                    : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _streetCtrl,
                label: 'Street / Road',
                icon: Icons.signpost_outlined,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _localityCtrl,
                label: 'Area / Locality / Sector',
                icon: Icons.location_city_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter locality/area'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _cityCtrl,
                      label: 'City',
                      icon: Icons.location_on_outlined,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter city'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _field(
                      controller: _pincodeCtrl,
                      label: 'Pincode',
                      icon: Icons.pin_drop_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter pincode';
                        }
                        if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(v.trim())) {
                          return 'Valid 6-digit PIN';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(
                controller: _landmarkCtrl,
                label: 'Landmark (Optional)',
                icon: Icons.near_me_outlined,
              ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                activeTrackColor: AppColors.primary,
                title: const Text(
                  'Set as default delivery address',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onChanged: widget.forceDefault
                    ? null
                    : (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Update Address' : 'Save Address',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.softMuted),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        filled: true,
        fillColor: const Color(0xFFFFF8FC),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _LocationDetectCard extends StatelessWidget {
  const _LocationDetectCard({
    required this.detecting,
    required this.preview,
    required this.error,
    required this.onUseCurrent,
  });

  final bool detecting;
  final String? preview;
  final String? error;
  final VoidCallback onUseCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: detecting
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detecting
                          ? 'Detecting your location…'
                          : (preview != null
                              ? 'Delivering to'
                              : 'Use current location'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.softMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detecting
                          ? 'Please wait'
                          : (preview ??
                              error ??
                              'Autofill street, area, city & pincode'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: error != null && preview == null
                            ? const Color(0xFFD32F2F)
                            : AppColors.deepInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: OutlinedButton.icon(
              onPressed: detecting ? null : onUseCurrent,
              icon: const Icon(Icons.gps_fixed_rounded, size: 16),
              label: Text(
                preview == null ? 'Use current location' : 'Refresh location',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
