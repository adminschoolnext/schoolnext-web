-- ============================================================
-- Migration: 004_add_oauth_support_system_config.sql
-- Version: 5
-- Description: Agrega configuración OAuth a system_config
-- Date: 2025-12-07
-- Author: [Tu Nombre]
-- ============================================================

-- Métodos de autenticación habilitados
ALTER TABLE public.system_config 
ADD COLUMN IF NOT EXISTS auth_local_enabled BOOLEAN DEFAULT true;

ALTER TABLE public.system_config 
ADD COLUMN IF NOT EXISTS auth_google_enabled BOOLEAN DEFAULT false;

ALTER TABLE public.system_config 
ADD COLUMN IF NOT EXISTS auth_microsoft_enabled BOOLEAN DEFAULT false;

-- Credenciales Google OAuth
ALTER TABLE public.system_config 
ADD COLUMN IF NOT EXISTS google_client_id VARCHAR;

-- Credenciales Microsoft OAuth
ALTER TABLE public.system_config 
ADD COLUMN IF NOT EXISTS microsoft_client_id VARCHAR;

ALTER TABLE public.system_config 
ADD COLUMN IF NOT EXISTS microsoft_tenant_id VARCHAR;

-- Comentarios de documentación
COMMENT ON COLUMN public.system_config.auth_local_enabled IS 'Habilita autenticación con usuario/contraseña';
COMMENT ON COLUMN public.system_config.auth_google_enabled IS 'Habilita autenticación con Google';
COMMENT ON COLUMN public.system_config.auth_microsoft_enabled IS 'Habilita autenticación con Microsoft';
COMMENT ON COLUMN public.system_config.google_client_id IS 'Client ID de Google Cloud Console';
COMMENT ON COLUMN public.system_config.microsoft_client_id IS 'Application (client) ID de Azure AD';
COMMENT ON COLUMN public.system_config.microsoft_tenant_id IS 'Directory (tenant) ID de Azure AD';

-- ============================================================
-- FIN DE MIGRACIÓN 004
-- ============================================================
