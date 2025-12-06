import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../providers/app_state.dart';
import '../services/supabase_product_service.dart';
import '../services/supabase_storage_service.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../utils/vietnam_addresses.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/searchable_address_dropdown.dart';
import 'profile_screen.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onProductAdded;
  final bool showBannerAd;
  
  const AddProductScreen({super.key, this.onProductAdded, this.showBannerAd = true});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false; // Don't keep alive, reset form when switching tabs
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _districtTextController = TextEditingController();
  final _wardTextController = TextEditingController();
  final SupabaseProductService _productService = SupabaseProductService();
  final SupabaseStorageService _storageService = SupabaseStorageService();

  String? _selectedCategory;
  String _selectedCondition = AppConstants.conditionUsed;
  int _expiryDays = AppConstants.defaultExpiryDays;
  bool _useDefaultAddress = true;
  bool _useDefaultPhone = true;
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  List<File?> _selectedImages = [null, null, null];
  
  // Address selection
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _contactPhoneController.dispose();
    _districtTextController.dispose();
    _wardTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(int index) async {
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
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null && mounted) {
        // Copy image to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final imageDir = Directory(path.join(appDir.path, 'product_images'));
        if (!await imageDir.exists()) {
          await imageDir.create(recursive: true);
        }
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
        final savedImage = await File(image.path).copy(
          path.join(imageDir.path, fileName),
        );
        
        // Wait a bit for UI to stabilize after camera closes
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          setState(() {
            _selectedImages[index] = savedImage;
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages[index] = null;
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn danh mục'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate: Bắt buộc có ít nhất 1 ảnh
    if (_selectedImages[0] == null && _selectedImages[1] == null && _selectedImages[2] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 ảnh sản phẩm'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final appState = context.read<AppState>();
    if (appState.currentUser == null) return;

    final user = appState.currentUser!;
    
    // Check if user has address information
    final hasAddress = (user.province != null && user.province!.isNotEmpty) ||
        (_selectedProvince != null && _selectedProvince!.isNotEmpty);
    
    if (!hasAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng cập nhật địa chỉ trong hồ sơ trước khi đăng tin'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      // Navigate to profile screen to update address
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            userId: user.id!,
            isOwnProfile: true,
            showBottomNavBar: false,
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final now = DateTime.now();

    // Upload images to Supabase Storage
    String? image1Url;
    String? image2Url;
    String? image3Url;

    if (_selectedImages[0] != null) {
      image1Url = await _storageService.uploadProductImage(_selectedImages[0]!);
      if (image1Url == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi upload ảnh 1'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (_selectedImages[1] != null) {
      image2Url = await _storageService.uploadProductImage(_selectedImages[1]!);
      if (image2Url == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi upload ảnh 2'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    if (_selectedImages[2] != null) {
      image3Url = await _storageService.uploadProductImage(_selectedImages[2]!);
      if (image3Url == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lỗi khi upload ảnh 3'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final product = Product(
      userId: user.id!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _selectedCategory!,
      condition: _selectedCondition,
      address: _useDefaultAddress ? user.address : _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      province: _useDefaultAddress ? user.province : _selectedProvince,
      district: _useDefaultAddress ? user.district : _selectedDistrict,
      ward: _useDefaultAddress ? user.ward : _selectedWard,
      contactPhone: _useDefaultPhone ? user.phone : _contactPhoneController.text.trim().isEmpty
          ? null
          : _contactPhoneController.text.trim(),
      image1: image1Url,
      image2: image2Url,
      image3: image3Url,
      expiryDays: _expiryDays,
      createdAt: now,
      expiresAt: now.add(Duration(days: _expiryDays)),
    );

    final id = await _productService.createProduct(product);
    setState(() => _isLoading = false);

    if (id != null && mounted) {
      // Clear form after successful save
      _nameController.clear();
      _descriptionController.clear();
      _addressController.clear();
      _contactPhoneController.clear();
      _districtTextController.clear();
      _wardTextController.clear();
      setState(() {
        _selectedCategory = null;
        _selectedCondition = AppConstants.conditionUsed;
        _expiryDays = AppConstants.defaultExpiryDays;
        _useDefaultAddress = true;
        _useDefaultPhone = true;
        _selectedImages = [null, null, null];
        _selectedProvince = null;
        _selectedDistrict = null;
        _selectedWard = null;
      });
      
      // Call callback to notify parent (MainScreen) to reload
      if (widget.onProductAdded != null) {
        widget.onProductAdded!();
      } else {
        Navigator.of(context).pop(true);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm sản phẩm')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm sản phẩm thất bại'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final appState = context.watch<AppState>();
    final user = appState.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm sản phẩm'),
      ),
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: widget.showBannerAd ? BannerAdWidget() : null,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên sản phẩm *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên sản phẩm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Danh mục *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Vui lòng chọn danh mục';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Trạng thái *'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCondition = AppConstants.conditionNew);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedCondition == AppConstants.conditionNew
                              ? Colors.orange
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedCondition == AppConstants.conditionNew
                                ? Colors.orange
                                : Colors.grey,
                          ),
                        ),
                        child: Text(
                          'Chưa sử dụng',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedCondition == AppConstants.conditionNew
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCondition = AppConstants.conditionUsed);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedCondition == AppConstants.conditionUsed
                              ? Colors.orange
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _selectedCondition == AppConstants.conditionUsed
                                ? Colors.orange
                                : Colors.grey,
                          ),
                        ),
                        child: Text(
                          'Đã qua sử dụng',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _selectedCondition == AppConstants.conditionUsed
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              const Text(
                'Ảnh sản phẩm (tối đa 3 ảnh)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey[100],
                            ),
                            child: _selectedImages[index] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImages[index]!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : InkWell(
                                    onTap: () => _pickImage(index),
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 32),
                                        SizedBox(height: 4),
                                        Text(
                                          'Thêm ảnh',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                          if (_selectedImages[index] != null)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('Thời gian hết hạn (ngày) *'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _expiryDays.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$_expiryDays ngày',
                      onChanged: (value) {
                        setState(() => _expiryDays = value.toInt());
                      },
                    ),
                  ),
                  Text('$_expiryDays'),
                ],
              ),
              const SizedBox(height: 16),
              // Contact Phone Section
              CheckboxListTile(
                title: const Text('Sử dụng số điện thoại mặc định'),
                value: _useDefaultPhone,
                onChanged: (value) {
                  setState(() => _useDefaultPhone = value ?? true);
                },
              ),
              if (!_useDefaultPhone) ...[
                TextFormField(
                  controller: _contactPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại liên hệ *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ] else if (user != null) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.phone, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'SĐT liên hệ: ${user.phone}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Address Section
              CheckboxListTile(
                title: const Text('Sử dụng địa chỉ mặc định'),
                value: _useDefaultAddress,
                onChanged: (value) {
                  setState(() => _useDefaultAddress = value ?? true);
                },
              ),
              if (!_useDefaultAddress) ...[
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Địa chỉ chi tiết *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.home),
                    hintText: 'Số nhà, tên đường...',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập địa chỉ chi tiết';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Text('Tỉnh/Thành phố *'),
                const SizedBox(height: 8),
                SearchableAddressDropdown(
                  type: AddressType.province,
                  value: _selectedProvince,
                  onChanged: (value) {
                    setState(() {
                      _selectedProvince = value;
                      _selectedDistrict = null; // Reset district when province changes
                      _selectedWard = null; // Reset ward when province changes
                      _districtTextController.clear();
                      _wardTextController.clear();
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Vui lòng chọn Tỉnh/Thành phố';
                    }
                    return null;
                  },
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                const Text('Quận/Huyện *'),
                const SizedBox(height: 8),
                _selectedProvince == null
                    ? SearchableAddressDropdown(
                        type: AddressType.district,
                        value: null,
                        province: null,
                        onChanged: null,
                        validator: (value) {
                          return 'Vui lòng chọn Tỉnh/Thành phố trước';
                        },
                        isRequired: true,
                      )
                    : VietnamAddresses.getDistrictsByProvince(_selectedProvince!).isEmpty
                        ? TextFormField(
                            controller: _districtTextController,
                            decoration: const InputDecoration(
                              labelText: 'Quận/Huyện *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                              hintText: 'Nhập tên Quận/Huyện',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedDistrict = value.isEmpty ? null : value;
                                _selectedWard = null; // Reset ward when district changes
                                _wardTextController.clear();
                              });
                            },
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui lòng nhập Quận/Huyện';
                              }
                              return null;
                            },
                          )
                        : SearchableAddressDropdown(
                            type: AddressType.district,
                            value: _selectedDistrict,
                            province: _selectedProvince,
                            onChanged: (value) {
                              setState(() {
                                _selectedDistrict = value;
                                _selectedWard = null; // Reset ward when district changes
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Vui lòng chọn Quận/Huyện';
                              }
                              return null;
                            },
                            isRequired: true,
                          ),
                const SizedBox(height: 16),
                const Text('Phường/Xã'),
                const SizedBox(height: 8),
                _selectedDistrict == null
                    ? SearchableAddressDropdown(
                        type: AddressType.ward,
                        value: null,
                        district: null,
                        onChanged: null,
                      )
                    : VietnamAddresses.getWardsByDistrict(_selectedDistrict!).isEmpty
                        ? TextFormField(
                            controller: _wardTextController,
                            decoration: const InputDecoration(
                              labelText: 'Phường/Xã (tùy chọn)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                              hintText: 'Nhập tên Phường/Xã',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedWard = value.isEmpty ? null : value;
                              });
                            },
                          )
                        : SearchableAddressDropdown(
                            type: AddressType.ward,
                            value: _selectedWard,
                            district: _selectedDistrict,
                            onChanged: (value) {
                              setState(() {
                                _selectedWard = value;
                              });
                            },
                          ),
              ] else if (user != null) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Địa chỉ mặc định:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${user.address ?? ''} ${user.district ?? ''} ${user.province ?? ''}'.trim(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProduct,
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
                        'Thêm sản phẩm',
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

