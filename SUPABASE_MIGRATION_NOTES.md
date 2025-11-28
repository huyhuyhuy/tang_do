# Supabase Migration Notes

## Đã hoàn thành:

1. ✅ Thêm `supabase_flutter` package vào `pubspec.yaml`
2. ✅ Tạo `lib/config/supabase_config.dart` với credentials
3. ✅ Khởi tạo Supabase trong `main.dart`
4. ✅ Cập nhật User model để sử dụng UUID
5. ✅ Cập nhật Product model để sử dụng UUID
6. ✅ Cập nhật Review model để sử dụng UUID
7. ✅ Cập nhật Notification model để sử dụng UUID
8. ✅ Tạo `SupabaseAuthService`
9. ✅ Tạo `SupabaseProductService`
10. ✅ Tạo `SupabaseReviewService`
11. ✅ Tạo `SupabaseNotificationService`
12. ✅ Cập nhật `AppState` để sử dụng `SupabaseAuthService`
13. ✅ Cập nhật `add_product_screen.dart` để sử dụng `SupabaseProductService`

## Cần cập nhật thêm:

### Screens cần thay đổi ProductService → SupabaseProductService:

1. **lib/screens/edit_product_screen.dart**
   - Thay `ProductService` → `SupabaseProductService`
   - Thay `import '../services/product_service.dart'` → `import '../services/supabase_product_service.dart'`

2. **lib/screens/main_feed_screen.dart**
   - Thay `ProductService` → `SupabaseProductService`
   - Thay `import '../services/product_service.dart'` → `import '../services/supabase_product_service.dart'`
   - Cập nhật `getProductById` để nhận `String` thay vì `int`
   - Cập nhật `getProductAverageRating` để nhận `String` thay vì `int`

3. **lib/screens/profile_screen.dart**
   - Thay `ProductService` → `SupabaseProductService`
   - Thay `import '../services/product_service.dart'` → `import '../services/supabase_product_service.dart'`
   - Cập nhật `getProductsByUserId` để nhận `String` thay vì `int`
   - Cập nhật `deleteProduct` để nhận `String` thay vì `int`
   - Cập nhật `getProductAverageRating` để nhận `String` thay vì `int`

4. **lib/screens/product_detail_screen.dart**
   - Thay `ProductService` → `SupabaseProductService`
   - Thay `import '../services/product_service.dart'` → `import '../services/supabase_product_service.dart'`
   - Cập nhật `getProductById` để nhận `String` thay vì `int`
   - Cập nhật `getProductReviews` → sử dụng `SupabaseReviewService`
   - Cập nhật `getProductAverageRating` → sử dụng `SupabaseReviewService`

5. **lib/screens/add_review_screen.dart**
   - Thay `ProductService` → `SupabaseProductService` và `SupabaseReviewService`
   - Thay `import '../services/product_service.dart'` → `import '../services/supabase_product_service.dart'` và `import '../services/supabase_review_service.dart'`
   - Cập nhật `addReview` → sử dụng `SupabaseReviewService`
   - Cập nhật `getProductById` để nhận `String` thay vì `int`

### Services cần cập nhật:

1. **lib/services/notification_service.dart**
   - Thay `NotificationService` → `SupabaseNotificationService`
   - Cập nhật tất cả methods để sử dụng UUID

### Models cần kiểm tra:

- Tất cả models đã được cập nhật để hỗ trợ cả UUID (Supabase) và int (SQLite) để tương thích ngược

## Lưu ý quan trọng:

1. **Authentication**: Supabase Auth yêu cầu email format. Hiện tại đang dùng `$phone@tangdo.local` làm workaround. Có thể cần điều chỉnh sau.

2. **Image Storage**: Hiện tại images vẫn lưu local path. Cần migrate sang Supabase Storage sau.

3. **User ID**: Tất cả `user.id` giờ là `String` (UUID) thay vì `int`. Cần cập nhật tất cả nơi sử dụng.

4. **Product ID**: Tất cả `product.id` giờ là `String` (UUID) thay vì `int`. Cần cập nhật tất cả nơi sử dụng.

5. **Chạy `flutter pub get`** để cài đặt `supabase_flutter` package.

