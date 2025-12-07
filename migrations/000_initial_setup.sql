-- ============================================================
-- Migration: 000_initial_setup.sql
-- Version: 0
-- Description: Estructura base completa de SchoolNext
-- Date: 2025-01-XX
-- Author: SchoolNext Team
-- ============================================================
-- NOTA: Este script crea toda la estructura inicial de la BD.
-- Debe ejecutarse en una BD vacía de Supabase.
-- ============================================================

-- ============================================================
-- TABLAS BASE (sin dependencias)
-- ============================================================

-- Usuarios (tabla central, muchas FK apuntan aquí)
-- Usuarios (tabla central, muchas FK apuntan aquí)
CREATE TABLE IF NOT EXISTS public.users (
    user_id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_name character varying NOT NULL UNIQUE,
    user_display_name character varying,
    user_mail character varying NOT NULL UNIQUE,
    user_password character varying,
    user_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (user_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying, 'suspended'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    last_login timestamp with time zone,
    auth_local_enabled boolean DEFAULT true,
    google_user_id character varying,
    google_linked_at timestamp with time zone,
    microsoft_user_id character varying,
    microsoft_linked_at timestamp with time zone,
    avatar_url text,
    CONSTRAINT users_pkey PRIMARY KEY (user_id)
);

-- Secuencia para system_config (CORREGIDO: crear secuencia explícita)
CREATE SEQUENCE IF NOT EXISTS public.system_config_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Configuración del sistema (CORREGIDO: usar secuencia explícita)
CREATE TABLE IF NOT EXISTS public.system_config (
    config_id integer NOT NULL DEFAULT nextval('system_config_config_id_seq'::regclass),
    institution_name character varying NOT NULL,
    logo_url text,
    primary_color character varying DEFAULT '#1B365D'::character varying,
    secondary_color character varying DEFAULT '#667eea'::character varying,
    tertiary_color character varying DEFAULT '#764ba2'::character varying,
    pqr_email character varying,
    app_url text,
    notification_enabled boolean DEFAULT false,
    notification_endpoint text,
    notification_type character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    satisfaction_survey_url text,
    recaptcha_site_key character varying,
    recaptcha_secret_key character varying,
    notification_sender_name character varying DEFAULT 'Sistema de Notificaciones',
    auth_local_enabled boolean DEFAULT true,
    auth_google_enabled boolean DEFAULT false,
    auth_microsoft_enabled boolean DEFAULT false,
    google_client_id character varying,
    microsoft_client_id character varying,
    microsoft_tenant_id character varying,
    CONSTRAINT system_config_pkey PRIMARY KEY (config_id)
);

-- Asignar la secuencia a la columna
ALTER SEQUENCE public.system_config_config_id_seq OWNED BY public.system_config.config_id;

-- Roles del sistema
CREATE TABLE IF NOT EXISTS public.roles (
    role_id uuid NOT NULL DEFAULT gen_random_uuid(),
    role_name character varying NOT NULL UNIQUE,
    role_description text,
    is_super_admin boolean NOT NULL DEFAULT false,
    role_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (role_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT roles_pkey PRIMARY KEY (role_id)
);

-- Permisos
CREATE TABLE IF NOT EXISTS public.permissions (
    permission_id uuid NOT NULL DEFAULT gen_random_uuid(),
    permission_name character varying NOT NULL UNIQUE,
    permission_description text,
    permission_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (permission_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    module_id character varying,
    page_url character varying,
    CONSTRAINT permissions_pkey PRIMARY KEY (permission_id)
);

-- Cargos laborales
CREATE TABLE IF NOT EXISTS public.job_roles (
    role_id uuid NOT NULL DEFAULT gen_random_uuid(),
    role_name character varying NOT NULL UNIQUE,
    role_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (role_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT job_roles_pkey PRIMARY KEY (role_id)
);

-- ============================================================
-- TABLAS DE RELACIÓN USUARIOS-ROLES-PERMISOS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.user_roles (
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    assigned_by uuid,
    assigned_at timestamp with time zone NOT NULL DEFAULT now(),
    expires_at timestamp with time zone,
    CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role_id),
    CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
    CONSTRAINT user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id),
    CONSTRAINT user_roles_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.role_permissions (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    granted_by uuid,
    granted_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id),
    CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id),
    CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(permission_id),
    CONSTRAINT role_permissions_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.user_job_roles (
    user_id uuid NOT NULL,
    job_role_id uuid NOT NULL,
    assigned_date date NOT NULL DEFAULT CURRENT_DATE,
    is_primary_role boolean NOT NULL DEFAULT false,
    assignment_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (assignment_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying, 'suspended'::character varying]::text[])),
    assigned_by uuid,
    notes text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT user_job_roles_pkey PRIMARY KEY (user_id, job_role_id),
    CONSTRAINT user_job_roles_user_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
    CONSTRAINT user_job_roles_job_role_fkey FOREIGN KEY (job_role_id) REFERENCES public.job_roles(role_id),
    CONSTRAINT user_job_roles_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(user_id)
);

-- Auditoría
CREATE TABLE IF NOT EXISTS public.audit_log (
    audit_id uuid NOT NULL DEFAULT gen_random_uuid(),
    table_name character varying NOT NULL,
    operation character varying NOT NULL 
        CHECK (operation::text = ANY (ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying]::text[])),
    row_id character varying NOT NULL,
    old_values jsonb,
    new_values jsonb,
    changed_by uuid,
    user_display_name character varying,
    changed_at timestamp with time zone NOT NULL DEFAULT now(),
    additional_info jsonb,
    CONSTRAINT audit_log_pkey PRIMARY KEY (audit_id),
    CONSTRAINT audit_log_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES public.users(user_id)
);

-- ============================================================
-- MÓDULO: FORMULARIOS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.forms (
    form_id uuid NOT NULL DEFAULT gen_random_uuid(),
    form_name character varying NOT NULL UNIQUE,
    form_description text,
    is_active boolean NOT NULL DEFAULT true,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    form_mode character varying NOT NULL DEFAULT 'procedure_only'::character varying 
        CHECK (form_mode::text = ANY (ARRAY['procedure_only'::character varying::text, 'standalone_only'::character varying::text, 'both'::character varying::text])),
    standalone_is_public boolean NOT NULL DEFAULT false,
    standalone_notify_email character varying,
    CONSTRAINT forms_pkey PRIMARY KEY (form_id),
    CONSTRAINT forms_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.form_fields (
    field_id uuid NOT NULL DEFAULT gen_random_uuid(),
    form_id uuid NOT NULL,
    field_name character varying NOT NULL,
    field_label character varying NOT NULL,
    field_type character varying NOT NULL 
        CHECK (field_type::text = ANY (ARRAY['text'::character varying::text, 'textarea'::character varying::text, 'number'::character varying::text, 'date'::character varying::text, 'select'::character varying::text, 'radio'::character varying::text, 'checkbox'::character varying::text, 'file'::character varying::text])),
    field_order integer NOT NULL DEFAULT 1,
    is_required boolean NOT NULL DEFAULT false,
    validation_format character varying 
        CHECK (validation_format IS NULL OR (validation_format::text = ANY (ARRAY['email'::character varying, 'phone'::character varying, 'url'::character varying, 'none'::character varying]::text[]))),
    min_value numeric,
    max_value numeric,
    max_file_size integer,
    allowed_file_types character varying,
    auto_fill_type character varying 
        CHECK (auto_fill_type IS NULL OR (auto_fill_type::text = ANY (ARRAY['user_name'::character varying, 'user_email'::character varying, 'current_date'::character varying, 'none'::character varying]::text[]))),
    placeholder_text character varying,
    help_text text,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT form_fields_pkey PRIMARY KEY (field_id),
    CONSTRAINT form_fields_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(form_id)
);

CREATE TABLE IF NOT EXISTS public.field_option_catalog (
    option_id uuid NOT NULL DEFAULT gen_random_uuid(),
    field_id uuid NOT NULL,
    option_label character varying NOT NULL,
    option_value character varying NOT NULL,
    option_order integer NOT NULL DEFAULT 1,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT field_option_catalog_pkey PRIMARY KEY (option_id),
    CONSTRAINT field_option_catalog_field_id_fkey FOREIGN KEY (field_id) REFERENCES public.form_fields(field_id)
);

CREATE TABLE IF NOT EXISTS public.form_submissions (
    submission_id uuid NOT NULL DEFAULT gen_random_uuid(),
    form_id uuid NOT NULL,
    submitted_by_user_id uuid,
    submitter_name character varying NOT NULL,
    submitter_email character varying NOT NULL,
    submitter_phone character varying,
    form_data jsonb NOT NULL,
    submitted_at timestamp with time zone NOT NULL DEFAULT now(),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT form_submissions_pkey PRIMARY KEY (submission_id),
    CONSTRAINT form_submissions_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(form_id),
    CONSTRAINT form_submissions_submitted_by_user_id_fkey FOREIGN KEY (submitted_by_user_id) REFERENCES public.users(user_id)
);

-- ============================================================
-- MÓDULO: PROCEDIMIENTOS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.procedures (
    procedure_id uuid NOT NULL DEFAULT gen_random_uuid(),
    procedure_name character varying NOT NULL UNIQUE,
    procedure_description text,
    procedure_type character varying NOT NULL 
        CHECK (procedure_type::text = ANY (ARRAY['internal'::character varying, 'external'::character varying]::text[])),
    form_id uuid NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT procedures_pkey PRIMARY KEY (procedure_id),
    CONSTRAINT procedures_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(form_id),
    CONSTRAINT procedures_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.procedure_steps (
    step_id uuid NOT NULL DEFAULT gen_random_uuid(),
    procedure_id uuid NOT NULL,
    step_sequence integer NOT NULL,
    step_name character varying NOT NULL,
    step_description text,
    step_type character varying NOT NULL DEFAULT 'manual'::character varying 
        CHECK (step_type::text = ANY (ARRAY['manual'::character varying, 'notification'::character varying, 'automatic'::character varying, 'send_email'::character varying]::text[])),
    responsible_user_id uuid,
    has_branches boolean NOT NULL DEFAULT false,
    is_final_step boolean NOT NULL DEFAULT false,
    sla_days integer CHECK (sla_days IS NULL OR sla_days > 0),
    next_step_id uuid,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    form_id uuid,
    email_config jsonb,
    CONSTRAINT procedure_steps_pkey PRIMARY KEY (step_id),
    CONSTRAINT procedure_steps_procedure_id_fkey FOREIGN KEY (procedure_id) REFERENCES public.procedures(procedure_id),
    CONSTRAINT procedure_steps_responsible_user_id_fkey FOREIGN KEY (responsible_user_id) REFERENCES public.users(user_id),
    CONSTRAINT procedure_steps_form_id_fkey FOREIGN KEY (form_id) REFERENCES public.forms(form_id)
);

-- Agregar FK circular después de crear la tabla
ALTER TABLE public.procedure_steps 
    ADD CONSTRAINT procedure_steps_next_step_id_fkey 
    FOREIGN KEY (next_step_id) REFERENCES public.procedure_steps(step_id);

CREATE TABLE IF NOT EXISTS public.procedure_step_branches (
    branch_id uuid NOT NULL DEFAULT gen_random_uuid(),
    step_id uuid NOT NULL,
    branch_label character varying NOT NULL,
    branch_order integer NOT NULL DEFAULT 1,
    next_step_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT procedure_step_branches_pkey PRIMARY KEY (branch_id),
    CONSTRAINT procedure_step_branches_step_id_fkey FOREIGN KEY (step_id) REFERENCES public.procedure_steps(step_id),
    CONSTRAINT procedure_step_branches_next_step_id_fkey FOREIGN KEY (next_step_id) REFERENCES public.procedure_steps(step_id)
);

CREATE TABLE IF NOT EXISTS public.procedure_instances (
    instance_id uuid NOT NULL DEFAULT gen_random_uuid(),
    procedure_id uuid NOT NULL,
    instance_status character varying NOT NULL DEFAULT 'in_progress'::character varying 
        CHECK (instance_status::text = ANY (ARRAY['in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying]::text[])),
    initiated_by_user_id uuid,
    requester_name character varying NOT NULL,
    requester_email character varying NOT NULL,
    requester_phone character varying,
    form_data jsonb NOT NULL,
    current_step_id uuid,
    started_at timestamp with time zone NOT NULL DEFAULT now(),
    completed_at timestamp with time zone,
    cancelled_at timestamp with time zone,
    cancelled_by uuid,
    cancellation_reason text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT procedure_instances_pkey PRIMARY KEY (instance_id),
    CONSTRAINT procedure_instances_procedure_id_fkey FOREIGN KEY (procedure_id) REFERENCES public.procedures(procedure_id),
    CONSTRAINT procedure_instances_initiated_by_user_id_fkey FOREIGN KEY (initiated_by_user_id) REFERENCES public.users(user_id),
    CONSTRAINT procedure_instances_current_step_id_fkey FOREIGN KEY (current_step_id) REFERENCES public.procedure_steps(step_id),
    CONSTRAINT procedure_instances_cancelled_by_fkey FOREIGN KEY (cancelled_by) REFERENCES public.users(user_id)
);

-- ============================================================
-- MÓDULO: TAREAS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.task_tags (
    tag_id uuid NOT NULL DEFAULT gen_random_uuid(),
    tag_name character varying NOT NULL UNIQUE,
    tag_color character varying NOT NULL DEFAULT '#667eea'::character varying,
    tag_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (tag_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT task_tags_pkey PRIMARY KEY (tag_id)
);

-- ============================================================
-- MÓDULO: KPI / INDICADORES
-- ============================================================

CREATE TABLE IF NOT EXISTS public.indicator_categories (
    category_id uuid NOT NULL DEFAULT gen_random_uuid(),
    category_name character varying NOT NULL UNIQUE,
    category_description text,
    category_icon character varying DEFAULT 'bi-folder'::character varying,
    category_color character varying DEFAULT '#6c757d'::character varying,
    category_order integer DEFAULT 1,
    category_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (category_status::text = ANY (ARRAY['active'::character varying::text, 'inactive'::character varying::text])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT indicator_categories_pkey PRIMARY KEY (category_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_segments (
    segment_id uuid NOT NULL DEFAULT gen_random_uuid(),
    segment_name character varying NOT NULL UNIQUE,
    segment_description text,
    segment_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (segment_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])),
    is_table_linked boolean NOT NULL DEFAULT false,
    source_table character varying,
    source_id_column character varying,
    source_name_column character varying,
    source_filter_column character varying,
    source_filter_value character varying,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_segments_pkey PRIMARY KEY (segment_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_segment_options (
    option_id uuid NOT NULL DEFAULT gen_random_uuid(),
    segment_id uuid NOT NULL,
    option_name character varying NOT NULL,
    option_value character varying NOT NULL,
    option_order integer NOT NULL DEFAULT 1,
    option_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (option_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_segment_options_pkey PRIMARY KEY (option_id),
    CONSTRAINT kpi_segment_options_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.kpi_segments(segment_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_variables (
    variable_id uuid NOT NULL DEFAULT gen_random_uuid(),
    variable_name character varying NOT NULL UNIQUE,
    variable_description text,
    owner_id uuid NOT NULL,
    capture_responsible_id uuid,
    periodicity character varying NOT NULL 
        CHECK (periodicity::text = ANY (ARRAY['annual'::character varying, 'monthly'::character varying]::text[])),
    data_type character varying NOT NULL DEFAULT 'numeric'::character varying 
        CHECK (data_type::text = ANY (ARRAY['numeric'::character varying, 'integer'::character varying, 'percentage'::character varying]::text[])),
    data_source character varying NOT NULL DEFAULT 'manual'::character varying 
        CHECK (data_source::text = ANY (ARRAY['manual'::character varying, 'query'::character varying, 'api'::character varying, 'survey'::character varying]::text[])),
    data_source_config jsonb,
    last_auto_capture timestamp without time zone,
    variable_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (variable_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_variables_pkey PRIMARY KEY (variable_id),
    CONSTRAINT kpi_variables_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(user_id),
    CONSTRAINT kpi_variables_capture_responsible_id_fkey FOREIGN KEY (capture_responsible_id) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_variable_segments (
    variable_id uuid NOT NULL,
    segment_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    aggregation_method character varying NOT NULL DEFAULT 'sum'::character varying 
        CHECK (aggregation_method::text = ANY (ARRAY['sum'::character varying::text, 'average'::character varying::text, 'weighted_average'::character varying::text, 'min'::character varying::text, 'max'::character varying::text, 'count'::character varying::text])),
    CONSTRAINT kpi_variable_segments_pkey PRIMARY KEY (variable_id, segment_id),
    CONSTRAINT kpi_variable_segments_variable_id_fkey FOREIGN KEY (variable_id) REFERENCES public.kpi_variables(variable_id),
    CONSTRAINT kpi_variable_segments_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.kpi_segments(segment_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_variable_values (
    value_id uuid NOT NULL DEFAULT gen_random_uuid(),
    variable_id uuid NOT NULL,
    period character varying NOT NULL CHECK (period::text ~ '^\d{4}(-\d{2})?$'::text),
    segment_combination jsonb,
    value_numeric numeric,
    value_text character varying,
    captured_by uuid NOT NULL,
    captured_at timestamp with time zone NOT NULL DEFAULT now(),
    notes text,
    value_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (value_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying, 'corrected'::character varying]::text[])),
    value_source character varying NOT NULL DEFAULT 'manual'::character varying 
        CHECK (value_source::text = ANY (ARRAY['manual'::character varying, 'calculated'::character varying, 'api'::character varying]::text[])),
    execution_time_ms integer,
    execution_metadata jsonb,
    CONSTRAINT kpi_variable_values_pkey PRIMARY KEY (value_id),
    CONSTRAINT kpi_variable_values_variable_id_fkey FOREIGN KEY (variable_id) REFERENCES public.kpi_variables(variable_id),
    CONSTRAINT kpi_variable_values_captured_by_fkey FOREIGN KEY (captured_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_variable_permissions (
    variable_id uuid NOT NULL,
    user_id uuid NOT NULL,
    permission_type character varying NOT NULL 
        CHECK (permission_type::text = ANY (ARRAY['read'::character varying, 'write'::character varying, 'admin'::character varying]::text[])),
    granted_by uuid,
    granted_at timestamp with time zone NOT NULL DEFAULT now(),
    expires_at timestamp with time zone,
    CONSTRAINT kpi_variable_permissions_pkey PRIMARY KEY (variable_id, user_id),
    CONSTRAINT kpi_variable_permissions_variable_id_fkey FOREIGN KEY (variable_id) REFERENCES public.kpi_variables(variable_id),
    CONSTRAINT kpi_variable_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
    CONSTRAINT kpi_variable_permissions_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.variable_category_assignments (
    variable_id uuid NOT NULL,
    category_id uuid NOT NULL,
    assigned_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT variable_category_assignments_pkey PRIMARY KEY (variable_id, category_id),
    CONSTRAINT variable_category_assignments_variable_id_fkey FOREIGN KEY (variable_id) REFERENCES public.kpi_variables(variable_id),
    CONSTRAINT variable_category_assignments_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.indicator_categories(category_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_indicators (
    indicator_id uuid NOT NULL DEFAULT gen_random_uuid(),
    indicator_name character varying NOT NULL UNIQUE,
    indicator_description text,
    formula_expression text NOT NULL,
    formula_variables jsonb,
    result_format character varying NOT NULL DEFAULT 'decimal'::character varying 
        CHECK (result_format::text = ANY (ARRAY['decimal'::character varying, 'percentage'::character varying, 'integer'::character varying]::text[])),
    owner_id uuid NOT NULL,
    indicator_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (indicator_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying, 'testing'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    comparison_direction character varying DEFAULT 'higher_better'::character varying 
        CHECK (comparison_direction::text = ANY (ARRAY['higher_better'::character varying, 'lower_better'::character varying]::text[])),
    relevance_justification text,
    strategic_alignment text,
    CONSTRAINT kpi_indicators_pkey PRIMARY KEY (indicator_id),
    CONSTRAINT kpi_indicators_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.indicator_category_assignments (
    indicator_id uuid NOT NULL,
    category_id uuid NOT NULL,
    assigned_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT indicator_category_assignments_pkey PRIMARY KEY (indicator_id, category_id),
    CONSTRAINT indicator_category_assignments_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.kpi_indicators(indicator_id),
    CONSTRAINT indicator_category_assignments_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.indicator_categories(category_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_indicator_goals (
    goal_id uuid NOT NULL DEFAULT gen_random_uuid(),
    indicator_id uuid NOT NULL,
    period character varying NOT NULL CHECK (period::text ~ '^\d{4}(-\d{2})?$'::text),
    goal_value numeric NOT NULL,
    goal_description text,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    goal_justification text,
    CONSTRAINT kpi_indicator_goals_pkey PRIMARY KEY (goal_id),
    CONSTRAINT kpi_indicator_goals_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.kpi_indicators(indicator_id),
    CONSTRAINT kpi_indicator_goals_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_indicator_analysis_notes (
    note_id uuid NOT NULL DEFAULT gen_random_uuid(),
    indicator_id uuid NOT NULL,
    note_text text NOT NULL,
    note_type character varying NOT NULL DEFAULT 'analysis'::character varying 
        CHECK (note_type::text = ANY (ARRAY['analysis'::character varying, 'observation'::character varying, 'concern'::character varying, 'insight'::character varying]::text[])),
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_indicator_analysis_notes_pkey PRIMARY KEY (note_id),
    CONSTRAINT kpi_indicator_analysis_notes_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.kpi_indicators(indicator_id),
    CONSTRAINT kpi_indicator_analysis_notes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_benchmarks (
    benchmark_id uuid NOT NULL DEFAULT gen_random_uuid(),
    benchmark_name character varying NOT NULL UNIQUE,
    benchmark_type character varying NOT NULL 
        CHECK (benchmark_type::text = ANY (ARRAY['competitor'::character varying, 'industry_average'::character varying, 'government_standard'::character varying, 'best_practice'::character varying, 'other'::character varying]::text[])),
    organization_name character varying,
    country character varying,
    sector character varying,
    description text,
    source_url text,
    is_public boolean NOT NULL DEFAULT true,
    benchmark_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (benchmark_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_benchmarks_pkey PRIMARY KEY (benchmark_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_indicator_benchmarks (
    indicator_id uuid NOT NULL,
    benchmark_id uuid NOT NULL,
    period character varying NOT NULL CHECK (period::text ~ '^\d{4}(-\d{2})?$'::text),
    benchmark_value numeric NOT NULL,
    notes text,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_indicator_benchmarks_pkey PRIMARY KEY (indicator_id, benchmark_id, period),
    CONSTRAINT kpi_indicator_benchmarks_benchmark_id_fkey FOREIGN KEY (benchmark_id) REFERENCES public.kpi_benchmarks(benchmark_id),
    CONSTRAINT kpi_indicator_benchmarks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id),
    CONSTRAINT kpi_indicator_benchmarks_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.kpi_indicators(indicator_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_stakeholder_groups (
    stakeholder_group_id uuid NOT NULL DEFAULT gen_random_uuid(),
    group_name character varying NOT NULL UNIQUE,
    group_description text,
    group_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (group_status::text = ANY (ARRAY['active'::character varying::text, 'inactive'::character varying::text])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_stakeholder_groups_pkey PRIMARY KEY (stakeholder_group_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_indicator_stakeholders (
    indicator_id uuid NOT NULL,
    stakeholder_group_id uuid NOT NULL,
    expectation text,
    priority character varying NOT NULL DEFAULT 'medium'::character varying 
        CHECK (priority::text = ANY (ARRAY['high'::character varying::text, 'medium'::character varying::text, 'low'::character varying::text])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_indicator_stakeholders_pkey PRIMARY KEY (indicator_id, stakeholder_group_id),
    CONSTRAINT kpi_indicator_stakeholders_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.kpi_indicators(indicator_id),
    CONSTRAINT kpi_indicator_stakeholders_stakeholder_group_id_fkey FOREIGN KEY (stakeholder_group_id) REFERENCES public.kpi_stakeholder_groups(stakeholder_group_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_improvement_plans (
    plan_id uuid NOT NULL DEFAULT gen_random_uuid(),
    indicator_id uuid NOT NULL,
    goal_id uuid NOT NULL,
    plan_name character varying NOT NULL,
    plan_objective text NOT NULL,
    strategy_summary text,
    plan_status character varying NOT NULL DEFAULT 'draft'::character varying 
        CHECK (plan_status::text = ANY (ARRAY['draft'::character varying, 'active'::character varying, 'completed'::character varying, 'cancelled'::character varying]::text[])),
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    completed_at timestamp with time zone,
    CONSTRAINT kpi_improvement_plans_pkey PRIMARY KEY (plan_id),
    CONSTRAINT kpi_improvement_plans_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.kpi_indicators(indicator_id),
    CONSTRAINT kpi_improvement_plans_goal_id_fkey FOREIGN KEY (goal_id) REFERENCES public.kpi_indicator_goals(goal_id),
    CONSTRAINT kpi_improvement_plans_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_plan_updates (
    update_id uuid NOT NULL DEFAULT gen_random_uuid(),
    plan_id uuid NOT NULL,
    update_text text NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_plan_updates_pkey PRIMARY KEY (update_id),
    CONSTRAINT kpi_plan_updates_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.kpi_improvement_plans(plan_id),
    CONSTRAINT kpi_plan_updates_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_relationship_suggestions (
    suggestion_id uuid NOT NULL DEFAULT gen_random_uuid(),
    indicator_cause_id uuid,
    indicator_effect_id uuid,
    correlation_value numeric NOT NULL,
    lag_months integer NOT NULL DEFAULT 0,
    periods_analyzed integer,
    suggestion_status character varying NOT NULL DEFAULT 'pending'::character varying 
        CHECK (suggestion_status::text = ANY (ARRAY['pending'::character varying::text, 'confirmed'::character varying::text, 'rejected'::character varying::text])),
    reviewed_by uuid,
    reviewed_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    notes text,
    variable_cause_id uuid,
    variable_effect_id uuid,
    CONSTRAINT kpi_relationship_suggestions_pkey PRIMARY KEY (suggestion_id),
    CONSTRAINT kpi_relationship_suggestions_indicator_cause_id_fkey FOREIGN KEY (indicator_cause_id) REFERENCES public.kpi_indicators(indicator_id),
    CONSTRAINT kpi_relationship_suggestions_indicator_effect_id_fkey FOREIGN KEY (indicator_effect_id) REFERENCES public.kpi_indicators(indicator_id),
    CONSTRAINT kpi_relationship_suggestions_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES public.users(user_id),
    CONSTRAINT kpi_relationship_suggestions_variable_cause_id_fkey FOREIGN KEY (variable_cause_id) REFERENCES public.kpi_variables(variable_id),
    CONSTRAINT kpi_relationship_suggestions_variable_effect_id_fkey FOREIGN KEY (variable_effect_id) REFERENCES public.kpi_variables(variable_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_user_dashboard_indicators (
    user_id uuid NOT NULL,
    indicator_id uuid NOT NULL,
    display_order integer NOT NULL DEFAULT 1,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_user_dashboard_indicators_pkey PRIMARY KEY (user_id, indicator_id),
    CONSTRAINT kpi_user_dashboard_indicators_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
    CONSTRAINT kpi_user_dashboard_indicators_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES public.kpi_indicators(indicator_id)
);

CREATE TABLE IF NOT EXISTS public.kpi_user_dashboard_variables (
    user_id uuid NOT NULL,
    variable_id uuid NOT NULL,
    display_order integer NOT NULL DEFAULT 1,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT kpi_user_dashboard_variables_pkey PRIMARY KEY (user_id, variable_id),
    CONSTRAINT kpi_user_dashboard_variables_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
    CONSTRAINT kpi_user_dashboard_variables_variable_id_fkey FOREIGN KEY (variable_id) REFERENCES public.kpi_variables(variable_id)
);

-- ============================================================
-- MÓDULO: TAREAS (continuación con dependencias)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.tasks (
    task_id uuid NOT NULL DEFAULT gen_random_uuid(),
    task_title character varying NOT NULL,
    task_description text,
    task_priority character varying NOT NULL DEFAULT 'medium'::character varying 
        CHECK (task_priority::text = ANY (ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'urgent'::character varying]::text[])),
    task_status character varying NOT NULL DEFAULT 'pending'::character varying 
        CHECK (task_status::text = ANY (ARRAY['pending'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying, 'blocked'::character varying]::text[])),
    created_by uuid,
    assigned_to uuid,
    due_date date,
    start_date date,
    completed_at timestamp with time zone,
    improvement_plan_id uuid,
    progress_percentage integer DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    blocking_reason text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    module_type character varying 
        CHECK (module_type::text = ANY (ARRAY['procedures'::character varying, 'kpi_improvement'::character varying, 'general'::character varying, 'other'::character varying]::text[])),
    procedure_id uuid,
    procedure_step_id uuid,
    task_progress text,
    instance_id uuid,
    CONSTRAINT tasks_pkey PRIMARY KEY (task_id),
    CONSTRAINT tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id),
    CONSTRAINT tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(user_id),
    CONSTRAINT tasks_improvement_plan_id_fkey FOREIGN KEY (improvement_plan_id) REFERENCES public.kpi_improvement_plans(plan_id),
    CONSTRAINT tasks_procedure_id_fkey FOREIGN KEY (procedure_id) REFERENCES public.procedures(procedure_id),
    CONSTRAINT tasks_procedure_step_id_fkey FOREIGN KEY (procedure_step_id) REFERENCES public.procedure_steps(step_id),
    CONSTRAINT tasks_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.procedure_instances(instance_id)
);

CREATE TABLE IF NOT EXISTS public.task_collaborators (
    task_id uuid NOT NULL,
    user_id uuid NOT NULL,
    added_by uuid NOT NULL,
    added_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT task_collaborators_pkey PRIMARY KEY (task_id, user_id),
    CONSTRAINT task_collaborators_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(task_id),
    CONSTRAINT task_collaborators_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
    CONSTRAINT task_collaborators_added_by_fkey FOREIGN KEY (added_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.task_comments (
    comment_id uuid NOT NULL DEFAULT gen_random_uuid(),
    task_id uuid NOT NULL,
    comment_text text NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT task_comments_pkey PRIMARY KEY (comment_id),
    CONSTRAINT task_comments_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(task_id),
    CONSTRAINT task_comments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.task_attachments (
    attachment_id uuid NOT NULL DEFAULT gen_random_uuid(),
    task_id uuid NOT NULL,
    file_name character varying NOT NULL,
    file_url text NOT NULL,
    file_size integer,
    file_type character varying,
    uploaded_by uuid NOT NULL,
    uploaded_at timestamp with time zone NOT NULL DEFAULT now(),
    storage_path text,
    CONSTRAINT task_attachments_pkey PRIMARY KEY (attachment_id),
    CONSTRAINT task_attachments_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(task_id),
    CONSTRAINT task_attachments_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.task_tag_assignments (
    task_id uuid NOT NULL,
    tag_id uuid NOT NULL,
    assigned_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT task_tag_assignments_pkey PRIMARY KEY (task_id, tag_id),
    CONSTRAINT task_tag_assignments_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(task_id),
    CONSTRAINT task_tag_assignments_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.task_tags(tag_id)
);

-- ============================================================
-- MÓDULO: PROCEDIMIENTOS (tablas con dependencias de tasks)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.procedure_step_executions (
    execution_id uuid NOT NULL DEFAULT gen_random_uuid(),
    instance_id uuid NOT NULL,
    step_id uuid NOT NULL,
    task_id uuid,
    execution_status character varying NOT NULL DEFAULT 'pending'::character varying 
        CHECK (execution_status::text = ANY (ARRAY['pending'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'skipped'::character varying]::text[])),
    selected_branch_id uuid,
    assigned_to uuid,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    execution_notes text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT procedure_step_executions_pkey PRIMARY KEY (execution_id),
    CONSTRAINT procedure_step_executions_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.procedure_instances(instance_id),
    CONSTRAINT procedure_step_executions_step_id_fkey FOREIGN KEY (step_id) REFERENCES public.procedure_steps(step_id),
    CONSTRAINT procedure_step_executions_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.tasks(task_id),
    CONSTRAINT procedure_step_executions_selected_branch_id_fkey FOREIGN KEY (selected_branch_id) REFERENCES public.procedure_step_branches(branch_id),
    CONSTRAINT procedure_step_executions_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(user_id)
);

-- Form responses (depende de procedure_step_executions)
CREATE TABLE IF NOT EXISTS public.form_responses (
    response_id uuid NOT NULL DEFAULT gen_random_uuid(),
    instance_id uuid,
    field_id uuid NOT NULL,
    response_text text,
    response_number numeric,
    response_date date,
    response_file_url text,
    selected_option_id uuid,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    response_boolean boolean,
    submission_id uuid,
    execution_id uuid,
    CONSTRAINT form_responses_pkey PRIMARY KEY (response_id),
    CONSTRAINT form_responses_field_id_fkey FOREIGN KEY (field_id) REFERENCES public.form_fields(field_id),
    CONSTRAINT form_responses_selected_option_id_fkey FOREIGN KEY (selected_option_id) REFERENCES public.field_option_catalog(option_id),
    CONSTRAINT form_responses_submission_id_fkey FOREIGN KEY (submission_id) REFERENCES public.form_submissions(submission_id),
    CONSTRAINT form_responses_instance_id_fkey FOREIGN KEY (instance_id) REFERENCES public.procedure_instances(instance_id),
    CONSTRAINT form_responses_execution_id_fkey FOREIGN KEY (execution_id) REFERENCES public.procedure_step_executions(execution_id)
);

-- ============================================================
-- MÓDULO: PQR
-- ============================================================

CREATE TABLE IF NOT EXISTS public.pqr_priorities (
    priority_id uuid NOT NULL DEFAULT gen_random_uuid(),
    priority_name character varying NOT NULL UNIQUE,
    days_to_respond integer NOT NULL CHECK (days_to_respond > 0),
    priority_color character varying NOT NULL DEFAULT '#667eea'::character varying,
    priority_order integer NOT NULL DEFAULT 1,
    priority_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (priority_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT pqr_priorities_pkey PRIMARY KEY (priority_id)
);

CREATE TABLE IF NOT EXISTS public.pqr_categories (
    category_id uuid NOT NULL DEFAULT gen_random_uuid(),
    category_name character varying NOT NULL UNIQUE,
    category_description text,
    responsible_user_id uuid NOT NULL,
    category_status character varying NOT NULL DEFAULT 'active'::character varying 
        CHECK (category_status::text = ANY (ARRAY['active'::character varying, 'inactive'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT pqr_categories_pkey PRIMARY KEY (category_id),
    CONSTRAINT pqr_categories_responsible_user_fkey FOREIGN KEY (responsible_user_id) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.pqr_requests (
    request_id uuid NOT NULL DEFAULT gen_random_uuid(),
    request_code character varying NOT NULL UNIQUE,
    requester_name character varying NOT NULL,
    requester_email character varying NOT NULL,
    subject character varying NOT NULL,
    description text NOT NULL,
    request_status character varying NOT NULL DEFAULT 'received'::character varying 
        CHECK (request_status::text = ANY (ARRAY['received'::character varying, 'assigned'::character varying, 'in_progress'::character varying, 'closed'::character varying]::text[])),
    priority_id uuid,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    due_date date,
    closed_at timestamp with time zone,
    closed_by uuid,
    attachment_file_name character varying,
    attachment_file_url text,
    attachment_file_size integer,
    attachment_storage_path text,
    CONSTRAINT pqr_requests_pkey PRIMARY KEY (request_id),
    CONSTRAINT pqr_requests_priority_fkey FOREIGN KEY (priority_id) REFERENCES public.pqr_priorities(priority_id),
    CONSTRAINT pqr_requests_closed_by_fkey FOREIGN KEY (closed_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.pqr_category_assignments (
    assignment_id uuid NOT NULL DEFAULT gen_random_uuid(),
    request_id uuid NOT NULL,
    category_id uuid NOT NULL,
    assigned_text text NOT NULL,
    assigned_by uuid NOT NULL,
    assigned_at timestamp with time zone NOT NULL DEFAULT now(),
    response_draft text,
    category_status character varying NOT NULL DEFAULT 'pending'::character varying 
        CHECK (category_status::text = ANY (ARRAY['pending'::character varying, 'closed'::character varying]::text[])),
    closed_by_responsible_at timestamp with time zone,
    CONSTRAINT pqr_category_assignments_pkey PRIMARY KEY (assignment_id),
    CONSTRAINT pqr_category_assignments_request_fkey FOREIGN KEY (request_id) REFERENCES public.pqr_requests(request_id),
    CONSTRAINT pqr_category_assignments_category_fkey FOREIGN KEY (category_id) REFERENCES public.pqr_categories(category_id),
    CONSTRAINT pqr_category_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.pqr_comments (
    comment_id uuid NOT NULL DEFAULT gen_random_uuid(),
    request_id uuid NOT NULL,
    category_id uuid,
    comment_text text NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT pqr_comments_pkey PRIMARY KEY (comment_id),
    CONSTRAINT pqr_comments_request_fkey FOREIGN KEY (request_id) REFERENCES public.pqr_requests(request_id),
    CONSTRAINT pqr_comments_category_fkey FOREIGN KEY (category_id) REFERENCES public.pqr_categories(category_id),
    CONSTRAINT pqr_comments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.pqr_final_responses (
    response_id uuid NOT NULL DEFAULT gen_random_uuid(),
    request_id uuid NOT NULL,
    response_text text NOT NULL,
    sent_by uuid NOT NULL,
    sent_at timestamp with time zone NOT NULL DEFAULT now(),
    email_sent boolean NOT NULL DEFAULT false,
    CONSTRAINT pqr_final_responses_pkey PRIMARY KEY (response_id),
    CONSTRAINT pqr_final_responses_request_fkey FOREIGN KEY (request_id) REFERENCES public.pqr_requests(request_id),
    CONSTRAINT pqr_final_responses_sent_by_fkey FOREIGN KEY (sent_by) REFERENCES public.users(user_id)
);

-- ============================================================
-- MÓDULO: ENCUESTAS
-- ============================================================

CREATE TABLE IF NOT EXISTS public.survey_scales (
    scale_id uuid NOT NULL DEFAULT gen_random_uuid(),
    scale_name character varying NOT NULL,
    description text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT survey_scales_pkey PRIMARY KEY (scale_id)
);

CREATE TABLE IF NOT EXISTS public.survey_scale_options (
    option_id uuid NOT NULL DEFAULT gen_random_uuid(),
    scale_id uuid NOT NULL,
    option_text character varying NOT NULL,
    option_value integer NOT NULL,
    option_order integer NOT NULL,
    CONSTRAINT survey_scale_options_pkey PRIMARY KEY (option_id),
    CONSTRAINT survey_scale_options_scale_id_fkey FOREIGN KEY (scale_id) REFERENCES public.survey_scales(scale_id)
);

CREATE TABLE IF NOT EXISTS public.survey_masters (
    survey_master_id uuid NOT NULL DEFAULT gen_random_uuid(),
    survey_name character varying NOT NULL,
    description text,
    is_active boolean NOT NULL DEFAULT true,
    is_template boolean NOT NULL DEFAULT false,
    created_by uuid NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT survey_masters_pkey PRIMARY KEY (survey_master_id),
    CONSTRAINT survey_masters_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.survey_master_segments (
    survey_master_id uuid NOT NULL,
    segment_id uuid NOT NULL,
    is_required boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT survey_master_segments_pkey PRIMARY KEY (survey_master_id, segment_id),
    CONSTRAINT survey_master_segments_survey_master_id_fkey FOREIGN KEY (survey_master_id) REFERENCES public.survey_masters(survey_master_id),
    CONSTRAINT survey_master_segments_segment_id_fkey FOREIGN KEY (segment_id) REFERENCES public.kpi_segments(segment_id)
);

CREATE TABLE IF NOT EXISTS public.survey_sections (
    section_id uuid NOT NULL DEFAULT gen_random_uuid(),
    survey_master_id uuid NOT NULL,
    section_title character varying NOT NULL,
    section_description text,
    scale_id uuid NOT NULL,
    section_order integer NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT survey_sections_pkey PRIMARY KEY (section_id),
    CONSTRAINT survey_sections_survey_master_id_fkey FOREIGN KEY (survey_master_id) REFERENCES public.survey_masters(survey_master_id),
    CONSTRAINT survey_sections_scale_id_fkey FOREIGN KEY (scale_id) REFERENCES public.survey_scales(scale_id)
);

CREATE TABLE IF NOT EXISTS public.survey_questions (
    question_id uuid NOT NULL DEFAULT gen_random_uuid(),
    section_id uuid NOT NULL,
    question_text text NOT NULL,
    question_order integer NOT NULL,
    is_required boolean NOT NULL DEFAULT true,
    question_type character varying NOT NULL DEFAULT 'scale'::character varying 
        CHECK (question_type::text = ANY (ARRAY['scale'::character varying, 'open_text'::character varying]::text[])),
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT survey_questions_pkey PRIMARY KEY (question_id),
    CONSTRAINT survey_questions_section_id_fkey FOREIGN KEY (section_id) REFERENCES public.survey_sections(section_id)
);

CREATE TABLE IF NOT EXISTS public.survey_applications (
    application_id uuid NOT NULL DEFAULT gen_random_uuid(),
    survey_master_id uuid NOT NULL,
    application_name character varying NOT NULL,
    application_number integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    status character varying NOT NULL DEFAULT 'draft'::character varying 
        CHECK (status::text = ANY (ARRAY['draft'::character varying, 'open'::character varying, 'closed'::character varying]::text[])),
    unique_url_code character varying NOT NULL UNIQUE,
    closed_manually boolean DEFAULT false,
    closed_by uuid,
    closed_at timestamp with time zone,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    expected_responses integer,
    CONSTRAINT survey_applications_pkey PRIMARY KEY (application_id),
    CONSTRAINT survey_applications_survey_master_id_fkey FOREIGN KEY (survey_master_id) REFERENCES public.survey_masters(survey_master_id),
    CONSTRAINT survey_applications_closed_by_fkey FOREIGN KEY (closed_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.survey_respondent_profile (
    profile_id uuid NOT NULL DEFAULT gen_random_uuid(),
    application_id uuid NOT NULL,
    response_token uuid NOT NULL DEFAULT gen_random_uuid() UNIQUE,
    responded_at timestamp with time zone NOT NULL DEFAULT now(),
    segment_data jsonb,
    CONSTRAINT survey_respondent_profile_pkey PRIMARY KEY (profile_id),
    CONSTRAINT survey_respondent_profile_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.survey_applications(application_id)
);

CREATE TABLE IF NOT EXISTS public.survey_responses (
    response_id uuid NOT NULL DEFAULT gen_random_uuid(),
    profile_id uuid NOT NULL,
    question_id uuid NOT NULL,
    response_value integer,
    response_text text,
    responded_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT survey_responses_pkey PRIMARY KEY (response_id),
    CONSTRAINT survey_responses_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.survey_respondent_profile(profile_id),
    CONSTRAINT survey_responses_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.survey_questions(question_id)
);

-- ============================================================
-- MÓDULO: FORMACIÓN / CAPACITACIÓN
-- ============================================================

CREATE TABLE IF NOT EXISTS public.training_axes (
    axis_id uuid NOT NULL DEFAULT gen_random_uuid(),
    institution_id uuid,
    name character varying NOT NULL,
    description text,
    color character varying,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT training_axes_pkey PRIMARY KEY (axis_id),
    CONSTRAINT training_axes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_modalities (
    modality_id uuid NOT NULL DEFAULT gen_random_uuid(),
    institution_id uuid,
    name character varying NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT training_modalities_pkey PRIMARY KEY (modality_id),
    CONSTRAINT training_modalities_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_requisition_sources (
    source_id uuid NOT NULL DEFAULT gen_random_uuid(),
    institution_id uuid,
    name character varying NOT NULL,
    description text,
    source_type character varying 
        CHECK (source_type::text = ANY (ARRAY['internal'::character varying, 'external'::character varying]::text[])),
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT training_requisition_sources_pkey PRIMARY KEY (source_id),
    CONSTRAINT training_requisition_sources_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_roles (
    role_id uuid NOT NULL DEFAULT gen_random_uuid(),
    institution_id uuid,
    name character varying NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT training_roles_pkey PRIMARY KEY (role_id),
    CONSTRAINT training_roles_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_skills (
    skill_id uuid NOT NULL DEFAULT gen_random_uuid(),
    institution_id uuid,
    name character varying NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT training_skills_pkey PRIMARY KEY (skill_id),
    CONSTRAINT training_skills_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_facilitators (
    facilitator_id uuid NOT NULL DEFAULT gen_random_uuid(),
    institution_id uuid,
    name character varying NOT NULL,
    email character varying,
    phone character varying,
    specialization text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    facilitator_type character varying 
        CHECK (facilitator_type::text = ANY (ARRAY['Interno'::character varying::text, 'Externo'::character varying::text, 'Tallerista'::character varying::text])),
    CONSTRAINT training_facilitators_pkey PRIMARY KEY (facilitator_id),
    CONSTRAINT training_facilitators_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_modules (
    module_id uuid NOT NULL DEFAULT gen_random_uuid(),
    institution_id uuid,
    axis_id uuid,
    modality_id uuid,
    source_id uuid,
    code character varying,
    name character varying NOT NULL,
    description text,
    objectives text,
    duration_hours integer,
    difficulty_level character varying 
        CHECK (difficulty_level::text = ANY (ARRAY['basic'::character varying, 'intermediate'::character varying, 'advanced'::character varying]::text[])),
    is_mandatory boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    purpose text,
    priority character varying 
        CHECK (priority::text = ANY (ARRAY['Alta'::character varying::text, 'Media'::character varying::text, 'Baja'::character varying::text])),
    evaluation_method text,
    is_certifiable boolean DEFAULT false,
    certification_type character varying,
    completion_criteria text,
    CONSTRAINT training_modules_pkey PRIMARY KEY (module_id),
    CONSTRAINT training_modules_axis_id_fkey FOREIGN KEY (axis_id) REFERENCES public.training_axes(axis_id),
    CONSTRAINT training_modules_modality_id_fkey FOREIGN KEY (modality_id) REFERENCES public.training_modalities(modality_id),
    CONSTRAINT training_modules_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.training_requisition_sources(source_id),
    CONSTRAINT training_modules_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_module_facilitators (
    module_facilitator_id uuid NOT NULL DEFAULT gen_random_uuid(),
    module_id uuid NOT NULL,
    facilitator_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    is_primary boolean DEFAULT false,
    CONSTRAINT training_module_facilitators_pkey PRIMARY KEY (module_facilitator_id),
    CONSTRAINT training_module_facilitators_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.training_modules(module_id),
    CONSTRAINT training_module_facilitators_facilitator_id_fkey FOREIGN KEY (facilitator_id) REFERENCES public.training_facilitators(facilitator_id),
    CONSTRAINT training_module_facilitators_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_module_references (
    reference_id uuid NOT NULL DEFAULT gen_random_uuid(),
    module_id uuid NOT NULL,
    title character varying NOT NULL,
    url text NOT NULL,
    description text,
    reference_type character varying,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    is_mandatory boolean DEFAULT false,
    reference_order integer DEFAULT 1,
    CONSTRAINT training_module_references_pkey PRIMARY KEY (reference_id),
    CONSTRAINT training_module_references_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.training_modules(module_id),
    CONSTRAINT training_module_references_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_module_roles (
    module_role_id uuid NOT NULL DEFAULT gen_random_uuid(),
    module_id uuid NOT NULL,
    role_id uuid NOT NULL,
    is_mandatory boolean DEFAULT true,
    default_deadline_days integer,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT training_module_roles_pkey PRIMARY KEY (module_role_id),
    CONSTRAINT training_module_roles_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.training_modules(module_id),
    CONSTRAINT training_module_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.training_roles(role_id),
    CONSTRAINT training_module_roles_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_module_skills (
    module_skill_id uuid NOT NULL DEFAULT gen_random_uuid(),
    module_id uuid NOT NULL,
    skill_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    created_by uuid,
    CONSTRAINT training_module_skills_pkey PRIMARY KEY (module_skill_id),
    CONSTRAINT training_module_skills_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.training_modules(module_id),
    CONSTRAINT training_module_skills_skill_id_fkey FOREIGN KEY (skill_id) REFERENCES public.training_skills(skill_id),
    CONSTRAINT training_module_skills_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_user_roles (
    user_role_id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    assigned_at timestamp with time zone DEFAULT now(),
    assigned_by uuid,
    CONSTRAINT training_user_roles_pkey PRIMARY KEY (user_role_id),
    CONSTRAINT training_user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
    CONSTRAINT training_user_roles_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.training_roles(role_id),
    CONSTRAINT training_user_roles_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES public.users(user_id)
);

CREATE TABLE IF NOT EXISTS public.training_user_paths (
    path_id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL,
    module_id uuid NOT NULL,
    status character varying NOT NULL DEFAULT 'pending'::character varying 
        CHECK (status::text = ANY (ARRAY['pending'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'exempted'::character varying]::text[])),
    assigned_date timestamp with time zone DEFAULT now(),
    deadline_date timestamp with time zone,
    completion_date timestamp with time zone,
    assigned_by_role_id uuid,
    is_self_requested boolean DEFAULT false,
    exemption_reason text,
    exemption_date timestamp with time zone,
    exemption_by uuid,
    progress_notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    completion_evidence text,
    evaluation_score numeric CHECK (evaluation_score IS NULL OR evaluation_score >= 0::numeric AND evaluation_score <= 100::numeric),
    evaluation_notes text,
    CONSTRAINT training_user_paths_pkey PRIMARY KEY (path_id),
    CONSTRAINT training_user_paths_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
    CONSTRAINT training_user_paths_module_id_fkey FOREIGN KEY (module_id) REFERENCES public.training_modules(module_id),
    CONSTRAINT training_user_paths_assigned_by_role_id_fkey FOREIGN KEY (assigned_by_role_id) REFERENCES public.training_roles(role_id),
    CONSTRAINT training_user_paths_exemption_by_fkey FOREIGN KEY (exemption_by) REFERENCES public.users(user_id)
);

-- ============================================================
-- FUNCIÓN PARA EJECUTAR SQL DINÁMICO (requerida para migraciones)
-- ============================================================
CREATE OR REPLACE FUNCTION public.execute_migration_sql(sql_text text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result jsonb;
BEGIN
    -- Ejecutar el SQL
    EXECUTE sql_text;
    
    -- Retornar éxito
    RETURN jsonb_build_object(
        'success', true,
        'message', 'SQL ejecutado correctamente',
        'executed_at', now()
    );
EXCEPTION WHEN OTHERS THEN
    -- Retornar error
    RETURN jsonb_build_object(
        'success', false,
        'error', SQLERRM,
        'error_detail', SQLSTATE,
        'executed_at', now()
    );
END;
$$;

-- Revocar acceso público y dar solo a service_role
REVOKE ALL ON FUNCTION public.execute_migration_sql(text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.execute_migration_sql(text) FROM anon;
REVOKE ALL ON FUNCTION public.execute_migration_sql(text) FROM authenticated;
-- Solo service_role puede ejecutar esta función (se hereda automáticamente)

COMMENT ON FUNCTION public.execute_migration_sql IS 
'Función para ejecutar SQL dinámico. Solo accesible con service_role_key. 
Usada por el sistema de migraciones de SchoolNext.';

-- ============================================================
-- FUNCIÓN PARA LISTAR TABLAS PÚBLICAS (usada por Backup)
-- ============================================================
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
'Función para obtener lista de tablas del schema public. Usada por el módulo de Backup.';

-- ============================================================
-- DATOS INICIALES: ROL SUPER ADMIN
-- ============================================================
INSERT INTO public.roles (role_name, role_description, is_super_admin, role_status)
VALUES ('Super Administrador', 'Acceso total al sistema', true, 'active')
ON CONFLICT (role_name) DO NOTHING;


-- ============================================================
-- DATOS INICIALES: USUARIO ADMIN
-- ============================================================
INSERT INTO public.users (
    user_name, 
    user_display_name, 
    user_mail, 
    user_password, 
    user_status
)
VALUES (
    'admin',
    'Administrador',
    'admin@institucion.edu.co',
    'admin123',
    'active'
)
ON CONFLICT (user_name) DO NOTHING;


-- ============================================================
-- ASIGNAR ROL SUPER ADMIN AL USUARIO ADMIN
-- ============================================================
INSERT INTO public.user_roles (user_id, role_id)
SELECT u.user_id, r.role_id
FROM public.users u, public.roles r
WHERE u.user_name = 'admin' 
AND r.role_name = 'Super Administrador'
ON CONFLICT (user_id, role_id) DO NOTHING;


-- ============================================================
-- FIN DE LA MIGRACIÓN INICIAL
-- ============================================================

-- ============================================================
-- FIN DE MIGRACIÓN 000
-- ============================================================
