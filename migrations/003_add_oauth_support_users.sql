-- ============================================================
-- Migration: 003_add_oauth_support_users.sql
-- Version: 4
-- Description: Agrega soporte OAuth (Google/Microsoft) a usuarios
-- Date: 2025-12-07
-- Author: [Tu Nombre]
-- ============================================================

-- Indica si el usuario tiene contraseña local configurada
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS auth_local_enabled BOOLEAN DEFAULT true;

-- Google OAuth
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS google_user_id VARCHAR;

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS google_linked_at TIMESTAMP WITH TIME ZONE;

-- Microsoft OAuth
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS microsoft_user_id VARCHAR;

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS microsoft_linked_at TIMESTAMP WITH TIME ZONE;

-- Foto de perfil (opcional, viene de OAuth)
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Comentarios de documentación
COMMENT ON COLUMN public.users.auth_local_enabled IS 'True si puede autenticarse con usuario/contraseña local';
COMMENT ON COLUMN public.users.google_user_id IS 'ID único de Google (sub claim del JWT)';
COMMENT ON COLUMN public.users.google_linked_at IS 'Fecha en que se vinculó la cuenta de Google';
COMMENT ON COLUMN public.users.microsoft_user_id IS 'ID único de Microsoft (oid claim del JWT)';
COMMENT ON COLUMN public.users.microsoft_linked_at IS 'Fecha en que se vinculó la cuenta de Microsoft';
COMMENT ON COLUMN public.users.avatar_url IS 'URL de la foto de perfil del usuario';

-- ============================================================
-- FIN DE MIGRACIÓN 003
-- ============================================================
