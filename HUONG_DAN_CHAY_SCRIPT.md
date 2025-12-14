# Hướng dẫn chạy script tạo Emulator (KHÔNG CẦN Android Studio)

## Cách chạy script

### Bước 1: Mở PowerShell
1. Nhấn `Windows + X`
2. Chọn **Windows PowerShell** hoặc **Terminal**
3. Di chuyển đến thư mục project:
   ```powershell
   cd D:\DEV_TOOL\app_tang_do
   ```

### Bước 2: Chạy script
```powershell
.\create_tablet_emulators.ps1
```

**Lưu ý:** Nếu gặp lỗi "execution policy", chạy lệnh này trước:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Bước 3: Chờ script chạy
- Script sẽ tự động:
  1. Kiểm tra system image đã cài chưa
  2. Tải system image nếu chưa có (mất ~5-10 phút, ~1GB)
  3. Tạo emulator 7 inch
  4. Tạo emulator 10 inch
  5. Cấu hình kích thước màn hình

### Bước 4: Chạy emulator
```powershell
# Xem danh sách emulators
flutter emulators

# Chạy emulator 7 inch
flutter emulators --launch Tablet_7inch

# Chạy emulator 10 inch
flutter emulators --launch Tablet_10inch
```

### Bước 5: Chạy app và chụp ảnh
```powershell
# Chạy app trên emulator 7 inch
flutter run -d Tablet_7inch
hoặc dùng id: flutter run -d emulator-5554

# Trong terminal khác, chụp màn hình
flutter screenshot screenshot_7inch.png

# Chạy app trên emulator 10 inch
flutter run -d Tablet_10inch

# Chụp màn hình
flutter screenshot screenshot_10inch.png
```

---

## Troubleshooting

### Lỗi "execution policy"
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Lỗi "system image not found"
Script sẽ tự động tải, nhưng nếu lỗi, chạy thủ công:
```powershell
C:\android-sdk\cmdline-tools\latest\bin\sdkmanager.bat "system-images;android-30;google_apis;x86_64"
```

### Emulator không hiển thị trong `flutter emulators`
Kiểm tra AVD folder:
```powershell
dir $env:USERPROFILE\.android\avd
```

### Emulator chạy chậm
- Tăng RAM trong file config: `$env:USERPROFILE\.android\avd\Tablet_7inch.avd\config.ini`
- Tìm dòng `hw.ramSize` và đổi thành `2048` hoặc `4096`

---

## Kích thước màn hình

- **7 inch**: 600 x 1024 pixels (density 213)
- **10 inch**: 800 x 1280 pixels (density 213)

