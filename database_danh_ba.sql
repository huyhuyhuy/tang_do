-- ============================================
-- Database Schema for Contacts (Danh bạ)
-- Public table, no RLS required
-- ============================================

-- ============================================
-- CONTACTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  contact_user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  -- Ensure a user can only save a contact once
  CONSTRAINT contacts_unique_pair UNIQUE (user_id, contact_user_id),
  -- Prevent users from saving themselves
  CONSTRAINT contacts_no_self_contact CHECK (user_id != contact_user_id)
);

-- Indexes for contacts
CREATE INDEX IF NOT EXISTS idx_contacts_user_id ON public.contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_contacts_contact_user_id ON public.contacts(contact_user_id);
CREATE INDEX IF NOT EXISTS idx_contacts_created_at ON public.contacts(created_at DESC);



