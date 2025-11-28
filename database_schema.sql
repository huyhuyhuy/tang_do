-- ============================================
-- Database Schema for TangDo App (Supabase)
-- Simple version for testing (no RLS)
-- ============================================

-- ============================================
-- 1. USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone TEXT UNIQUE NOT NULL,
  nickname TEXT UNIQUE NOT NULL,
  password TEXT NOT NULL,
  name TEXT,
  email TEXT,
  address TEXT,
  province TEXT,
  district TEXT,
  ward TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for users
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_nickname ON public.users(nickname);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_province ON public.users(province);
CREATE INDEX IF NOT EXISTS idx_users_district ON public.users(district);
CREATE INDEX IF NOT EXISTS idx_users_ward ON public.users(ward);

-- Trigger to auto-update updated_at
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

-- ============================================
-- 2. PRODUCTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL CHECK (category IN (
    'Đồ điện tử', 'Thực phẩm', 'Mỹ phẩm', 'Quần áo', 'Sách', 
    'Thú cưng', 'Đồ chơi', 'Văn phòng phẩm', 'Đồ gia dụng', 'Khác'
  )),
  condition TEXT NOT NULL CHECK (condition IN ('new', 'used')),
  address TEXT,
  province TEXT,
  district TEXT,
  ward TEXT,
  contact_phone TEXT,
  image1_url TEXT,
  image2_url TEXT,
  image3_url TEXT,
  expiry_days INTEGER NOT NULL CHECK (expiry_days > 0),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN DEFAULT TRUE NOT NULL
);

-- Indexes for products
CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_province ON public.products(province);
CREATE INDEX IF NOT EXISTS idx_products_district ON public.products(district);
CREATE INDEX IF NOT EXISTS idx_products_expires_at ON public.products(expires_at);
CREATE INDEX IF NOT EXISTS idx_products_is_active ON public.products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON public.products(created_at DESC);

-- Composite index for active products
CREATE INDEX IF NOT EXISTS idx_products_active_expires ON public.products(is_active, expires_at) 
  WHERE is_active = TRUE;

-- Full-text search index (using 'simple' configuration for compatibility)
CREATE INDEX IF NOT EXISTS idx_products_search ON public.products 
  USING gin(to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(description, '')));

-- Trigger to auto-calculate expires_at
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

-- ============================================
-- 3. REVIEWS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT reviews_unique_user_product UNIQUE (product_id, user_id)
);

-- Indexes for reviews
CREATE INDEX IF NOT EXISTS idx_reviews_product_id ON public.reviews(product_id);
CREATE INDEX IF NOT EXISTS idx_reviews_user_id ON public.reviews(user_id);
CREATE INDEX IF NOT EXISTS idx_reviews_created_at ON public.reviews(created_at DESC);

-- Function to calculate average rating
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

-- ============================================
-- 4. NOTIFICATIONS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('review')),
  title TEXT NOT NULL,
  message TEXT,
  related_id UUID,
  is_read BOOLEAN DEFAULT FALSE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Indexes for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id, is_read) 
  WHERE is_read = FALSE;

-- Function to count unread notifications
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

-- ============================================
-- 5. FOLLOWS TABLE (for future use)
-- ============================================
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT follows_no_self_follow CHECK (follower_id != following_id),
  CONSTRAINT follows_unique_pair UNIQUE (follower_id, following_id)
);

-- Indexes for follows
CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows(following_id);
CREATE INDEX IF NOT EXISTS idx_follows_created_at ON public.follows(created_at DESC);

-- ============================================
-- 6. FUNCTIONS
-- ============================================

-- Function to create notification
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

-- ============================================
-- 7. TRIGGERS
-- ============================================

-- Trigger: Auto-create notification when review is created
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

-- ============================================
-- 8. STORAGE BUCKETS (Optional - for future use)
-- ============================================
-- Note: For simple testing, images can be stored as URLs in database
-- Uncomment below if you want to use Supabase Storage

-- -- Create avatars bucket
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('avatars', 'avatars', true)
-- ON CONFLICT (id) DO NOTHING;

-- -- Create product-images bucket
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('product-images', 'product-images', true)
-- ON CONFLICT (id) DO NOTHING;

-- ============================================
-- END OF SCHEMA
-- ============================================

