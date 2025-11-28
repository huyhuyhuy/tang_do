# Kế hoạch Database Supabase cho App TangDo

## Tổng quan

Tài liệu này mô tả chi tiết kế hoạch chuyển đổi database từ SQLite local sang Supabase (PostgreSQL) để đảm bảo đồng bộ, chính xác, chuẩn hóa và phục vụ đầy đủ toàn bộ chức năng hiện tại của app.

## Kiến trúc Database

### 1. Authentication
- Sử dụng **Supabase Auth** thay vì tự quản lý password
- Tích hợp với `auth.users` table của Supabase
- Custom user metadata lưu trong `public.users` table

### 2. Storage
- **Bucket `avatars`**: Lưu trữ avatar của users
- **Bucket `product-images`**: Lưu trữ ảnh sản phẩm (tối đa 3 ảnh/sản phẩm)

## Schema Design

### Table: `users`

Lưu trữ thông tin người dùng, liên kết với Supabase Auth.

```sql
CREATE TABLE public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  phone TEXT UNIQUE NOT NULL,
  nickname TEXT UNIQUE NOT NULL,
  name TEXT,
  email TEXT, -- Tùy chọn khi đăng ký
  address TEXT,
  province TEXT,
  district TEXT,
  avatar_url TEXT, -- URL từ storage bucket 'avatars'
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Constraints
  CONSTRAINT users_phone_format CHECK (phone ~ '^[0-9]{10,11}$'),
  CONSTRAINT users_nickname_length CHECK (char_length(nickname) >= 3),
  CONSTRAINT users_email_format CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- Indexes
CREATE INDEX idx_users_auth_user_id ON public.users(auth_user_id);
CREATE INDEX idx_users_phone ON public.users(phone);
CREATE INDEX idx_users_nickname ON public.users(nickname);
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_province ON public.users(province);
CREATE INDEX idx_users_district ON public.users(district);

-- Trigger để tự động cập nhật updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

**Lưu ý quan trọng:**
- `phone` và `nickname` là UNIQUE và NOT NULL - không thể thay đổi sau khi đăng ký
- `email` là tùy chọn - có thể để trống khi đăng ký
- `auth_user_id` liên kết với Supabase Auth

---

### Table: `products`

Lưu trữ thông tin sản phẩm muốn tặng.

```sql
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL CHECK (char_length(name) >= 1),
  description TEXT,
  category TEXT NOT NULL CHECK (category IN (
    'Đồ điện tử', 'Thực phẩm', 'Mỹ phẩm', 'Quần áo', 'Sách', 
    'Thú cưng', 'Đồ chơi', 'Văn phòng phẩm', 'Đồ gia dụng', 'Khác'
  )),
  condition TEXT NOT NULL CHECK (condition IN ('new', 'used')),
  address TEXT,
  province TEXT,
  district TEXT,
  ward TEXT, -- Phường/Xã
  contact_phone TEXT, -- Số điện thoại liên hệ cho sản phẩm
  image1_url TEXT, -- URL từ storage bucket 'product-images'
  image2_url TEXT,
  image3_url TEXT,
  expiry_days INTEGER NOT NULL CHECK (expiry_days > 0),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL,
  
  -- Constraints
  CONSTRAINT products_expires_at_future CHECK (expires_at > created_at)
);

-- Indexes
CREATE INDEX idx_products_user_id ON public.products(user_id);
CREATE INDEX idx_products_category ON public.products(category);
CREATE INDEX idx_products_province ON public.products(province);
CREATE INDEX idx_products_district ON public.products(district);
CREATE INDEX idx_products_expires_at ON public.products(expires_at);
CREATE INDEX idx_products_is_active ON public.products(is_active);
CREATE INDEX idx_products_created_at ON public.products(created_at DESC);

-- Composite index cho query phổ biến
CREATE INDEX idx_products_active_expires ON public.products(is_active, expires_at) 
  WHERE is_active = TRUE;

-- Full-text search index cho tìm kiếm
CREATE INDEX idx_products_search ON public.products 
  USING gin(to_tsvector('vietnamese', coalesce(name, '') || ' ' || coalesce(description, '')));

-- Trigger để tự động tính expires_at
CREATE OR REPLACE FUNCTION set_product_expires_at()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.expires_at IS NULL THEN
    NEW.expires_at = NEW.created_at + (NEW.expiry_days || ' days')::INTERVAL;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_products_expires_at
  BEFORE INSERT ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION set_product_expires_at();
```

**Lưu ý:**
- Chỉ có 3 ảnh: `image1_url`, `image2_url`, `image3_url` (không có image4)
- `contact_phone`: Số điện thoại liên hệ cho sản phẩm (có thể khác với số điện thoại của user)
- Thời gian hết hạn mặc định: 30 ngày
- Tự động tính `expires_at` từ `expiry_days`
- Full-text search hỗ trợ tiếng Việt

---

### Table: `reviews`

Lưu trữ đánh giá và comment cho sản phẩm.

```sql
CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Mỗi user chỉ đánh giá 1 lần cho mỗi sản phẩm
  CONSTRAINT reviews_unique_user_product UNIQUE (product_id, user_id)
);

-- Indexes
CREATE INDEX idx_reviews_product_id ON public.reviews(product_id);
CREATE INDEX idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX idx_reviews_created_at ON public.reviews(created_at DESC);

-- Function để tính điểm trung bình đánh giá
CREATE OR REPLACE FUNCTION get_product_average_rating(product_uuid UUID)
RETURNS NUMERIC AS $$
DECLARE
  avg_rating NUMERIC;
BEGIN
  SELECT COALESCE(AVG(rating), 0) INTO avg_rating
  FROM public.reviews
  WHERE product_id = product_uuid;
  RETURN ROUND(avg_rating, 1);
END;
$$ LANGUAGE plpgsql;
```

**Lưu ý:**
- Unique constraint đảm bảo mỗi user chỉ đánh giá 1 lần
- Function helper để tính điểm trung bình

---

### Table: `notifications`

Lưu trữ thông báo cho users.

```sql
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('review')),
  title TEXT NOT NULL CHECK (char_length(title) >= 1),
  message TEXT,
  related_id UUID, -- product_id hoặc transaction_id tùy type
  is_read BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id, is_read) 
  WHERE is_read = FALSE;

-- Function để đếm số thông báo chưa đọc
CREATE OR REPLACE FUNCTION get_unread_notification_count(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
  unread_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO unread_count
  FROM public.notifications
  WHERE user_id = user_uuid AND is_read = FALSE;
  RETURN unread_count;
END;
$$ LANGUAGE plpgsql;
```

---

### Table: `follows`

Lưu trữ quan hệ follow giữa users (hiện tại không dùng trong UI nhưng giữ lại cho tương lai).

```sql
CREATE TABLE public.follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  
  -- Không thể follow chính mình
  CONSTRAINT follows_no_self_follow CHECK (follower_id != following_id),
  -- Mỗi cặp chỉ follow 1 lần
  CONSTRAINT follows_unique_pair UNIQUE (follower_id, following_id)
);

-- Indexes
CREATE INDEX idx_follows_follower ON public.follows(follower_id);
CREATE INDEX idx_follows_following ON public.follows(following_id);
CREATE INDEX idx_follows_created_at ON public.follows(created_at DESC);
```

---

## Row Level Security (RLS) Policies

### Users Table

```sql
-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users có thể xem tất cả profiles
CREATE POLICY "Users can view all profiles"
  ON public.users FOR SELECT
  USING (true);

-- Users chỉ có thể update profile của chính mình
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = auth_user_id)
  WITH CHECK (auth.uid() = auth_user_id);

-- Không cho phép update phone và nickname
CREATE POLICY "Prevent phone and nickname update"
  ON public.users FOR UPDATE
  USING (true)
  WITH CHECK (
    phone = (SELECT phone FROM public.users WHERE auth_user_id = auth.uid()) AND
    nickname = (SELECT nickname FROM public.users WHERE auth_user_id = auth.uid())
  );
```

### Products Table

```sql
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Tất cả users có thể xem products active
CREATE POLICY "Anyone can view active products"
  ON public.products FOR SELECT
  USING (is_active = TRUE AND expires_at > NOW());

-- Users chỉ có thể tạo products cho chính mình
CREATE POLICY "Users can create own products"
  ON public.products FOR INSERT
  WITH CHECK (
    auth.uid() IN (SELECT auth_user_id FROM public.users WHERE id = user_id)
  );

-- Users chỉ có thể update products của chính mình
CREATE POLICY "Users can update own products"
  ON public.products FOR UPDATE
  USING (
    auth.uid() IN (SELECT auth_user_id FROM public.users WHERE id = user_id)
  );

-- Users chỉ có thể delete products của chính mình
CREATE POLICY "Users can delete own products"
  ON public.products FOR DELETE
  USING (
    auth.uid() IN (SELECT auth_user_id FROM public.users WHERE id = user_id)
  );
```

### Reviews Table

```sql
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

-- Tất cả users có thể xem reviews
CREATE POLICY "Anyone can view reviews"
  ON public.reviews FOR SELECT
  USING (true);

-- Users có thể tạo reviews
CREATE POLICY "Users can create reviews"
  ON public.reviews FOR INSERT
  WITH CHECK (
    auth.uid() IN (SELECT auth_user_id FROM public.users WHERE id = user_id)
  );

-- Users chỉ có thể update/delete reviews của chính mình
CREATE POLICY "Users can update own reviews"
  ON public.reviews FOR UPDATE
  USING (
    auth.uid() IN (SELECT auth_user_id FROM public.users WHERE id = user_id)
  );

CREATE POLICY "Users can delete own reviews"
  ON public.reviews FOR DELETE
  USING (
    auth.uid() IN (SELECT auth_user_id FROM public.users WHERE id = user_id)
  );
```

### Notifications Table

```sql
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users chỉ có thể xem notifications của chính mình
CREATE POLICY "Users can view own notifications"
  ON public.notifications FOR SELECT
  USING (
    auth.uid() IN (SELECT auth_user_id FROM public.users WHERE id = user_id)
  );

-- Chỉ hệ thống có thể tạo notifications (qua service role hoặc function)
CREATE POLICY "System can create notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (true); -- Sẽ được kiểm tra trong application logic

-- Users chỉ có thể update notifications của chính mình
CREATE POLICY "Users can update own notifications"
  ON public.notifications FOR UPDATE
  USING (
    auth.uid() IN (SELECT auth_user_id FROM public.users WHERE id = user_id)
  );
```

---

## Storage Buckets

### Bucket: `avatars`

```sql
-- Tạo bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true);

-- Policy: Users có thể upload avatar của chính mình
CREATE POLICY "Users can upload own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy: Public read
CREATE POLICY "Anyone can view avatars"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Policy: Users có thể update/delete avatar của chính mình
CREATE POLICY "Users can update own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

### Bucket: `product-images`

```sql
-- Tạo bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('product-images', 'product-images', true);

-- Policy: Users có thể upload ảnh sản phẩm
CREATE POLICY "Users can upload product images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Policy: Public read
CREATE POLICY "Anyone can view product images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

-- Policy: Users có thể delete ảnh sản phẩm của chính mình
CREATE POLICY "Users can delete own product images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'product-images' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );
```

---

## Database Functions

### Function: Create Notification

```sql
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_message TEXT DEFAULT NULL,
  p_related_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
BEGIN
  INSERT INTO public.notifications (user_id, type, title, message, related_id)
  VALUES (p_user_id, p_type, p_title, p_message, p_related_id)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Triggers

### Trigger: Auto-create notification when review created

```sql
CREATE OR REPLACE FUNCTION notify_product_owner_on_review()
RETURNS TRIGGER AS $$
DECLARE
  v_product_owner_id UUID;
  v_reviewer_nickname TEXT;
  v_product_name TEXT;
BEGIN
  -- Get product owner
  SELECT user_id INTO v_product_owner_id
  FROM public.products
  WHERE id = NEW.product_id;

  -- Get reviewer nickname
  SELECT nickname INTO v_reviewer_nickname
  FROM public.users
  WHERE id = NEW.user_id;

  -- Get product name
  SELECT name INTO v_product_name
  FROM public.products
  WHERE id = NEW.product_id;

  -- Create notification
  PERFORM create_notification(
    v_product_owner_id,
    'review',
    'Có đánh giá mới',
    v_reviewer_nickname || ' đã đánh giá sản phẩm "' || v_product_name || '" của bạn',
    NEW.product_id
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_notify_on_review
  AFTER INSERT ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION notify_product_owner_on_review();
```

---

## Migration Plan

### Phase 1: Setup Supabase Project
1. Tạo Supabase project
2. Enable Authentication
3. Tạo Storage buckets (`avatars`, `product-images`)
4. Setup RLS policies cho storage

### Phase 2: Create Database Schema
1. Tạo tất cả tables với đầy đủ constraints
2. Tạo indexes
3. Tạo functions
4. Tạo triggers
5. Setup RLS policies

### Phase 3: Data Migration (nếu có)
1. Export data từ SQLite
2. Transform data (chuyển INTEGER id sang UUID)
3. Import vào Supabase
4. Map auth users với existing users

### Phase 4: Update Flutter App
1. Cài đặt `supabase_flutter` package
2. Tạo Supabase client service
3. Update các services để sử dụng Supabase thay vì SQLite
4. Update models để sử dụng UUID
5. Update authentication flow để sử dụng Supabase Auth
6. Update image upload để sử dụng Supabase Storage
7. **Giữ nguyên ads integration**: Google Mobile Ads sẽ tiếp tục hoạt động độc lập, không cần thay đổi

### Phase 5: Testing
1. Test authentication flow
2. Test CRUD operations
3. Test RLS policies
4. Test storage uploads
5. Test functions và triggers
6. Performance testing

---

## Notes

### Quan trọng:
1. **Email tùy chọn**: Email có thể để trống khi đăng ký
2. **Phone và Nickname không thể thay đổi**: Enforced bằng RLS policy và application logic
3. **Chỉ 3 ảnh sản phẩm**: image1_url, image2_url, image3_url (không có image4)
4. **Contact Phone**: Mỗi sản phẩm có số điện thoại liên hệ riêng (có thể khác với số điện thoại của user)
5. **Thời gian hết hạn mặc định**: 30 ngày
6. **UUID thay vì INTEGER**: Tất cả id sử dụng UUID để tránh conflicts
7. **Timestamps với timezone**: Sử dụng TIMESTAMPTZ thay vì INTEGER milliseconds
8. **Full-text search**: Hỗ trợ tìm kiếm tiếng Việt
9. **RLS Security**: Tất cả tables đều có RLS enabled
10. **Ads Integration**: App hiện tại đã tích hợp Google AdMob với banner ads. Khi migrate sang Supabase, ads integration sẽ không bị ảnh hưởng vì nó hoạt động độc lập với database backend.
11. **Đã xóa GoldChip**: Toàn bộ chức năng GoldChip, ví, chuyển GoldChip, và referral bonus đã được xóa khỏi app

### Performance:
- Indexes được tối ưu cho các query phổ biến
- Composite indexes cho queries phức tạp
- Partial indexes cho filtered queries

### Scalability:
- UUID cho distributed systems
- Storage buckets cho file management
- Functions cho business logic server-side
- Triggers cho automation

---

## SQL Scripts

Tất cả SQL scripts được tổ chức trong thư mục `supabase/migrations/`:

1. `001_initial_schema.sql` - Tạo tất cả tables và indexes (không bao gồm goldchip_transactions và referrals)
2. `002_functions.sql` - Tạo các functions (chỉ create_notification, không có transfer_goldchip và add_referral_bonus)
3. `003_triggers.sql` - Tạo các triggers
4. `004_rls_policies.sql` - Setup RLS policies (không bao gồm goldchip_transactions)
5. `005_storage_policies.sql` - Setup storage policies

---

## Next Steps

1. Review và approve schema design
2. Setup Supabase project
3. Run migration scripts
4. Test database với sample data
5. Update Flutter app code
6. Deploy và monitor

