import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../utils/vietnam_addresses.dart';

/// Widget tái sử dụng cho dropdown địa chỉ có tính năng tìm kiếm
class SearchableAddressDropdown extends StatelessWidget {
  final String? value;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;
  final AddressType type;
  final String? province; // Cần khi type là District hoặc Ward
  final String? district; // Cần khi type là Ward
  final bool isRequired;
  final String? hintText;
  final String? labelText;
  final String? allOptionText; // Text cho option "Tất cả" (dùng trong filter)

  const SearchableAddressDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    required this.type,
    this.validator,
    this.province,
    this.district,
    this.isRequired = false,
    this.hintText,
    this.labelText,
    this.allOptionText,
  });

  List<String> _getItems() {
    List<String> items;
    switch (type) {
      case AddressType.province:
        items = VietnamAddresses.provinces.toSet().toList();
        break;
      case AddressType.district:
        if (province == null) return [];
        items = VietnamAddresses.getDistrictsByProvince(province!).toSet().toList();
        break;
      case AddressType.ward:
        if (district == null) return [];
        items = VietnamAddresses.getWardsByDistrict(district!).toSet().toList();
        break;
    }
    
    // Nếu có allOptionText, thêm vào đầu danh sách
    if (allOptionText != null && items.isNotEmpty) {
      items = [allOptionText!, ...items];
    }
    
    return items;
  }

  IconData _getIcon() {
    switch (type) {
      case AddressType.province:
        return Icons.map;
      case AddressType.district:
        return Icons.location_city;
      case AddressType.ward:
        return Icons.location_on;
    }
  }

  String _getDefaultLabel() {
    switch (type) {
      case AddressType.province:
        return 'Tỉnh/Thành phố';
      case AddressType.district:
        return 'Quận/Huyện';
      case AddressType.ward:
        return 'Phường/Xã';
    }
  }

  String _getDefaultHint() {
    switch (type) {
      case AddressType.province:
        return 'Chọn Tỉnh/Thành phố';
      case AddressType.district:
        return 'Chọn Quận/Huyện';
      case AddressType.ward:
        return 'Chọn Phường/Xã (tùy chọn)';
    }
  }

  String _getDisabledHint() {
    switch (type) {
      case AddressType.province:
        return 'Chọn Tỉnh/Thành phố';
      case AddressType.district:
        return 'Chọn Tỉnh/Thành phố trước';
      case AddressType.ward:
        return 'Chọn Quận/Huyện trước';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getItems();
    final isEnabled = items.isNotEmpty;
    final defaultLabel = labelText ?? _getDefaultLabel();
    final defaultHint = hintText ?? _getDefaultHint();

    // Nếu không có items (chưa chọn cấp trên), hiển thị dropdown disabled
    if (!isEnabled) {
      return DropdownSearch<String>(
        popupProps: PopupProps.menu(
          showSearchBox: false,
          disabledItemFn: (item) => true,
        ),
        items: const [],
        selectedItem: null,
        enabled: false,
        dropdownDecoratorProps: DropDownDecoratorProps(
          baseStyle: const TextStyle(color: Colors.grey),
          dropdownSearchDecoration: InputDecoration(
            labelText: defaultLabel,
            hintText: _getDisabledHint(),
            border: const OutlineInputBorder(),
            prefixIcon: Icon(_getIcon()),
            disabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
        validator: validator,
      );
    }

    // Xử lý selectedItem: nếu value là null và có allOptionText, dùng allOptionText
    final selectedItem = (value == null && allOptionText != null) ? allOptionText : value;
    
    // Xử lý onChanged: nếu chọn allOptionText, trả về null
    void Function(String?)? handleOnChanged = onChanged;
    if (allOptionText != null && onChanged != null) {
      handleOnChanged = (String? newValue) {
        if (newValue == allOptionText) {
          onChanged?.call(null);
        } else {
          onChanged?.call(newValue);
        }
      };
    }
    
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: true,
        showSelectedItems: true,
        itemBuilder: (context, item, isSelected) {
          return ListTile(
            title: Text(item),
            selected: isSelected,
            selectedTileColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          );
        },
        constraints: const BoxConstraints(maxHeight: 400),
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Tìm kiếm ${defaultLabel.toLowerCase()}...',
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      items: items,
      selectedItem: selectedItem,
      onChanged: handleOnChanged,
      filterFn: (item, filter) {
        return item.toLowerCase().contains(filter.toLowerCase());
      },
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: defaultLabel + (isRequired ? ' *' : ''),
          hintText: defaultHint,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(_getIcon()),
        ),
      ),
      validator: validator,
    );
  }
}

enum AddressType {
  province,
  district,
  ward,
}

