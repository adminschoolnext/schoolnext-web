-- ============================================================
-- Migration: 001_add_get_public_tables.sql
-- Version: 2
-- Description: Agrega función get_public_tables para backup dinámico
-- Date: 2025-12-06
-- Author: SchoolNext Team
-- ============================================================
-- NOTA: Esta migración agrega la función que permite al módulo
-- de Backup detectar automáticamente todas las tablas.
-- ============================================================

-- Crear función get_public_tables
CREATE OR REPLACE FUNCTION get_public_tables()
RETURNS TABLE(table_name text) 
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT table_name::text
    FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_type = 'BASE TABLE'
    ORDER BY table_name;
$$;

COMMENT ON FUNCTION get_public_tables IS 
'Función para obtener lista de tablas del schema public. Usada por el módulo de Backup. Agregada en migración 001.';

-- ============================================================
-- FIN DE MIGRACIÓN 001
-- ============================================================
