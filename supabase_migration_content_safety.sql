-- ============================================
-- Migration: Content Safety (Report & Block)
-- For Apple App Store Guideline 1.2 - User-Generated Content
-- ============================================

-- ============================================
-- 1. CONTENT_REPORTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL CHECK (content_type IN ('product', 'user', 'review')),
  content_id UUID NOT NULL,
  reported_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_content_reports_reporter ON public.content_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_reported_user ON public.content_reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_content ON public.content_reports(content_type, content_id);
CREATE INDEX IF NOT EXISTS idx_content_reports_status ON public.content_reports(status);
CREATE INDEX IF NOT EXISTS idx_content_reports_created_at ON public.content_reports(created_at DESC);

-- ============================================
-- 2. BLOCKED_USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.blocked_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT blocked_no_self_block CHECK (blocker_id != blocked_id),
  CONSTRAINT blocked_unique_pair UNIQUE (blocker_id, blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON public.blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON public.blocked_users(blocked_id);
