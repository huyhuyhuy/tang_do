-- ============================================
-- Script to DELETE ALL database objects in Supabase
-- WARNING: This will delete ALL data and structure!
-- Use with caution!
-- ============================================

-- ============================================
-- 1. DROP TRIGGERS
-- ============================================
DROP TRIGGER IF EXISTS trigger_notify_on_review ON public.reviews;
DROP TRIGGER IF EXISTS set_products_expires_at ON public.products;
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;

-- ============================================
-- 2. DROP FUNCTIONS
-- ============================================
DROP FUNCTION IF EXISTS notify_product_owner_on_review() CASCADE;
DROP FUNCTION IF EXISTS set_product_expires_at() CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS create_notification(UUID, TEXT, TEXT, TEXT, UUID) CASCADE;
DROP FUNCTION IF EXISTS get_unread_notification_count(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_product_average_rating(UUID) CASCADE;

-- ============================================
-- 3. DROP TABLES (in order to respect foreign keys)
-- ============================================
-- Drop tables that reference other tables first
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.follows CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- ============================================
-- 4. DROP STORAGE BUCKETS
-- ============================================
-- Note: This requires admin privileges
-- You may need to delete these manually from Supabase Dashboard
-- or use the Supabase API
DELETE FROM storage.buckets WHERE id = 'avatars';
DELETE FROM storage.buckets WHERE id = 'product-images';

-- ============================================
-- 5. DROP EXTENSIONS (if you created any custom ones)
-- ============================================
-- Uncomment if needed
-- DROP EXTENSION IF EXISTS <extension_name> CASCADE;

-- ============================================
-- VERIFICATION QUERIES (optional - run these to check)
-- ============================================
-- Check remaining tables
-- SELECT table_name 
-- FROM information_schema.tables 
-- WHERE table_schema = 'public' 
-- AND table_type = 'BASE TABLE';

-- Check remaining functions
-- SELECT routine_name 
-- FROM information_schema.routines 
-- WHERE routine_schema = 'public';

-- Check remaining triggers
-- SELECT trigger_name, event_object_table 
-- FROM information_schema.triggers 
-- WHERE trigger_schema = 'public';

-- ============================================
-- END OF DELETE SCRIPT
-- ============================================

