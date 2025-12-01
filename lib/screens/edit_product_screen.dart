import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../services/supabase_product_service.dart';
import '../services/supabase_storage_service.dart';
import '../models/product.dart';
import '../utils/constants.dart';
import '../utils/vietnam_addresses.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _districtTextController = TextEditingController();
  final _wardTextController = TextEditingController();
  final SupabaseProductService _productService = SupabaseProductService();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedCategory;
  String _selectedCondition = AppConstants.conditionUsed;
  int _expiryDays = AppConstants.defaultExpiryDays;
  bool _useDefaultPhone = false;
  bool _useDefaultAddress = false;
  bool _isLoading = false;
  List<File?> _selectedImages = [null, null, null];
  List<bool> _imageRemoved = [false, false, false]; // Track if original images were removed
  
  // Address selection
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedWard;

  @override
  void initState() {
    super.initState();
    // Pre-fill form data
    _nameController.text = widget.product.name;
    _descriptionController.text = widget.product.description ?? '';
    _addressController.text = widget.product.address ?? '';
    _selectedCategory = widget.product.category;
    _selectedCondition = widget.product.condition;
    
    // Calculate remaining days
    final now = DateTime.now();
    final remainingDays = widget.product.expiresAt.difference(now).inDays;
    _expiryDays = remainingDays > 0 ? remainingDays : 1;
    
    // Pre-fill contact phone
    _contactPhoneController.text = widget.product.contactPhone ?? '';
    
    // Pre-fill address
    _selectedProvince = widget.product.province;
    _selectedDistrict = widget.product.district;
    
    // Set default phone checkbox if contact phone matches user's phone
    // This will be checked in build method
    
    // Try to parse ward from address (if ward info is stored in address)
    // For now, we'll leave it empty as ward is not stored in product model
    
    // Pre-fill images
    _loadImages();
  }

  Future<void> _loadImages() async {
    // Images are stored as URLs in Supabase Storage
    // We don't need to load them as local files
    // They will be displayed directly from URLs in the UI
  }
  
  String? _getImageUrl(int index) {
    if (_selectedImages[index] != null) {
      return null; // Using local file, not URL
    }
    if (_imageRemoved[index]) {
      return null; // Image was removed
    }
    final images = [
      widget.product.image1,
      widget.product.image2,
      widget.product.image3,
    ];
    if (index < images.length && images[index] != null && images[index]!.isNotEmpty) {
      return images[index];
    }
    return null;
  }

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
            _imageRemoved[index] = false; // Reset removed flag when new image is selected
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
      _imageRemoved[index] = true;
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

    setState(() => _isLoading = true);

    final appState = context.read<AppState>();
    if (appState.currentUser == null) return;

    final user = appState.currentUser!;
    final now = DateTime.now();

    // Handle images: delete old ones if replaced/removed, upload new ones
    String? image1Url;
    String? image2Url;
    String? image3Url;

    final originalImages = [
      widget.product.image1,
      widget.product.image2,
      widget.product.image3,
    ];

    // Process image1
    if (_selectedImages[0] != null) {
      // New image selected - delete old one if exists, then upload new
      if (originalImages[0] != null && originalImages[0]!.startsWith('http')) {
        await _storageService.deleteProductImage(originalImages[0]!);
      }
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
    } else if (_imageRemoved[0]) {
      // Image was removed - delete old one if exists
      if (originalImages[0] != null && originalImages[0]!.startsWith('http')) {
        await _storageService.deleteProductImage(originalImages[0]!);
      }
      image1Url = null;
    } else {
      // Keep existing image
      image1Url = originalImages[0];
    }

    // Process image2
    if (_selectedImages[1] != null) {
      if (originalImages[1] != null && originalImages[1]!.startsWith('http')) {
        await _storageService.deleteProductImage(originalImages[1]!);
      }
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
    } else if (_imageRemoved[1]) {
      if (originalImages[1] != null && originalImages[1]!.startsWith('http')) {
        await _storageService.deleteProductImage(originalImages[1]!);
      }
      image2Url = null;
    } else {
      image2Url = originalImages[1];
    }

    // Process image3
    if (_selectedImages[2] != null) {
      if (originalImages[2] != null && originalImages[2]!.startsWith('http')) {
        await _storageService.deleteProductImage(originalImages[2]!);
      }
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
    } else if (_imageRemoved[2]) {
      if (originalImages[2] != null && originalImages[2]!.startsWith('http')) {
        await _storageService.deleteProductImage(originalImages[2]!);
      }
      image3Url = null;
    } else {
      image3Url = originalImages[2];
    }

    final updatedProduct = widget.product.copyWith(
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
      expiresAt: now.add(Duration(days: _expiryDays)),
    );

    final success = await _productService.updateProduct(updatedProduct);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật sản phẩm')),
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
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    
    // Check if contact phone matches user's phone (only once)
    if (user != null && !_useDefaultPhone && widget.product.contactPhone == user.phone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _useDefaultPhone = true;
            _contactPhoneController.clear();
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa sản phẩm'),
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
                                : _getImageUrl(index) != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: _getImageUrl(index)!,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => InkWell(
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
                          if (_selectedImages[index] != null || _getImageUrl(index) != null)
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
              const Text('Thời gian hết hạn (ngày còn lại) *'),
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
                  setState(() => _useDefaultPhone = value ?? false);
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
                  setState(() => _useDefaultAddress = value ?? false);
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
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.map),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Chọn Tỉnh/Thành phố'),
                    ),
                    ...VietnamAddresses.provinces.toSet().map((province) {
                      return DropdownMenuItem<String>(
                        value: province,
                        child: Text(province),
                      );
                    }),
                  ],
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
                ),
                const SizedBox(height: 16),
                const Text('Quận/Huyện *'),
                const SizedBox(height: 8),
                _selectedProvince == null
                    ? DropdownButtonFormField<String>(
                        value: null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_city),
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Chọn Tỉnh/Thành phố trước'),
                          ),
                        ],
                        onChanged: null,
                        validator: (value) {
                          return 'Vui lòng chọn Tỉnh/Thành phố trước';
                        },
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
                        : DropdownButtonFormField<String>(
                            value: _selectedDistrict,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_city),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Chọn Quận/Huyện'),
                              ),
                              ...VietnamAddresses.getDistrictsByProvince(_selectedProvince!).map((district) {
                                return DropdownMenuItem<String>(
                                  value: district,
                                  child: Text(district),
                                );
                              }),
                            ],
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
                          ),
                const SizedBox(height: 16),
                const Text('Phường/Xã'),
                const SizedBox(height: 8),
                _selectedDistrict == null
                    ? DropdownButtonFormField<String>(
                        value: null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        items: const [
                          DropdownMenuItem<String>(
                            value: null,
                            child: Text('Chọn Quận/Huyện trước'),
                          ),
                        ],
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
                        : DropdownButtonFormField<String>(
                            value: _selectedWard,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('Chọn Phường/Xã (tùy chọn)'),
                              ),
                              ...VietnamAddresses.getWardsByDistrict(_selectedDistrict!).map((ward) {
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

