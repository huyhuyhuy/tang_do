# Hướng dẫn chi tiết đẩy app lên Google Play Store

Hướng dẫn từng bước để publish app TangDo lên Google Play Store.

---

## 📋 Mục lục

1. [Chuẩn bị trước khi publish](#1-chuẩn-bị-trước-khi-publish)
2. [Tạo Keystore cho Android](#2-tạo-keystore-cho-android)
3. [Cấu hình signing config](#3-cấu-hình-signing-config)
4. [Build App Bundle (AAB)](#4-build-app-bundle-aab)
5. [Tạo tài khoản Google Play Console](#5-tạo-tài-khoản-google-play-console)
6. [Tạo app mới trên Play Console](#6-tạo-app-mới-trên-play-console)
7. [Điền thông tin app](#7-điền-thông-tin-app)
8. [Upload App Bundle](#8-upload-app-bundle)
9. [Tạo Store Listing](#9-tạo-store-listing)
10. [Cấu hình Content Rating](#10-cấu-hình-content-rating)
11. [Cấu hình Privacy Policy](#11-cấu-hình-privacy-policy)
12. [Target Audience](#12-target-audience)
13. [Submit để review](#13-submit-để-review)

---

## 1. Chuẩn bị trước khi publish

### 1.1. Kiểm tra thông tin app

- ✅ **Package name**: `com.tangdo.tang_do` (đã có trong `android/app/build.gradle.kts`)
- ✅ **Version**: `1.0.0+1` (trong `pubspec.yaml`)
- ✅ **App name**: "TangDo" hoặc "Tặng đồ"
- ✅ **Min SDK**: Android 21 (Android 5.0) trở lên

### 1.2. Kiểm tra các yêu cầu

- [ ] App đã test kỹ trên nhiều thiết bị
- [ ] Không có crash hoặc lỗi nghiêm trọng
- [ ] Quảng cáo AdMob đã cấu hình với ID thật (đã có)
- [ ] Icon app đã có (đã có trong `android/app/src/main/res/mipmap-*`)
- [ ] Screenshots app (cần chuẩn bị)
- [ ] Privacy Policy URL (cần tạo)

### 1.3. Chuẩn bị tài liệu

Bạn cần chuẩn bị:
- **Icon app**: 512x512px (PNG, không trong suốt)
- **Feature Graphic**: 1024x500px (banner cho Play Store)
- **Screenshots**: 
  - Tối thiểu 2 ảnh, tối đa 8 ảnh
  - Kích thước: 16:9 hoặc 9:16
  - Độ phân giải: tối thiểu 320px, tối đa 3840px
- **Privacy Policy**: URL đến trang chính sách bảo mật

---

## 2. Tạo Keystore cho Android

Keystore là file chứa private key để ký app. **QUAN TRỌNG**: Lưu file này cẩn thận, nếu mất sẽ không thể update app!

### 2.1. Tạo keystore

Mở terminal/command prompt và chạy lệnh sau:

**Windows (PowerShell):**
```powershell
cd D:\DEV_TOOL\app_tang_do
keytool -genkey -v -keystore D:\DEV_TOOL\app_tang_do\android\app\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**macOS/Linux:**
```bash
cd /path/to/app_tang_do
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 2.2. Điền thông tin

Khi chạy lệnh, bạn sẽ được hỏi:
- **Enter keystore password**: Nhập mật khẩu (ví dụ: `tangdo2024@`) - **Ghi nhớ mật khẩu này!**
- **Re-enter new password**: Nhập lại mật khẩu
- **What is your first and last name?**: Tên của bạn (ví dụ: `Nguyen Van A`)
- **What is the name of your organizational unit?**: Đơn vị (ví dụ: `TangDo`)
- **What is the name of your organization?**: Tên công ty/tổ chức (ví dụ: `TangDo`)
- **What is the name of your City or Locality?**: Thành phố (ví dụ: `Ho Chi Minh City`)
- **What is the name of your State or Province?**: Tỉnh/Thành phố (ví dụ: `Ho Chi Minh`)
- **What is the two-letter country code for this unit?**: Mã quốc gia (ví dụ: `VN`)
- **Is CN=... correct?**: Nhập `yes`

### 2.3. Lưu thông tin keystore

**QUAN TRỌNG**: Tạo file `key.properties` để lưu thông tin keystore:

Tạo file `android/key.properties` với nội dung:

```properties
storePassword=tangdo2025@
keyPassword=tangdo2025@
keyAlias=upload
storeFile=upload-keystore.jks
```

**Lưu ý:**
- File này chứa thông tin nhạy cảm, **KHÔNG commit lên Git!**
- Thêm `android/key.properties` vào `.gitignore`

### 2.4. Thêm vào .gitignore

Mở file `.gitignore` và thêm:

```
# Keystore files
*.jks
*.keystore
android/key.properties
```

---

## 3. Cấu hình signing config

### 3.1. Đọc file build.gradle.kts

Mở file `android/app/build.gradle.kts` và thêm cấu hình signing.

### 3.2. Thêm code vào đầu file

Thêm vào đầu file `android/app/build.gradle.kts` (sau các import):

```kotlin
// Load keystore properties
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
}
```



Tìm section `android {` và thêm `signingConfigs`:

```kotlin
android {
    namespace = "com.tangdo.tang_do"
    compileSdk = 34

    // ... existing code ...

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 3.4. Di chuyển file key.properties

Di chuyển file `key.properties` từ `android/key.properties` sang `android/key.properties` (nếu chưa có).

Hoặc cập nhật đường dẫn trong code nếu bạn đặt file ở vị trí khác.

---

## 4. Build App Bundle (AAB)

Google Play yêu cầu file **AAB (Android App Bundle)** thay vì APK.

### 4.1. Build AAB

Chạy lệnh:

```bash
flutter build appbundle --release
```

### 4.2. Tìm file AAB

Sau khi build xong, file AAB sẽ ở:
```
build/app/outputs/bundle/release/app-release.aab
```

### 4.3. Kiểm tra kích thước file

File AAB thường nhỏ hơn APK khoảng 15-20%. Kiểm tra kích thước:
- Nếu > 150MB: Cần tối ưu hóa (xóa assets không cần thiết, nén ảnh)
- Nếu < 150MB: OK

---

## 5. Tạo tài khoản Google Play Console

### 5.1. Truy cập Google Play Console

1. Vào: https://play.google.com/console
2. Đăng nhập bằng tài khoản Google

### 5.2. Đăng ký tài khoản developer

1. Click **"Get started"** hoặc **"Create app"**
2. Chọn **"Create developer account"**
3. Điền thông tin:
   - **Developer name**: Tên hiển thị (ví dụ: "TangDo" hoặc tên của bạn)
   - **Email**: Email liên hệ
   - **Phone**: Số điện thoại
   - **Country/Region**: Việt Nam
4. Chấp nhận **Developer Distribution Agreement**
5. Thanh toán phí **$25 USD** (một lần duy nhất, thanh toán bằng thẻ tín dụng/ghi nợ)

### 5.3. Xác minh tài khoản

- Google sẽ gửi email xác minh
- Có thể mất 24-48 giờ để xác minh

---

## 6. Tạo app mới trên Play Console

### 6.1. Tạo app

1. Vào **Play Console** → Click **"Create app"**
2. Điền thông tin:
   - **App name**: "TangDo" hoặc "Tặng đồ"
   - **Default language**: Vietnamese (Tiếng Việt)
   - **App or game**: Chọn **App**
   - **Free or paid**: Chọn **Free**
   - **Declarations**: Đánh dấu các checkbox phù hợp
3. Click **"Create app"**

### 6.2. Lưu ý

- **Package name**: Phải khớp với package name trong `build.gradle.kts` (`com.tangdo.tang_do`)
- Không thể thay đổi package name sau khi tạo app

---

## 7. Điền thông tin app

### 7.1. App access

1. Vào **Policy** → **App access**
2. Chọn:
   - **All functionality is available without restrictions** (nếu app không cần đăng nhập bắt buộc)
   - Hoặc **Some functionality is restricted** (nếu cần đăng nhập)

### 7.2. Ads

1. Vào **Policy** → **Ads**
2. Chọn **Yes, my app contains ads**
3. Điền thông tin:
   - **Ad network**: Google AdMob
   - **Ad content rating**: Chọn phù hợp (thường là "General audiences")

### 7.3. Content rating

1. Vào **Policy** → **Content rating**
2. Click **Start questionnaire**
3. Trả lời các câu hỏi về nội dung app
4. Nhận rating (thường là "Everyone" hoặc "Teen")

---

## 8. Upload App Bundle

### 8.1. Vào Production

1. Vào **Production** (menu bên trái)
2. Click **"Create new release"**

### 8.2. Upload AAB

1. Click **"Upload"** trong phần **App bundles**
2. Chọn file `app-release.aab` từ `build/app/outputs/bundle/release/`
3. Đợi upload xong (có thể mất vài phút)

### 8.3. Release name

1. Điền **Release name**: `1.0.0` (hoặc version bạn muốn)
2. **Release notes**: Mô tả những gì mới trong version này (tiếng Việt)

Ví dụ:
```
Phiên bản đầu tiên của TangDo:
- Đăng ký/Đăng nhập
- Đăng sản phẩm muốn tặng
- Tìm kiếm và lọc sản phẩm
- Đánh giá sản phẩm
- Quản lý hồ sơ cá nhân
```

### 8.4. Review release

1. Kiểm tra lại thông tin
2. Click **"Save"** (chưa submit)

---

## 9. Tạo Store Listing

### 9.1. Vào Store presence → Main store listing

### 9.2. App name

- **App name**: "TangDo" (tối đa 50 ký tự)

### 9.3. Short description

Mô tả ngắn (tối đa 80 ký tự):

```
Ứng dụng chia sẻ và tặng đồ cũ miễn phí cho cộng đồng
```

### 9.4. Full description

Mô tả đầy đủ (tối đa 4000 ký tự):

```
TangDo - Ứng dụng chia sẻ và tặng đồ cũ miễn phí

TangDo là nền tảng kết nối cộng đồng, giúp bạn dễ dàng chia sẻ và nhận những món đồ cũ còn sử dụng được. Thay vì vứt bỏ, hãy tặng chúng cho những người thực sự cần!

TÍNH NĂNG CHÍNH:

✨ Đăng sản phẩm miễn phí
- Đăng tải sản phẩm bạn muốn tặng với ảnh và mô tả chi tiết
- Phân loại theo danh mục: Đồ điện tử, Quần áo, Sách, Đồ gia dụng, v.v.

🔍 Tìm kiếm thông minh
- Tìm kiếm sản phẩm theo từ khóa
- Lọc theo địa điểm, danh mục, trạng thái

⭐ Đánh giá và nhận xét
- Đánh giá sản phẩm bằng sao
- Xem nhận xét từ người dùng khác

👤 Quản lý hồ sơ
- Tạo hồ sơ cá nhân với avatar
- Xem lịch sử sản phẩm đã đăng

📞 Liên hệ trực tiếp
- Gọi điện hoặc nhắn tin với người đăng
- Xem địa chỉ chi tiết

🎁 Hoàn toàn miễn phí
- Không có phí ẩn
- Không cần thanh toán

Hãy tham gia cộng đồng TangDo ngay hôm nay để cùng nhau tạo nên một môi trường sống xanh và tiết kiệm hơn!
```

### 9.5. Graphics

Upload các file sau:

**App icon:**
- Kích thước: 512x512px
- Format: PNG (không trong suốt)
- File: `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (resize lên 512x512)

**Feature graphic:**
- Kích thước: 1024x500px
- Format: PNG hoặc JPG
- Banner hiển thị trên Play Store

**Screenshots:**
- Tối thiểu: 2 ảnh
- Tối đa: 8 ảnh
- Kích thước: 16:9 hoặc 9:16
- Độ phân giải: 320px - 3840px
- Format: PNG hoặc JPG

**Gợi ý screenshots:**
1. Màn hình đăng nhập/đăng ký
2. Màn hình trang chủ (danh sách sản phẩm)
3. Màn hình chi tiết sản phẩm
4. Màn hình đăng sản phẩm
5. Màn hình hồ sơ cá nhân

### 9.6. Categorization

- **App category**: Lifestyle hoặc Shopping
- **Tags**: Tùy chọn (ví dụ: "sharing", "free", "community")

### 9.7. Contact details

- **Email**: Email liên hệ của bạn
- **Phone**: Số điện thoại (tùy chọn)
- **Website**: URL website (nếu có)

---

## 10. Cấu hình Content Rating

### 10.1. Vào Content rating

1. Vào **Policy** → **Content rating**
2. Click **Start questionnaire**

### 10.2. Trả lời câu hỏi

Trả lời các câu hỏi về:
- Violence
- Sexual content
- Profanity
- Controlled substances
- Gambling
- Location sharing
- User-generated content
- etc.

### 10.3. Nhận rating

Sau khi hoàn thành, bạn sẽ nhận được rating (thường là "Everyone" hoặc "Teen").

---

## 11. Cấu hình Privacy Policy

### 11.1. Tạo Privacy Policy

Bạn cần tạo một trang Privacy Policy. Có thể:
- Tạo trang web đơn giản (GitHub Pages, Netlify, etc.)
- Hoặc sử dụng dịch vụ tạo Privacy Policy online

### 11.2. Nội dung Privacy Policy

Privacy Policy cần bao gồm:
- Thông tin thu thập (số điện thoại, email, ảnh, v.v.)
- Cách sử dụng thông tin
- Chia sẻ thông tin với bên thứ ba (AdMob, Supabase)
- Bảo mật dữ liệu
- Quyền của người dùng
- Liên hệ

### 11.3. Thêm URL vào app

1. Vào **Policy** → **App content** → **Privacy Policy**
2. Điền URL Privacy Policy
3. Click **Save**

---

## 12. Target Audience

### 12.1. Vào Target audience

1. Vào **Policy** → **Target audience**
2. Chọn:
   - **Age group**: Chọn phù hợp (thường là "All ages" hoặc "13+")
   - **Primary audience**: General
   - **Content guidelines**: Đánh dấu các checkbox phù hợp

---

## 13. Submit để review

### 13.1. Kiểm tra checklist

Trước khi submit, đảm bảo đã hoàn thành:

- [ ] App bundle đã upload
- [ ] Store listing đã điền đầy đủ
- [ ] Screenshots đã upload (tối thiểu 2)
- [ ] Feature graphic đã upload
- [ ] App icon đã upload
- [ ] Privacy Policy URL đã điền
- [ ] Content rating đã hoàn thành
- [ ] Target audience đã cấu hình
- [ ] Ads declaration đã điền (nếu có quảng cáo)

### 13.2. Submit for review

1. Vào **Production**
2. Click **"Review release"**
3. Kiểm tra lại tất cả thông tin
4. Click **"Start rollout to Production"**

### 13.3. Chờ review

- **Thời gian review**: Thường 1-3 ngày làm việc
- Google sẽ gửi email khi có kết quả
- Có thể bị từ chối nếu:
  - Vi phạm chính sách
  - Thiếu thông tin
  - App có lỗi nghiêm trọng

### 13.4. Sau khi được approve

- App sẽ xuất hiện trên Play Store trong vài giờ
- Bạn có thể tìm kiếm app bằng tên hoặc package name

---

## 🔧 Troubleshooting

### Lỗi: "Upload failed"

- Kiểm tra kết nối internet
- Thử upload lại
- Kiểm tra kích thước file (< 150MB)

### Lỗi: "Package name already exists"

- Package name đã được sử dụng
- Cần đổi package name trong `build.gradle.kts` và build lại

### Lỗi: "Missing Privacy Policy"

- Cần thêm URL Privacy Policy
- Privacy Policy phải accessible (không bị chặn)

### Lỗi: "Content rating required"

- Cần hoàn thành Content Rating questionnaire
- Vào **Policy** → **Content rating** → **Start questionnaire**

---

## 📝 Lưu ý quan trọng

1. **Keystore**: Lưu file keystore và mật khẩu cẩn thận. Nếu mất, không thể update app!
2. **Version code**: Mỗi lần update, tăng version code trong `pubspec.yaml` (ví dụ: `1.0.0+1` → `1.0.1+2`)
3. **Testing**: Test kỹ app trước khi submit
4. **Screenshots**: Dùng ảnh thật từ app, không dùng mockup
5. **Privacy Policy**: Bắt buộc phải có nếu app thu thập dữ liệu người dùng

---

## 🎉 Chúc mừng!

Sau khi app được approve và xuất hiện trên Play Store, bạn có thể:
- Share link app với bạn bè
- Quảng bá app
- Theo dõi số lượt tải, đánh giá
- Update app khi có version mới

**Link app sẽ có dạng:**
```
https://play.google.com/store/apps/details?id=com.tangdo.tang_do
```

---

## 📞 Hỗ trợ

Nếu gặp vấn đề, tham khảo:
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Documentation](https://flutter.dev/docs/deployment/android)

---

**Chúc bạn thành công! 🚀**

### 3.3. Cấu hình signingConfigs