import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/user.dart';
import '../services/supabase_auth_service.dart';
import '../utils/vietnam_addresses.dart';
import '../providers/app_state.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtTextController = TextEditingController();
  final _wardTextController = TextEditingController();
  final SupabaseAuthService _authService = SupabaseAuthService();
  final ImagePicker _imagePicker = ImagePicker();
  File? _avatarFile;
  bool _isLoading = false;

  // Address selection
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;

  @override
  void initState() {
    super.initState();
    _nicknameController.text = widget.user.nickname;
    _nameController.text = widget.user.name ?? '';
    _emailController.text = widget.user.email ?? '';
    _addressController.text = widget.user.address ?? '';
    _selectedProvince = widget.user.province;
    _selectedDistrict = widget.user.district;
    _selectedWard = widget.user.ward;
    
    // If district/ward not in dropdown, use text controllers
    if (_selectedDistrict != null && _selectedProvince != null && !VietnamAddresses.getDistrictsByProvince(_selectedProvince!).contains(_selectedDistrict)) {
      _districtTextController.text = _selectedDistrict!;
    }
    if (_selectedWard != null && _selectedDistrict != null && !VietnamAddresses.getWardsByDistrict(_selectedDistrict!).contains(_selectedWard)) {
      _wardTextController.text = _selectedWard!;
    }
    
    if (widget.user.avatar != null && widget.user.avatar!.isNotEmpty) {
      _avatarFile = File(widget.user.avatar!);
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null) {
        // Copy image to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final avatarDir = Directory(path.join(appDir.path, 'avatars'));
        if (!await avatarDir.exists()) {
          await avatarDir.create(recursive: true);
        }
        final fileName = '${widget.user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(image.path).copy(
          path.join(avatarDir.path, fileName),
        );
        
        setState(() {
          _avatarFile = savedImage;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeAvatar() {
    setState(() {
      _avatarFile = null;
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _districtTextController.dispose();
    _wardTextController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Determine final district and ward values
    final finalDistrict = _selectedDistrict ?? _districtTextController.text.trim();
    final finalWard = _selectedWard ?? _wardTextController.text.trim();

    // Don't update nickname and phone - they are used for login
    final updatedUser = widget.user.copyWith(
      name: _nameController.text.trim().isEmpty
          ? null
          : _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      province: _selectedProvince,
      district: finalDistrict.isEmpty ? null : finalDistrict,
      ward: finalWard.isEmpty ? null : finalWard,
      avatar: _avatarFile?.path,
    );

    final success = await _authService.updateUser(updatedUser);
    setState(() => _isLoading = false);

    if (success && mounted) {
      // Refresh user in AppState
      final appState = context.read<AppState>();
      await appState.refreshUser();
      
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật hồ sơ')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.orange[100],
                      backgroundImage: _avatarFile != null
                          ? FileImage(_avatarFile!)
                          : (widget.user.avatar != null && widget.user.avatar!.isNotEmpty
                              ? FileImage(File(widget.user.avatar!))
                              : null),
                      child: _avatarFile == null &&
                              (widget.user.avatar == null || widget.user.avatar!.isEmpty)
                          ? Text(
                              widget.user.nickname[0].toUpperCase(),
                              style: const TextStyle(fontSize: 48, color: Colors.orange),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.orange,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: _pickAvatar,
                        ),
                      ),
                    ),
                    if (_avatarFile != null || (widget.user.avatar != null && widget.user.avatar!.isNotEmpty))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.red,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 16),
                            onPressed: _removeAvatar,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhấn vào icon camera để chọn avatar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              // Nickname - Read only
              TextFormField(
                controller: _nicknameController,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.alternate_email),
                ),
              ),
              const SizedBox(height: 16),
              // Phone - Read only (if available)
              if (widget.user.phone != null)
                TextFormField(
                  controller: TextEditingController(text: widget.user.phone),
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
              if (widget.user.phone != null) const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 16),
              // Province dropdown
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedProvince,
                decoration: const InputDecoration(
                  labelText: 'Tỉnh/Thành phố',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.map),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Chọn Tỉnh/Thành phố'),
                  ),
                  ...VietnamAddresses.provinces.toSet().toList().map((province) {
                    return DropdownMenuItem<String>(
                      value: province,
                      child: Text(province),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedProvince = value;
                    _selectedDistrict = null;
                    _selectedWard = null;
                    _districtTextController.clear();
                    _wardTextController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              // District dropdown or text field
              _selectedProvince != null && VietnamAddresses.getDistrictsByProvince(_selectedProvince!).isNotEmpty
                  ? DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _selectedDistrict,
                      decoration: const InputDecoration(
                        labelText: 'Quận/Huyện',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Chọn Quận/Huyện'),
                        ),
                        ...VietnamAddresses.getDistrictsByProvince(_selectedProvince!).toSet().toList().map((district) {
                          return DropdownMenuItem<String>(
                            value: district,
                            child: Text(district),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDistrict = value;
                          _selectedWard = null;
                          _wardTextController.clear();
                        });
                      },
                    )
                  : TextFormField(
                      controller: _districtTextController,
                      decoration: const InputDecoration(
                        labelText: 'Quận/Huyện',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
              const SizedBox(height: 16),
              // Ward dropdown or text field
              _selectedDistrict != null && VietnamAddresses.getWardsByDistrict(_selectedDistrict!).isNotEmpty
                  ? DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _selectedWard,
                      decoration: const InputDecoration(
                        labelText: 'Phường/Xã',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Chọn Phường/Xã'),
                        ),
                        ...VietnamAddresses.getWardsByDistrict(_selectedDistrict!).toSet().toList().map((ward) {
                          return DropdownMenuItem<String>(
                            value: ward,
                            child: Text(ward),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedWard = value;
                        });
                      },
                    )
                  : TextFormField(
                      controller: _wardTextController,
                      decoration: const InputDecoration(
                        labelText: 'Phường/Xã',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Lưu',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
