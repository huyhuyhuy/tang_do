import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user.dart';
import '../services/supabase_auth_service.dart';
import '../services/supabase_storage_service.dart';
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
  final SupabaseStorageService _storageService = SupabaseStorageService();
  final ImagePicker _imagePicker = ImagePicker();
  File? _avatarFile;
  bool _avatarRemoved = false; // Track if avatar was removed
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
    
    // Avatar is stored as URL in Supabase, not local file path
    // We'll display it directly from URL in the UI
  }

  Future<void> _pickAvatar() async {
    try {
      // Show dialog to choose camera or gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Chọn ảnh'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      
      if (source == null) return;
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );
      
      if (image != null && mounted) {
        // Wait a bit for UI to stabilize after camera closes
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          // Save as File for preview and later upload
          setState(() {
            _avatarFile = File(image.path);
            _avatarRemoved = false; // Reset removed flag when new image is selected
          });
        }
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
      _avatarRemoved = true;
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

    // Handle avatar: upload new one or delete old one
    String? avatarUrl;
    
    if (_avatarFile != null) {
      // New avatar selected - delete old one if exists, then upload new
      if (widget.user.avatar != null && widget.user.avatar!.isNotEmpty && widget.user.avatar!.startsWith('http')) {
        await _storageService.deleteAvatarImage(widget.user.avatar!);
      }
      avatarUrl = await _storageService.uploadAvatarImage(_avatarFile!);
      if (avatarUrl == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi upload avatar'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    } else if (_avatarRemoved) {
      // Avatar was removed - delete old one if exists
      if (widget.user.avatar != null && widget.user.avatar!.isNotEmpty && widget.user.avatar!.startsWith('http')) {
        await _storageService.deleteAvatarImage(widget.user.avatar!);
      }
      avatarUrl = null;
    } else {
      // Keep existing avatar
      avatarUrl = widget.user.avatar;
    }

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
      avatar: avatarUrl,
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
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
                              ? (widget.user.avatar!.startsWith('http')
                                  ? CachedNetworkImageProvider(widget.user.avatar!)
                                  : FileImage(File(widget.user.avatar!)) as ImageProvider)
                              : null),
                      child: _avatarFile == null &&
                              (widget.user.avatar == null || widget.user.avatar!.isEmpty || _avatarRemoved)
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
                    if (_avatarFile != null || (widget.user.avatar != null && widget.user.avatar!.isNotEmpty && !_avatarRemoved))
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
      ),
    );
  }
}
