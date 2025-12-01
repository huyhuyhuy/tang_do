com.tangdo.tang_do

<!-- quảng cáo cho android -->

ID ứng dụng: ca-app-pub-4969810842586372~8341729290
ID Biểu ngữ: ca-app-pub-4969810842586372/3224423548
ID quảng cáo khi mở app: ca-app-pub-4969810842586372/7842325400

<!-- quảng cáo cho ios -->
ID ứng dụng: ca-app-pub-4969810842586372~3872835394
ID quảng cáo biểu ngữ: ca-app-pub-4969810842586372/7346118490
ID quảng cáo khi mở app: ca-app-pub-4969810842586372/5026134966


<!-- supabase -->
project url: https://sdbasjrsnwfibwocjdfl.supabase.co

anon public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkYmFzanJzbndmaWJ3b2NqZGZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMjA4NDMsImV4cCI6MjA3OTg5Njg0M30.luQ9vJWdl-UM9mrKuzMtVNS2l1_eQU4NSPtcYS0WoVQ

service role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNkYmFzanJzbndmaWJ3b2NqZGZsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2NDMyMDg0MywiZXhwIjoyMDc5ODk2ODQzfQ.AwYX5xNLvrxyaz3nlwIMTbUpwmZMsMyBH7snCuVlyPM

# App TangDo

Ứng dụng mobile đa nền tảng (iOS và Android) được xây dựng bằng Flutter, cho phép người dùng chia sẻ và tặng đồ cũ cho nhau.

## Tính năng chính

### Authentication
- Đăng ký/Đăng nhập bằng số điện thoại hoặc nickname
- Quản lý profile cá nhân:
  - Tên, số điện thoại, email, địa chỉ
  - Avatar (upload từ thiết bị)
  - Tỉnh/Thành phố, Quận/Huyện

### Quản lý sản phẩm
- Đăng mới/Sửa/Xóa sản phẩm muốn tặng
- Mỗi sản phẩm có:
  - Tên sản phẩm, mô tả
  - Danh mục: Đồ điện tử, Thực phẩm, Mỹ phẩm, Quần áo, Sách, Thú cưng, Đồ chơi, Văn phòng phẩm, Đồ gia dụng, Khác
  - Trạng thái: Chưa sử dụng / Đã qua sử dụng
  - Tối đa 3 ảnh (upload từ thiết bị)
  - Địa chỉ (mặc định từ profile hoặc tùy chỉnh)
  - Thời gian hết hạn (tự động xóa sau X ngày)

### Bảng tin chính
- Hiển thị sản phẩm dạng grid (giống Shopee)
- Mỗi item hiển thị:
  - Ảnh chính của sản phẩm
  - Nickname người đăng
  - Điểm đánh giá (sao) overlay trên ảnh
  - Địa chỉ ngắn gọn (Quận/Huyện, Tỉnh/Thành phố)
- Tìm kiếm theo từ khóa
- Lọc theo:
  - Địa chỉ (Tỉnh/Thành phố)
  - Danh mục
  - Số sao đánh giá (tối thiểu)

### Đánh giá và Comment
- Đánh giá sản phẩm (1-5 sao)
- Comment bằng văn bản
- Hiển thị điểm trung bình đánh giá trên card sản phẩm
- Mỗi user chỉ đánh giá 1 lần cho mỗi sản phẩm

### Thông báo (Notifications)
- Thông báo khi có đánh giá mới cho sản phẩm của bạn
- Thông báo khi nhận GoldChip từ người khác
- Badge hiển thị số thông báo chưa đọc trên icon chuông
- Đánh dấu đã đọc, xóa thông báo

### GoldChip Wallet
- Ví GoldChip cho mỗi user
- Chuyển GoldChip cho nhau (tặng GoldChip)
- Nhận 100 GoldChip khi giới thiệu bạn bè (referral)
- Lịch sử hoạt động (giao dịch GoldChip)
- Tính năng rút tiền (Coming Soon)

### Liên hệ
- Gọi điện trực tiếp từ số điện thoại trong profile
- Copy địa chỉ vào clipboard

### Quảng cáo (Ads)
- Banner quảng cáo hiển thị ở dưới cùng tất cả các màn hình
- Tích hợp Google AdMob (Google Mobile Ads)
- Sử dụng test ad unit ID cho development
- FloatingActionButton được điều chỉnh để tránh banner

## Cấu trúc dự án

```
lib/
├── database/          # SQLite database helper
│   └── database_helper.dart
├── models/            # Data models
│   ├── user.dart
│   ├── product.dart
│   ├── review.dart
│   ├── notification.dart
│   ├── goldchip_transaction.dart
│   └── follow.dart
├── screens/           # UI screens
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── main_feed_screen.dart
│   ├── product_detail_screen.dart
│   ├── profile_screen.dart
│   ├── edit_profile_screen.dart
│   ├── add_product_screen.dart
│   ├── edit_product_screen.dart
│   ├── add_review_screen.dart
│   ├── goldchip_screen.dart
│   └── notifications_screen.dart
├── services/          # Business logic services
│   ├── auth_service.dart
│   ├── product_service.dart
│   ├── notification_service.dart
│   ├── goldchip_service.dart
│   ├── follow_service.dart
│   └── seed_service.dart
├── providers/         # State management (Provider)
│   └── app_state.dart
├── utils/             # Constants và utilities
│   ├── constants.dart
│   └── contact_utils.dart
├── widgets/           # Reusable widgets
│   └── banner_ad_widget.dart
└── main.dart          # Entry point
```

## Database Schema

### Users
- `id`: Primary key
- `phone`: Số điện thoại (unique)
- `nickname`: Nickname (unique)
- `password`: Mật khẩu (hashed)
- `name`: Họ tên
- `email`: Email
- `address`: Địa chỉ chi tiết
- `province`: Tỉnh/Thành phố
- `district`: Quận/Huyện
- `avatar`: Đường dẫn ảnh avatar
- `gold_chip`: Số GoldChip hiện có
- `created_at`, `updated_at`: Timestamps

### Products
- `id`: Primary key
- `user_id`: Foreign key đến users
- `name`: Tên sản phẩm
- `description`: Mô tả
- `category`: Danh mục
- `condition`: Trạng thái (new/used)
- `address`, `province`, `district`: Địa chỉ
- `image1`, `image2`, `image3`: Đường dẫn ảnh (tối đa 3 ảnh)
- `expiry_days`: Số ngày hết hạn
- `created_at`, `expires_at`: Timestamps
- `is_active`: Trạng thái hoạt động

### Reviews
- `id`: Primary key
- `product_id`: Foreign key đến products
- `user_id`: Foreign key đến users
- `rating`: Điểm đánh giá (1-5 sao)
- `comment`: Nhận xét
- `created_at`: Timestamp
- Unique constraint: (product_id, user_id) - mỗi user chỉ đánh giá 1 lần

### Notifications
- `id`: Primary key
- `user_id`: Foreign key đến users
- `type`: Loại thông báo (review, goldchip_received)
- `title`: Tiêu đề
- `message`: Nội dung
- `related_id`: ID liên quan (product_id, transaction_id)
- `is_read`: Trạng thái đã đọc
- `created_at`: Timestamp

### GoldChip Transactions
- `id`: Primary key
- `from_user_id`: Người gửi (nullable cho referral)
- `to_user_id`: Người nhận
- `amount`: Số lượng GoldChip
- `type`: Loại giao dịch (transfer, referral, received)
- `description`: Mô tả
- `created_at`: Timestamp

### Follows
- `id`: Primary key
- `follower_id`: Người theo dõi
- `following_id`: Người được theo dõi
- `created_at`: Timestamp
- Unique constraint: (follower_id, following_id)

### Referrals
- `id`: Primary key
- `referrer_id`: Người giới thiệu
- `referred_phone`: Số điện thoại người được giới thiệu
- `is_completed`: Trạng thái hoàn thành
- `created_at`, `completed_at`: Timestamps

## Cài đặt và chạy

1. Cài đặt Flutter dependencies:
```bash
flutter pub get
```

2. Cấu hình AdMob (đã được cấu hình sẵn với test App ID):
   - Android: AdMob App ID đã được thêm vào `android/app/src/main/AndroidManifest.xml`
   - Test App ID: `ca-app-pub-3940256099942544~3347511713`
   - Test Banner Ad Unit ID: `ca-app-pub-3940256099942544/6300978111`
   - **Lưu ý**: Khi publish app, cần thay thế bằng App ID và Ad Unit ID thật từ AdMob Console

3. Chạy app:
```bash
flutter run
```

4. Build app:
```bash
# Android
flutter build apk

# iOS
flutter build ios
```

## Demo Data

App tự động seed demo data khi khởi chạy lần đầu:
- 3 users mẫu với avatar
- 10 sản phẩm mẫu với ảnh từ Unsplash
- Dữ liệu được tạo trong `lib/services/seed_service.dart`

## Tech Stack

- **Framework**: Flutter 3.9.0+
- **Database**: SQLite (local) - sqflite 2.3.0
- **State Management**: Provider 6.1.1
- **UI**: Material Design 3
- **Image Handling**: 
  - image_picker 1.0.7 (upload ảnh từ thiết bị)
  - cached_network_image 3.3.0 (hiển thị ảnh từ URL)
- **Utilities**:
  - url_launcher 6.2.2 (gọi điện, mở Zalo)
  - path_provider 2.1.1 (lưu ảnh local)
  - intl 0.19.0 (format ngày tháng)
  - shared_preferences 2.2.2 (lưu preferences)
- **Ads**:
  - google_mobile_ads 5.0.0 (Google AdMob integration)

## Tính năng đã hoàn thành

✅ Đăng ký/Đăng nhập  
✅ Quản lý profile với avatar  
✅ Đăng/Sửa/Xóa sản phẩm với upload ảnh  
✅ Tìm kiếm và lọc sản phẩm  
✅ Đánh giá và comment sản phẩm  
✅ Hiển thị điểm đánh giá trên card  
✅ GoldChip wallet và chuyển GoldChip  
✅ Hệ thống thông báo  
✅ Liên hệ (gọi điện, copy địa chỉ)  
✅ Seed demo data  
✅ Banner quảng cáo (Google AdMob) tích hợp vào tất cả màn hình  

## Tương lai

- Tích hợp Supabase cho backend
- Push notifications
- Real-time updates
- Tính năng rút GoldChip
- Cải thiện hiệu năng và UX

## License

Private project
