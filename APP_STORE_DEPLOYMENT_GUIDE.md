# 📱 HƯỚNG DẪN BUILD VÀ XUẤT BẢN APP LÊN APP STORE (Mac Mini)

Hướng dẫn chi tiết từng bước cho người chưa từng dùng Mac Mini, từ cài đặt đến xuất bản app lên App Store.

---

## 📋 MỤC LỤC

1. [Chuẩn bị](#1-chuẩn-bị)
2. [Cài đặt Xcode](#2-cài-đặt-xcode)
3. [Cài đặt Flutter](#3-cài-đặt-flutter)
4. [Cài đặt CocoaPods](#4-cài-đặt-cocoapods)
5. [Clone code từ Git](#5-clone-code-từ-git)
6. [Cài đặt Dependencies](#6-cài-đặt-dependencies)
7. [Cấu hình Signing trong Xcode](#7-cấu-hình-signing-trong-xcode)
8. [Build App](#8-build-app)
9. [Archive và Upload lên App Store Connect](#9-archive-và-upload-lên-app-store-connect)
10. [Chuẩn bị Screenshots và Icon](#10-chuẩn-bị-screenshots-và-icon)
11. [Submit để Review](#11-submit-để-review)
12. [Xử lý Lỗi Thường Gặp](#12-xử-lý-lỗi-thường-gặp)

---

## 1. CHUẨN BỊ

### 1.1. Kiểm tra tài khoản Apple Developer

✅ **Bạn đã có:**
- Tài khoản Apple Developer ($99/năm)
- Đã đăng ký và thanh toán thành công

### 1.2. Thông tin cần chuẩn bị

- **Bundle ID**: `com.tangdo.tangDo` (đã cấu hình sẵn trong code)
- **App Name**: `TangDo`
- **Apple ID**: Email đăng nhập Apple Developer của bạn
- **Git Repository URL**: URL của repository chứa code (GitHub, GitLab, Bitbucket, etc.)

---

## 2. CÀI ĐẶT XCODE

### Bước 2.1: Mở App Store trên Mac Mini

1. Click vào biểu tượng **App Store** trên Dock (thanh dưới cùng màn hình)
2. Hoặc tìm "App Store" trong Spotlight (nhấn `Cmd + Space`, gõ "App Store")

### Bước 2.2: Tìm và cài đặt Xcode

1. Trong App Store, tìm kiếm: **"Xcode"**
2. Click vào **"Get"** hoặc **"Install"** (miễn phí, nhưng cần đăng nhập Apple ID)
3. **Lưu ý**: Xcode rất lớn (~15-20GB), cài đặt sẽ mất 30-60 phút tùy tốc độ mạng
4. Đợi Xcode tải và cài đặt xong

### Bước 2.3: Mở Xcode lần đầu và chấp nhận license

1. Mở **Finder** (biểu tượng mặt cười trên Dock)
2. Vào **Applications** (Ứng dụng)
3. Tìm và mở **Xcode**
4. Lần đầu mở sẽ có popup yêu cầu chấp nhận license:
   - Click **"Agree"** (Đồng ý)
   - Nhập mật khẩu Mac của bạn
5. Xcode sẽ tự động cài đặt thêm các components cần thiết (mất 5-10 phút)

### Bước 2.4: Cài đặt Command Line Tools

1. Mở **Terminal** (tìm trong Spotlight: `Cmd + Space`, gõ "Terminal")
2. Chạy lệnh:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   ```
3. Nhập mật khẩu Mac của bạn (khi gõ sẽ không hiện ký tự, cứ gõ bình thường và Enter)
4. Chạy tiếp:
   ```bash
   sudo xcodebuild -license accept
   ```
5. Nhập mật khẩu lần nữa

### Bước 2.5: Kiểm tra Xcode đã cài đặt đúng

Trong Terminal, chạy:
```bash
xcodebuild -version
```

Kết quả sẽ hiển thị phiên bản Xcode (ví dụ: `Xcode 15.0` hoặc `Xcode 16.0`)

---

## 3. CÀI ĐẶT FLUTTER

### Bước 3.1: Tải Flutter SDK

1. Mở trình duyệt Safari (hoặc Chrome) trên Mac Mini
2. Truy cập: https://docs.flutter.dev/get-started/install/macos
3. Tải Flutter SDK cho macOS:
   - Click vào link **"Download Flutter SDK"**
   - Chọn file `.zip` (không chọn `git clone`)
   - File sẽ tự động tải về thư mục **Downloads**

### Bước 3.2: Giải nén và di chuyển Flutter

1. Mở **Finder**
2. Vào thư mục **Downloads**
3. Tìm file `flutter_macos_xxx.zip` (xxx là số phiên bản)
4. Double-click để giải nén (sẽ tạo thư mục `flutter`)
5. Di chuyển thư mục `flutter` vào thư mục chính:
   - Kéo thả thư mục `flutter` từ Downloads vào **Home** (biểu tượng ngôi nhà trên sidebar)
   - Hoặc copy vào: `/Users/[tên-user-của-bạn]/flutter`

### Bước 3.3: Thêm Flutter vào PATH

1. Mở **Terminal**
2. Chạy lệnh để mở file cấu hình:
   ```bash
   nano ~/.zshrc
   ```
   (Nếu dùng bash thay vì zsh, dùng: `nano ~/.bash_profile`)

3. Thêm dòng này vào cuối file:
   ```bash
   export PATH="$PATH:$HOME/flutter/bin"
   ```

4. Lưu file:
   - Nhấn `Ctrl + O` (chữ O, không phải số 0)
   - Nhấn `Enter` để xác nhận
   - Nhấn `Ctrl + X` để thoát

5. Áp dụng cấu hình:
   ```bash
   source ~/.zshrc
   ```
   (Hoặc `source ~/.bash_profile` nếu dùng bash)

### Bước 3.4: Kiểm tra Flutter đã cài đặt đúng

Chạy lệnh:
```bash
flutter --version
```

Kết quả sẽ hiển thị phiên bản Flutter (ví dụ: `Flutter 3.24.0`)

### Bước 3.5: Chạy Flutter Doctor để kiểm tra môi trường

Chạy lệnh:
```bash
flutter doctor
```

Kết quả sẽ hiển thị các thành phần đã cài đặt. Bạn sẽ thấy:
- ✅ Flutter (installed)
- ✅ Android toolchain (nếu cần, nhưng không bắt buộc cho iOS)
- ✅ Xcode (installed)
- ⚠️ CocoaPods (chưa cài - sẽ cài ở bước tiếp theo)

---

## 4. CÀI ĐẶT COCOAPODS

CocoaPods là công cụ quản lý dependencies cho iOS.

### Bước 4.1: Cài đặt CocoaPods

Trong Terminal, chạy:
```bash
sudo gem install cocoapods
```

Nhập mật khẩu Mac của bạn khi được hỏi.

**Lưu ý**: Nếu gặp lỗi về quyền, có thể cần cài đặt Homebrew trước (xem phần Xử lý Lỗi).

### Bước 4.2: Kiểm tra CocoaPods đã cài đặt

Chạy:
```bash
pod --version
```

Kết quả sẽ hiển thị phiên bản (ví dụ: `1.15.0`)

---

## 5. CLONE CODE TỪ GIT

### Bước 5.1: Mở Terminal và chuyển đến thư mục làm việc

1. Mở **Terminal**
2. Chuyển đến thư mục bạn muốn lưu code (ví dụ: Desktop hoặc Documents):
   ```bash
   cd ~/Desktop
   ```
   (Hoặc `cd ~/Documents` nếu muốn lưu trong Documents)

### Bước 5.2: Clone repository

Chạy lệnh clone (thay `[URL-REPOSITORY]` bằng URL thật của bạn):
```bash
git clone [URL-REPOSITORY]
```

**Ví dụ:**
- GitHub: git clone https://github.com/huyhuyhuy/tang_do.git


### Bước 5.3: Chuyển vào thư mục project
Sau khi clone xong, chuyển vào thư mục:
```bash
cd app_tang_do
```

(Lưu ý: có thể cần `cd app_tang_do` hoặc `cd tang_do` tùy cấu trúc repository của bạn)

### Bước 5.4: Kiểm tra code đã clone đúng

Chạy:
```bash
ls -la
```

Bạn sẽ thấy các file như `pubspec.yaml`, `lib/`, `ios/`, `android/`, etc.

---

## 6. CÀI ĐẶT DEPENDENCIES

### Bước 6.1: Cài đặt Flutter dependencies

Trong Terminal, đảm bảo đang ở thư mục `app_tang_do`, chạy:
```bash
flutter pub get
```

Lệnh này sẽ tải và cài đặt tất cả packages trong `pubspec.yaml`.

### Bước 6.2: Cài đặt iOS dependencies (CocoaPods)

1. Chuyển vào thư mục iOS:
   ```bash
   cd ios
   ```

2. Cài đặt pods:
   ```bash
   pod install
   ```

   **Lưu ý**: Lần đầu chạy sẽ mất 5-10 phút để tải các dependencies.

3. Sau khi xong, quay lại thư mục gốc:
   ```bash
   cd ..
   ```

### Bước 6.3: Kiểm tra Flutter Doctor một lần nữa

Chạy:
```bash
flutter doctor
```

Tất cả các mục nên hiển thị ✅ (hoặc ít nhất Xcode và CocoaPods phải ✅)

---

## 7. CẤU HÌNH SIGNING TRONG XCODE

Đây là bước quan trọng để app có thể build và upload lên App Store.

### Bước 7.1: Mở project trong Xcode

1. Trong Terminal, đảm bảo đang ở thư mục `app_tang_do`
2. Mở project iOS trong Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
   
   **LƯU Ý**: Phải mở `.xcworkspace`, KHÔNG phải `.xcodeproj`!

3. Xcode sẽ mở và hiển thị project

### Bước 7.2: Chọn target Runner

1. Ở sidebar bên trái, click vào **"Runner"** (biểu tượng màu xanh ở trên cùng)
2. Ở giữa màn hình, chọn tab **"Signing & Capabilities"**

### Bước 7.3: Cấu hình Team và Bundle Identifier

1. **Team**: 
   - Click dropdown "Team"
   - Chọn team Apple Developer của bạn (sẽ hiển thị tên hoặc email)
   - Nếu chưa thấy, click **"Add Account..."** và đăng nhập Apple ID của bạn

2. **Bundle Identifier**:
   - Đảm bảo là: `com.tangdo.tangDo`
   - Nếu khác, sửa lại cho đúng

3. **Automatically manage signing**:
   - ✅ Đảm bảo checkbox này được BẬT (checked)

4. Xcode sẽ tự động tạo **Provisioning Profile** và **Signing Certificate**
   - Nếu thành công, bạn sẽ thấy dấu ✅ xanh
   - Nếu có lỗi, xem phần Xử lý Lỗi

### Bước 7.4: Chọn scheme và device

1. Ở thanh trên cùng Xcode, bên trái có dropdown hiển thị:
   - **Scheme**: Chọn **"Runner"**
   - **Device**: Chọn **"Any iOS Device (arm64)"** (KHÔNG chọn simulator)

---

## 8. BUILD APP

### Bước 8.1: Kiểm tra và tăng Version/Build Number (QUAN TRỌNG)

**TRƯỚC KHI BUILD**, bạn cần kiểm tra version trong `pubspec.yaml`:

1. Mở file `pubspec.yaml`
2. Tìm dòng `version: X.X.X+X` (ví dụ: `version: 1.0.3+4`)
3. **Tăng build number** (số sau dấu `+`) để App Store Connect nhận build mới:
   - Ví dụ: `1.0.3+4` → `1.0.3+5`
   - Hoặc tăng version: `1.0.3+4` → `1.0.4+1`

**Lưu ý:** Nếu upload build mới với cùng version/build number, App Store Connect có thể từ chối hoặc không cập nhật.

### Bước 8.2: Build bằng Flutter (Khuyến nghị)

Trong Terminal, đảm bảo đang ở thư mục `app_tang_do`, chạy:
```bash
flutter clean
flutter pub get
flutter build ios --release
```

Lệnh này sẽ:
- Xóa cache cũ (`flutter clean`)
- Cài lại dependencies (`flutter pub get`)
- Build app ở chế độ release (`flutter build ios --release`)
- Tạo file `.app` trong `build/ios/iphoneos/`

**Lưu ý**: Build lần đầu sẽ mất 5-10 phút.

### Bước 8.3: Kiểm tra build thành công

Sau khi build xong, bạn sẽ thấy:
```
✓ Built build/ios/iphoneos/Runner.app
```

**LƯU Ý QUAN TRỌNG:**
- File `.app` này là cho **iOS/App Store**
- Đảm bảo version/build number đã được tăng trước khi build

---

## 9. ARCHIVE VÀ UPLOAD LÊN APP STORE CONNECT

### Bước 9.1: Mở Xcode và chọn Product > Archive

1. Mở Xcode (đã mở từ bước 7.1)
2. Trên thanh menu, chọn: **Product** → **Archive**
3. Xcode sẽ build lại và tạo Archive
4. Quá trình này mất 3-5 phút

### Bước 9.2: Kiểm tra Archive thành công

Sau khi Archive xong, cửa sổ **Organizer** sẽ tự động mở:
- Bạn sẽ thấy Archive vừa tạo với ngày giờ hiện tại
- Status sẽ hiển thị **"Ready to Submit"** hoặc **"Ready to Distribute"**

### Bước 9.3: Upload lên App Store Connect

1. Trong cửa sổ Organizer, chọn Archive vừa tạo
2. Click nút **"Distribute App"** (màu xanh, ở bên phải)
3. Chọn **"App Store Connect"** → Click **"Next"**
4. Chọn **"Upload"** → Click **"Next"**
5. Chọn **"Automatically manage signing"** → Click **"Next"**
6. Xem lại thông tin → Click **"Upload"**
7. Xcode sẽ upload app lên App Store Connect
   - Quá trình này mất 5-15 phút tùy tốc độ mạng
   - Bạn sẽ thấy progress bar

chú ý sửa tên:
Trong dialog "Upload for App Store Connect", bạn thấy:
Name: "Runner" → cần đổi thành "TangDo"
SKU: "com.tangdo.tangDo" → đúng
Primary Language: "Vietnamese" → đúng
Bundle Identifier: "com.tangdo.tangDo" → đúng

### Bước 9.4: Kiểm tra upload thành công

1. Sau khi upload xong, bạn sẽ thấy thông báo **"Upload Successful"**
2. Mở trình duyệt, truy cập: https://appstoreconnect.apple.com
3. Đăng nhập bằng Apple ID Developer của bạn
4. Vào **"My Apps"** → Kiểm tra xem app **"TangDo"** đã có chưa

**LƯU Ý QUAN TRỌNG:**
- Khi upload build lần đầu tiên, **Xcode có thể tự động tạo App record** trong App Store Connect
- Nếu bạn thấy dialog "Upload for App Store Connect" với thông tin Name, SKU, Bundle ID → Xcode sẽ tự động tạo app record
- Nếu app **"TangDo"** đã xuất hiện trong danh sách "My Apps" → App record đã được tạo tự động, bạn có thể **BỎ QUA bước 11.1**
- Nếu app **chưa có** trong danh sách → Cần tạo thủ công ở bước 11.1

5. Vào app **"TangDo"** → Tab **"TestFlight"** hoặc **"App Store"**
6. Bạn sẽ thấy build vừa upload (có thể đang ở trạng thái "Processing")

---

## 10. CHUẨN BỊ SCREENSHOTS VÀ ICON

- **App Icon**: 1024x1024px (PNG, không trong suốt)
- **Screenshots**: 5-10  screenshot cho iPhone

### Bước 10.1: Chụp Screenshots từ iPhone Simulator

#### Cách 1: Dùng Xcode Simulator (Khuyến nghị)

1. **Mở Simulator:**
   - Mở Simulator từ: **Xcode** → **Open Developer Tool** → **Simulator**
   - hoặc chạy lệnh: open -a Simulator

2. **Chạy app trên Simulator:**
   - Ở terminal thư mục `app_tang_do` chạy lệnh:
   ```bash
   flutter run
   ```
   - App sẽ mở trên Simulator

-> chụp màn hình.

#### Cách 2: Dùng iPhone thật

1. **Cài app lên iPhone:**
   - Cắm iPhone vào Mac Mini
   - Trong Xcode, chọn device là iPhone của bạn
   - Chạy app (`flutter run` hoặc click Run trong Xcode)

2. **Chụp screenshot trên iPhone:**
   - Nhấn nút Home + Power (hoặc Volume Up + Power trên iPhone X trở lên)
   - Screenshot sẽ lưu vào Photos trên iPhone

App Store yêu cầu screenshots cho các kích thước khác nhau:

#### iPhone Screenshots (BẮT BUỘC):
- **iPhone 6.7" (iPhone 14 Pro Max, 15 Pro Max)**: 1290 x 2796 pixels
- **iPhone 6.5" (iPhone 11 Pro Max, XS Max)**: 1242 x 2688 pixels
- **iPhone 5.5" (iPhone 8 Plus)**: 1242 x 2208 pixels

**Lưu ý**: Bạn chỉ cần upload cho **một kích thước** (khuyến nghị: 6.7"), Apple sẽ tự động scale cho các kích thước khác.

#### Cách resize screenshots:

1. **Dùng Preview trên Mac:**
   - Mở screenshot trong Preview
   - **Tools** → **Adjust Size**
   - Nhập kích thước mới (ví dụ: Width 1290, Height 2796)
   - Chọn **Scale proportionally** (nếu cần)
   - Click **OK**
   - **File** → **Export** → Chọn PNG


### Bước 10.5: Lưu trữ Screenshots và Icon

Tạo một thư mục để lưu tất cả:

```bash
mkdir ~/Desktop/App_Store_Assets
cd ~/Desktop/App_Store_Assets
mkdir Screenshots
mkdir Icon
```

- Copy icon vào: `Icon/app_icon_1024x1024.png`
- Copy screenshots vào: `Screenshots/`

**Đặt tên file rõ ràng:**
- `screenshot_1_home.png`
- `screenshot_2_product_detail.png`
- `screenshot_3_add_product.png`
- `screenshot_4_profile.png`
- `screenshot_5_contacts.png`
- `app_icon_1024x1024.png`

---

## 11. SUBMIT ĐỂ REVIEW

### Bước 11.1: Kiểm tra App đã có trong App Store Connect chưa

**QUAN TRỌNG:** Khi upload build ở bước 9, Xcode có thể đã tự động tạo App record trong App Store Connect. Bạn cần kiểm tra trước:

1. Truy cập: https://appstoreconnect.apple.com
2. Vào **"My Apps"**
3. Kiểm tra xem app **"TangDo"** đã có trong danh sách chưa

có thể nó sẽ ở trạng thái **"Processing"** trong 10-30 phút
- Sau khi xong, status sẽ đổi thành **"Ready to Submit"**

### Bước 11.3: Điền thông tin App Store Listing

Bạn đang ở trang **"iOS App Version 1.0"** trong App Store Connect. Điền các thông tin sau theo thứ tự:

---

#### 1. PREVIEWS AND SCREENSHOTS (BẮT BUỘC)

**Vị trí:** Phần đầu tiên trên trang, có tiêu đề "Previews and Screenshots"

**Các bước:**

1. **Chọn tab "iPhone"** (đã được chọn sẵn)
2. **Chọn kích thước Display:**
   - Click vào dropdown hiển thị **"iPhone 6.5" Display"**
   - Chọn **"iPhone 6.5" Display"** (1242 x 2688px) - **KHUYẾN NGHỊ**
   - Hoặc chọn kích thước khác nếu bạn đã resize screenshots theo kích thước đó

3. **Upload Screenshots:**
   - **Cách 1:** Kéo thả các file screenshot vào vùng "Drag up to 3 app previews and 10 screenshots here"
   - **Cách 2:** Click **"Choose File"** → Chọn các file screenshot đã resize (chọn nhiều file cùng lúc bằng `Cmd + Click`)
   - **Tối thiểu:** 1 screenshot
   - **Khuyến nghị:** 3-5 screenshots
   - **Tối đa:** 10 screenshots

4. **Sắp xếp thứ tự:**
   - Sau khi upload, bạn có thể kéo thả để sắp xếp lại thứ tự
   - **Screenshot đầu tiên** sẽ hiển thị đầu tiên trên App Store
   - **Khuyến nghị thứ tự:**
     1. Màn hình Home/Trang chủ (hiển thị grid sản phẩm)
     2. Màn hình Chi tiết sản phẩm
     3. Màn hình Đăng sản phẩm
     4. Màn hình Profile
     5. Màn hình Danh bạ/Contacts (nếu có)

5. **Kiểm tra:**
   - Đảm bảo screenshots hiển thị đúng
   - Không có frame iPhone (Apple sẽ tự động thêm)
   - Không có watermark, text overlay (trừ text trong app)
   - Không có nút "Download", "Get", "Free"

**Lưu ý:** App Previews (video) là tùy chọn, không bắt buộc. Bạn có thể bỏ qua phần này.

---

#### 2. PROMOTIONAL TEXT (TÙY CHỌN)

**Vị trí:** Phần thứ hai, có tiêu đề "Promotional Text"

**Mục đích:** Text này sẽ hiển thị ngay dưới app name trên App Store, 
dùng để quảng bá tính năng mới hoặc khuyến mãi.

**Yêu cầu:**
- Tối đa **170 ký tự**
- Có thể để trống (không bắt buộc)
- Có thể cập nhật bất cứ lúc nào mà không cần submit lại

**Ví dụ điền:**
```
Chia sẻ đồ cũ, tặng yêu thương! Tìm và nhận đồ miễn phí từ cộng đồng ngay hôm nay.
```
Hoặc:
```
Ứng dụng tặng đồ miễn phí. Chia sẻ đồ cũ, nhận đồ mới, kết nối cộng đồng.
```

**Bạn có thể:**
- Điền ngay bây giờ
- Hoặc để trống và điền sau

---

#### 3. DESCRIPTION (BẮT BUỘC)

**Vị trí:** Phần thứ ba, có tiêu đề "Description"

**Mục đích:** Mô tả chi tiết về app, tính năng, cách sử dụng.

**Yêu cầu:**
- Tối đa **4,000 ký tự**
- **BẮT BUỘC** phải điền
- Nên viết bằng tiếng Việt (vì Primary Language là Vietnamese)

**Cấu trúc mô tả gợi ý:**

```
TangDo - Ứng dụng chia sẻ và tặng đồ cũ miễn phí

TangDo là ứng dụng kết nối cộng đồng, cho phép bạn chia sẻ đồ cũ không dùng đến và nhận đồ miễn phí từ người khác. Hãy cùng nhau tạo nên một cộng đồng chia sẻ ý nghĩa!

✨ TÍNH NĂNG CHÍNH:

🎁 Đăng và tìm đồ miễn phí
- Đăng sản phẩm muốn tặng với hình ảnh và mô tả chi tiết
- Tìm kiếm đồ theo danh mục, địa điểm
- Lọc theo tỉnh/thành phố, quận/huyện
- Xem chi tiết sản phẩm với nhiều hình ảnh

⭐ Đánh giá và nhận xét
- Đánh giá sản phẩm bằng sao (1-5 sao)
- Viết nhận xét để giúp người khác
- Xem điểm đánh giá trung bình trên mỗi sản phẩm

👥 Quản lý danh bạ
- Lưu thông tin liên hệ của người tặng
- Dễ dàng gọi điện hoặc copy địa chỉ
- Quản lý danh sách contacts

📱 Quản lý sản phẩm
- Xem tất cả sản phẩm bạn đã đăng
- Chỉnh sửa hoặc xóa sản phẩm
- Tự động hết hạn sau số ngày đã đặt

🔔 Thông báo
- Nhận thông báo khi có đánh giá mới
- Cập nhật real-time về hoạt động

🔒 Bảo mật và riêng tư
- Thông tin cá nhân được bảo vệ
- Chỉ hiển thị thông tin cần thiết
- Quản lý profile an toàn

Tải ngay TangDo và bắt đầu chia sẻ yêu thương ngay hôm nay!
```

**Hoặc bạn có thể viết ngắn gọn hơn:**

```
TangDo - Ứng dụng chia sẻ và tặng đồ cũ miễn phí

Chia sẻ đồ cũ không dùng đến và nhận đồ miễn phí từ cộng đồng. Hãy cùng nhau tạo nên một môi trường chia sẻ ý nghĩa!

Tính năng chính:
• Đăng và tìm đồ miễn phí
• Tìm kiếm theo danh mục, địa điểm
• Đánh giá và nhận xét sản phẩm
• Quản lý danh bạ liên hệ
• Thông báo real-time

Dễ dàng sử dụng, an toàn và miễn phí. Tải ngay và tham gia cộng đồng chia sẻ!
```

**Lưu ý:**
- Viết bằng tiếng Việt (vì Primary Language là Vietnamese)
- Sử dụng emoji để làm nổi bật (tùy chọn)
- Liệt kê các tính năng chính
- Không được có link, email, số điện thoại trong Description
- Không được có text như "Download now", "Get it free"

---

#### 4. CÁC THÔNG TIN KHÁC (Scroll xuống để tìm)

Sau khi điền 3 phần trên, scroll xuống để tìm và điền các thông tin sau:

##### 4.1. Keywords (Từ khóa tìm kiếm)

**Vị trí:** Scroll xuống, tìm phần "Keywords"

**Yêu cầu:**
- Tối đa **100 ký tự**
- Các từ khóa cách nhau bằng **dấu phẩy** (không có khoảng trắng sau dấu phẩy)
- **BẮT BUỘC** phải điền

**Ví dụ điền:**
```
tặng đồ,chia sẻ,đồ cũ,miễn phí,quyên góp,trao tặng,cộng đồng,đồ điện tử,quần áo
```

Hoặc:
```
tặng đồ miễn phí,chia sẻ đồ cũ,quyên góp,trao tặng,cộng đồng,đồ điện tử,quần áo,sách
```

**Lưu ý:**
- Không được có khoảng trắng sau dấu phẩy
- Không được trùng với tên app
- Nên dùng từ khóa liên quan đến app

##### 4.2. Support URL (URL hỗ trợ)

**Vị trí:** Scroll xuống, tìm phần "Support URL"

**Yêu cầu:**
- **BẮT BUỘC** phải điền
- Phải là URL hợp lệ (bắt đầu bằng `http://` hoặc `https://`)

**Ví dụ điền:**
```
https://tangdo.com/support
```

Hoặc nếu chưa có website:
```
https://tangdo.com
```

**Lưu ý:** Nếu bạn chưa có website, có thể tạo một trang đơn giản hoặc dùng GitHub Pages.

**Lưu ý:** Nếu bạn chưa có website, có thể tạo một trang đơn giản hoặc dùng GitHub Pages.

##### 4.3. Marketing URL (Tùy chọn)

**Vị trí:** Scroll xuống, tìm phần "Marketing URL"

**Yêu cầu:**
- **TÙY CHỌN** (có thể để trống)
- Nếu có, phải là URL hợp lệ

**Ví dụ điền:**
```
https://tangdo.com
```

Hoặc để trống nếu chưa có.

##### 4.4. Privacy Policy URL (BẮT BUỘC)

**Vị trí:** Scroll xuống, tìm phần "Privacy Policy URL"

**Yêu cầu:**
- **BẮT BUỘC** phải điền
- Phải là URL hợp lệ
- Phải có trang Privacy Policy thực sự (không được để trống hoặc link lỗi)

**Ví dụ điền:**
```
https://tangdo.com/privacy
```

**Lưu ý:** 
- Nếu bạn chưa có Privacy Policy, cần tạo ngay. Có thể dùng:
  - Công cụ tạo Privacy Policy online (ví dụ: https://www.privacypolicygenerator.info/)
  - Hoặc tự viết và đăng lên website

##### 4.5. Category (Danh mục)

**Vị trí:** Scroll xuống, tìm phần "Category"

**Yêu cầu:**
- **BẮT BUỘC** phải chọn
- Chọn **Primary Category** (danh mục chính)
- Có thể chọn **Secondary Category** (danh mục phụ) - tùy chọn

**Gợi ý chọn:**
- **Primary Category:** Chọn **"Lifestyle"** (Phong cách sống) hoặc **"Social Networking"** (Mạng xã hội)
- **Secondary Category:** Có thể chọn **"Utilities"** (Tiện ích) hoặc để trống

**Cách chọn:**
1. Click vào dropdown "Primary Category"
2. Chọn **"Lifestyle"** hoặc **"Social Networking"**
3. (Tùy chọn) Chọn Secondary Category

##### 4.6. App Icon

**Vị trí:** Scroll xuống, tìm phần "App Icon"

**Yêu cầu:**
- **BẮT BUỘC** phải upload
- Kích thước: **1024 x 1024 pixels**
- Định dạng: **PNG**
- Không trong suốt (phải có background)

**Các bước:**
1. Click vào vùng upload App Icon
2. Chọn file `app_icon_1024x1024.png` đã chuẩn bị ở bước 10.1
3. Đợi upload xong (có thể mất 1-2 phút)
4. Kiểm tra icon hiển thị đúng

---

#### 5. LƯU THÔNG TIN

Sau khi điền xong tất cả các thông tin trên:

1. Scroll lên đầu trang
2. Click nút **"Save"** (màu xám, ở góc trên bên phải)
3. Đợi lưu xong (có thể mất vài giây)
4. Kiểm tra không có lỗi nào

**Lưu ý:** 
- Bạn có thể lưu và quay lại chỉnh sửa sau
- Không cần điền hết tất cả ngay một lúc
- Nhưng **phải điền đầy đủ** trước khi Submit để Review

### Bước 11.4: Chọn build và Submit

1. Scroll xuống phần **"Build"**
2. Click **"+ Version or Platform"** → Chọn build vừa upload (build mới nhất)
   - **Lưu ý:** Nếu có nhiều builds, chọn build mới nhất (có ngày giờ upload gần nhất)
   - Build cũ sẽ vẫn còn trong danh sách nhưng không được sử dụng
3. Điền thông tin **"Version Information"**:
   - **Version**: `1.0.2` (hoặc version hiện tại trong `pubspec.yaml`)
   - **What's New in This Version**: Mô tả các thay đổi (ví dụ: "Phiên bản đầu tiên - Tính năng chia sẻ và tặng đồ cũ")
4. Trả lời các câu hỏi **"App Review Information"**:
   - **Contact Information**: Email và số điện thoại
   - **Demo Account**: (nếu cần)
   - **Notes**: Ghi chú cho reviewer (nếu cần)
5. Click **"Add for Review"**
6. Xác nhận và click **"Submit for Review"**

**Lưu ý quan trọng về Builds:**
- Build cũ **KHÔNG tự động xóa** và **KHÔNG cần xóa bằng tay**
- Khi upload build mới, bạn chỉ cần **chọn build mới** trong dropdown "Build"
- Build cũ sẽ vẫn còn trong danh sách nhưng không được sử dụng
- **Tất cả thông tin đã điền** (Description, Screenshots, Keywords, etc.) **KHÔNG mất** - đó là metadata của app, không phải của build

### Bước 11.5: Theo dõi trạng thái Review

- App sẽ ở trạng thái **"Waiting for Review"**
- Apple sẽ review trong 1-3 ngày làm việc
- Bạn sẽ nhận email khi có kết quả

---

## 12. XỬ LÝ LỖI THƯỜNG GẶP

### Lỗi 12.1: "Command Line Tools not found"

**Nguyên nhân**: Chưa cài đặt Command Line Tools

**Giải pháp**:
```bash
sudo xcode-select --install
```

Sau đó làm lại bước 2.4.

---

### Lỗi 12.2: "CocoaPods installation failed"

**Nguyên nhân**: Quyền truy cập hoặc Ruby version

**Giải pháp 1**: Cài đặt Homebrew trước:
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Sau đó cài CocoaPods:
```bash
brew install cocoapods
```

**Giải pháp 2**: Dùng rbenv để quản lý Ruby version (nâng cao)

---

### Lỗi 12.3: "No signing certificate found"

**Nguyên nhân**: Chưa đăng nhập Apple ID trong Xcode hoặc Team chưa được chọn

**Giải pháp**:
1. Mở Xcode → **Preferences** (hoặc `Cmd + ,`)
2. Vào tab **"Accounts"**
3. Click **"+"** → Chọn **"Apple ID"**
4. Đăng nhập bằng Apple ID Developer của bạn
5. Quay lại bước 7.3 và chọn Team

---

### Lỗi 12.4: "Bundle identifier is already in use"

**Nguyên nhân**: Bundle ID `com.tangdo.tangDo` đã được sử dụng bởi app khác

**Giải pháp**:
1. Kiểm tra trong App Store Connect xem Bundle ID đã được đăng ký chưa
2. Nếu chưa, tạo App mới trong App Store Connect với Bundle ID này
3. Nếu đã có app khác dùng, cần đổi Bundle ID (không khuyến nghị)

---

### Lỗi 12.5: "Pod install failed"

**Nguyên nhân**: Lỗi khi cài đặt CocoaPods dependencies

**Giải pháp**:
1. Xóa cache:
   ```bash
   cd ios
   rm -rf Pods Podfile.lock
   pod cache clean --all
   ```

2. Cài lại:
   ```bash
   pod install --repo-update
   ```

---

### Lỗi 12.6: "Flutter doctor shows issues"

**Nguyên nhân**: Một số components chưa được cài đặt đầy đủ

**Giải pháp**:
Chạy:
```bash
flutter doctor -v
```

Xem chi tiết lỗi và làm theo hướng dẫn. Thường thì:
- Xcode: Đã cài ở bước 2
- CocoaPods: Đã cài ở bước 4
- Android toolchain: Không cần thiết cho iOS (có thể bỏ qua)

---

### Lỗi 12.7: "Archive failed" hoặc "Build failed"

**Nguyên nhân**: Lỗi trong code hoặc cấu hình

**Giải pháp**:
1. Xem chi tiết lỗi trong Xcode (ở tab "Issue Navigator" - `Cmd + 5`)
2. Thử build bằng Flutter trước:
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter build ios --release
   ```
3. Nếu vẫn lỗi, kiểm tra:
   - Bundle ID đúng chưa
   - Signing đã cấu hình chưa
   - Dependencies đã cài đầy đủ chưa

---

### Lỗi 12.8: "Upload failed" - Invalid Bundle

**Nguyên nhân**: Thiếu thông tin trong Info.plist hoặc cấu hình sai

**Giải pháp**:
1. Kiểm tra `ios/Runner/Info.plist` có đầy đủ:
   - `NSCameraUsageDescription`
   - `NSPhotoLibraryUsageDescription`
   - `NSPhotoLibraryAddUsageDescription`
   - `GADApplicationIdentifier`
2. Đảm bảo version trong `pubspec.yaml` đúng format: `1.0.3+4`

---

## 📝 CHECKLIST TRƯỚC KHI SUBMIT

Trước khi submit app lên App Store, đảm bảo:

### Build và Upload:
- ✅ Xcode đã cài đặt và cấu hình đúng
- ✅ Flutter đã cài đặt và trong PATH
- ✅ CocoaPods đã cài đặt
- ✅ Code đã clone từ Git về Mac Mini
- ✅ Dependencies đã cài đặt (`flutter pub get` và `pod install`)
- ✅ Signing đã cấu hình trong Xcode (Team và Bundle ID)
- ✅ App đã build thành công (`flutter build ios --release`)
- ✅ Archive đã tạo thành công trong Xcode
- ✅ Upload lên App Store Connect thành công
- ✅ Build đã được process xong (status: "Ready to Submit")

### App Store Listing:
- ✅ Thông tin App Store Listing đã điền đầy đủ:
  - ✅ App Name
  - ✅ Description
  - ✅ Keywords
  - ✅ Support URL
  - ✅ Privacy Policy URL (BẮT BUỘC)
  - ✅ Category đã chọn
- ✅ App Icon 1024x1024px đã upload và hiển thị đúng
- ✅ Screenshots đã upload (ít nhất 1 cái, khuyến nghị 3-5)
- ✅ Screenshots đúng kích thước và không vi phạm quy tắc
- ✅ Version Information đã điền (What's New)
- ✅ App Review Information đã điền (Contact, Demo Account nếu cần)

---

## 🎉 HOÀN THÀNH!

Sau khi submit, bạn chỉ cần đợi Apple review. Thường mất 1-3 ngày làm việc.

**Lưu ý quan trọng:**
- Kiểm tra email thường xuyên để nhận thông báo từ Apple
- Nếu bị reject, đọc kỹ lý do và sửa lại
- Sau khi được approve, app sẽ tự động xuất hiện trên App Store

---

## 📞 HỖ TRỢ

Nếu gặp vấn đề không giải quyết được:
1. Kiểm tra lại từng bước trong hướng dẫn này
2. Xem phần "Xử lý Lỗi Thường Gặp"
3. Tìm kiếm lỗi trên Google với từ khóa cụ thể
4. Tham khảo tài liệu chính thức:
   - Flutter: https://docs.flutter.dev
   - Apple Developer: https://developer.apple.com/documentation

---

**Chúc bạn thành công! 🚀**

