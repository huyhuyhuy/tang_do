# Hướng dẫn đáp ứng Guideline 1.5 (Support URL) và 1.2 (User-Generated Content)

## 1. Guideline 1.5 – Support URL

**Vấn đề:** URL hỗ trợ `https://sites.google.com/view/tangdo/home` không dẫn đến trang có thông tin để người dùng hỏi đáp và yêu cầu hỗ trợ.

**Cách xử lý:** Cập nhật trang Google Site để có đủ nội dung hỗ trợ.

### Nội dung tối thiểu cần có trên trang Support

Trên **https://sites.google.com/view/tangdo/home** (hoặc đường dẫn bạn dùng làm Support URL) cần có:

1. **Tiêu đề rõ ràng**  
   Ví dụ: "Hỗ trợ Tặng đồ" hoặc "Liên hệ & Hỗ trợ".

2. **Cách liên hệ hỗ trợ**
   - Email hỗ trợ (bắt buộc), ví dụ:  
     `support@tangdo.com` hoặc `hotro.tangdo@gmail.com`
   - Ghi rõ: "Gửi email về địa chỉ trên để được hỗ trợ."

3. **Câu hỏi thường gặp (FAQ)**  
   Ít nhất 3–5 câu, ví dụ:
   - Làm sao để đăng ký / đăng nhập?
   - Làm sao để đăng tin tặng đồ?
   - Làm sao báo cáo nội dung vi phạm hoặc người dùng lạm dụng?
   - Làm sao chặn người dùng?
   - Làm sao xóa tài khoản?

4. **Thời gian phản hồi**  
   Ví dụ: "Chúng tôi cố gắng phản hồi trong vòng 24–48 giờ."

**Ví dụ bố cục trang (text):**

```
HỖ TRỢ ỨNG DỤNG TẶNG ĐỒ

Liên hệ hỗ trợ
Gửi email tới: [email của bạn]
Chúng tôi phản hồi trong vòng 24–48 giờ.

Câu hỏi thường gặp
• Đăng ký: Mở app → Đăng ký → Nhập SĐT, nickname, mật khẩu.
• Báo cáo nội dung: Vào sản phẩm/ hồ sơ người dùng → Menu ⋮ → Báo cáo.
• Chặn người dùng: Menu ⋮ trên sản phẩm/hồ sơ → Chặn [tên].
• Xóa tài khoản: Hồ sơ → Menu ⋮ → Xóa tài khoản.
```

Sau khi chỉnh xong, **kiểm tra lại Support URL trong App Store Connect** đang trỏ đúng tới trang này.

---

## 2. Guideline 1.2 – User-Generated Content (Đã triển khai trong app)

Các phần sau đã được thêm/sửa trong code và database.

### 2.1. EULA / Điều khoản (Terms)

- **Màn hình đăng ký:** Bắt buộc tick “Tôi đồng ý với Điều khoản sử dụng và Quy định cộng đồng”.
- **Nội dung cần có trên trang Điều khoản** (dùng cho link trong app, ví dụ `https://sites.google.com/view/tangdo/terms`):
  - Ứng dụng **không dung thứ** nội dung phản cảm hoặc người dùng có hành vi lạm dụng.
  - Vi phạm có thể dẫn đến xóa nội dung và khóa tài khoản.
  - Qui định nội dung cấm (spam, xúc phạm, lừa đảo, quấy rối, v.v.).

### 2.2. Lọc nội dung (Content filtering)

- Khi đăng sản phẩm: kiểm tra **tên** và **mô tả** với danh sách từ cấm trong `lib/utils/constants.dart` (bannedWords).
- Nếu có từ cấm → không cho đăng và hiện thông báo từ `getBannedContentMessage()`.
- Có thể bổ sung từ vào `AppConstants.bannedWords` trong `lib/utils/constants.dart`.

### 2.3. Báo cáo nội dung (Flag content)

- **Trên sản phẩm:** Chi tiết sản phẩm → Menu ⋮ → “Báo cáo sản phẩm” → chọn lý do → Gửi.
- **Trên hồ sơ người khác:** Hồ sơ → Menu ⋮ → “Báo cáo người dùng” → chọn lý do → Gửi.
- Báo cáo lưu vào bảng `content_reports` (reporter, loại nội dung, người bị báo cáo, lý do, trạng thái).

### 2.4. Chặn người dùng (Block abusive users)

- **Trên sản phẩm:** Chi tiết sản phẩm → Menu ⋮ → “Chặn [nickname]” → Xác nhận.
- **Trên hồ sơ:** Hồ sơ người khác → Menu ⋮ → “Chặn [nickname]” → Xác nhận.
- Sau khi chặn:
  - Sản phẩm của người bị chặn **không còn hiển thị** trên bảng tin của bạn (lọc ngay theo danh sách blocked).
  - Thông tin “đã chặn” lưu trong bảng `blocked_users` để lọc feed và có thể dùng cho xử lý nội dung vi phạm.

### 2.5. Trách nhiệm xử lý trong 24 giờ

- Apple yêu cầu developer **xử lý báo cáo trong vòng 24 giờ** (gỡ nội dung, xử lý tài khoản vi phạm).
- Trong app đã có:
  - Gửi báo cáo lên backend (`content_reports`).
  - Thông báo: “Chúng tôi sẽ xem xét trong vòng 24 giờ.”
- Bạn cần:
  - Có quy trình (hoặc dashboard) để xem danh sách báo cáo trong Supabase (`content_reports`).
  - Trong 24h: xóa/chặn nội dung vi phạm và xử lý tài khoản (cảnh cáo / khóa) theo nội quy đã công bố.

---

## 3. Chạy migration Supabase

Để báo cáo và chặn hoạt động đúng, cần tạo bảng trên Supabase:

1. Vào **Supabase Dashboard** → project của app → **SQL Editor**.
2. Chạy nội dung file:  
   `supabase_migration_content_safety.sql`

Nội dung chính:

- Bảng `content_reports`: lưu báo cáo (reporter, content_type, content_id, reported_user_id, reason, status, …).
- Bảng `blocked_users`: lưu quan hệ chặn (blocker_id, blocked_id).

Sau khi chạy xong, kiểm tra trong **Table Editor** có hai bảng `content_reports` và `blocked_users`.

---

## 4. URL dùng trong app

Trong `lib/utils/constants.dart` đã khai báo:

- `supportUrl`: dùng cho “Hỗ trợ” (có thể trùng với Support URL trên App Store).
- `termsUrl`: dùng cho “Điều khoản & Quy định cộng đồng” (link khi đăng ký).

Cập nhật cho đúng với trang bạn đã chỉnh:

```dart
static const String supportUrl = 'https://sites.google.com/view/tangdo/home';
static const String termsUrl = 'https://sites.google.com/view/tangdo/terms';
```

Nếu bạn dùng một tên trang khác trên Google Site (ví dụ “dieu-khoan”), hãy đổi `termsUrl` cho khớp.

---

## 5. Checklist trước khi gửi lại App Review

- [ ] Trang Support URL có: tiêu đề, email hỗ trợ, FAQ, thời gian phản hồi.
- [ ] Trang Điều khoản/Quy định có: không dung thứ nội dung phản cảm và lạm dụng, quy định xử lý vi phạm.
- [ ] Trong App Store Connect, Support URL trỏ đúng trang hỗ trợ đã cập nhật.
- [ ] Đã chạy `supabase_migration_content_safety.sql` trên Supabase.
- [ ] Đã test: đăng ký có đồng ý điều khoản, báo cáo sản phẩm/người dùng, chặn người dùng, feed không còn hiện sản phẩm của người bị chặn.
- [ ] Đã có quy trình (hoặc cách) xem báo cáo và xử lý trong 24 giờ.

Sau khi làm đủ các bước trên và build lại bản 1.0.6 (hoặc version bạn dùng), bạn có thể resubmit và ghi rõ trong “Notes for reviewer” những gì đã thay đổi (Support URL, EULA, báo cáo, chặn, lọc nội dung, xử lý 24h).
