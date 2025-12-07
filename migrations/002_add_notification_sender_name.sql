-- ============================================================
-- Migration: 002_add_notification_sender_name.sql
-- Version: [CURRENT_SCHEMA_VERSION + 1]
-- Description: Agrega campo notification_sender_name a system_config
-- Date: 2025-12-07
-- Author: [Tu Nombre]
-- ============================================================

ALTER TABLE public.system_config 
ADD COLUMN IF NOT EXISTS notification_sender_name character varying DEFAULT 'Sistema de Notificaciones';

COMMENT ON COLUMN public.system_config.notification_sender_name IS 'Nombre del remitente para notificaciones por email. Agregado en migración XXX.';

-- ============================================================
-- FIN DE MIGRACIÓN 002
-- ============================================================
