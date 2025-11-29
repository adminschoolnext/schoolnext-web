# IMPLEMENTACIÓN DE MIGRACIONES EN ADMIN

## Archivos a modificar

### 1. Borra este archivo (no sirve):
```
/scripts/migration-runner.js
```

### 2. Conserva este archivo:
```
/migrations/000_initial_setup.sql
```

### 3. Modifica admin.html

Busca en `admin/admin.html` la sección de migraciones y reemplaza las funciones con el contenido de:

📄 **[ADMIN_MIGRACIONES_CODIGO.js](computer:///mnt/user-data/outputs/ADMIN_MIGRACIONES_CODIGO.js)**

---

## FLUJO DE TRABAJO

### Para clientes NUEVOS:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Crear cliente en Admin (llenar todos los campos)        │
│    - Supabase URL                                          │
│    - Supabase Anon Key                                     │
│    - Supabase Service Role Key                             │
│    - Deployment URL                                        │
├─────────────────────────────────────────────────────────────┤
│ 2. Ir al SQL Editor del Supabase del cliente               │
│    - Copiar/pegar 000_initial_setup.sql                    │
│    - Ejecutar                                              │
├─────────────────────────────────────────────────────────────┤
│ 3. Volver al Admin → Migraciones                           │
│    - Click en "Ya ejecuté la migración"                    │
│    - El cliente pasa de v0 a v1                            │
├─────────────────────────────────────────────────────────────┤
│ 4. Configurar DNS y Vercel                                 │
│    - Agregar CNAME en el proveedor de DNS                  │
│    - Agregar dominio en Vercel                             │
├─────────────────────────────────────────────────────────────┤
│ 5. El cliente puede acceder con:                           │
│    - Usuario: admin                                        │
│    - Contraseña: admin123                                  │
└─────────────────────────────────────────────────────────────┘
```

### Para migraciones FUTURAS (001, 002, etc.):

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Crear archivo /migrations/001_nombre.sql                │
├─────────────────────────────────────────────────────────────┤
│ 2. Agregar URL al objeto MIGRATION_FILES en admin.html:    │
│                                                            │
│    const MIGRATION_FILES = {                               │
│        1: 'https://raw.githubusercontent.com/.../001.sql', │
│    };                                                      │
├─────────────────────────────────────────────────────────────┤
│ 3. Incrementar CURRENT_SCHEMA_VERSION:                     │
│                                                            │
│    const CURRENT_SCHEMA_VERSION = 2; // era 1              │
├─────────────────────────────────────────────────────────────┤
│ 4. Subir cambios a GitHub                                  │
├─────────────────────────────────────────────────────────────┤
│ 5. Ir al Admin → Migraciones                               │
│    - Los clientes v1 aparecerán como "pendientes"          │
│    - Click en ▶️ para ejecutar automáticamente             │
└─────────────────────────────────────────────────────────────┘
```

---

## RESUMEN

| Migración | Ejecución | Razón |
|-----------|-----------|-------|
| `000_initial_setup.sql` | **MANUAL** (SQL Editor) | Crea la función `execute_migration_sql` |
| `001_xxx.sql` | **AUTOMÁTICA** (botón Admin) | Usa la función que ya existe |
| `002_xxx.sql` | **AUTOMÁTICA** (botón Admin) | Usa la función que ya existe |
| ... | **AUTOMÁTICA** | ... |

---

## IMPORTANTE

- La migración 000 **siempre** es manual porque crea la infraestructura necesaria
- Las migraciones 001+ son automáticas gracias a la función `execute_migration_sql`
- Necesitas `service_role_key` para las migraciones automáticas
- Sin `service_role_key`, solo puedes ejecutar manualmente
