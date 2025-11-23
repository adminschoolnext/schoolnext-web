// ==========================================
// CONFIGURACIÓN DE SUPABASE
// ==========================================

// Nota: En producción, estas variables vienen de Vercel Environment Variables
const SUPABASE_CONFIG = {
    url: typeof window !== 'undefined' && window.location.hostname === 'localhost' 
        ? 'https://rqteyrmguczrjiaqxppu.supabase.co'  // Reemplaza con tu URL
        : 'https://rqteyrmguczrjiaqxppu.supabase.co',  // Reemplaza con tu URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxdGV5cm1ndWN6cmppYXF4cHB1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5MzczNDcsImV4cCI6MjA3OTUxMzM0N30.ApTukbdfmhl2qVFpGJNC-sLeLTocEneRbZK0has0syI'  // Reemplaza con tu anon key completa
};

// ==========================================
// CARGAR CONFIGURACIÓN DEL SITIO
// ==========================================

async function loadSiteConfig() {
    try {
        const response = await fetch(
            `${SUPABASE_CONFIG.url}/rest/v1/config?select=*&limit=1`,
            {
                method: 'GET',
                headers: {
                    'apikey': SUPABASE_CONFIG.anonKey,
                    'Authorization': `Bearer ${SUPABASE_CONFIG.anonKey}`,
                    'Content-Type': 'application/json',
                    'Prefer': 'return=representation'
                }
            }
        );
        
        if (!response.ok) {
            const errorText = await response.text();
            throw new Error(`HTTP ${response.status}: ${errorText}`);
        }
        
        const data = await response.json();
        
        if (data && data.length > 0) {
            console.log('✅ Configuración cargada:', data[0]);
            return data[0];
        }
    } catch (error) {
        console.error('❌ Error cargando site_config:', error);
    }
    
    // Valores por defecto si falla
    return {
        site_name: 'SchoolNext',
        primary_color: '#667eea',
        secondary_color: '#764ba2',
        tertiary_color: '#764ba2',
        hero_title: 'Sistema de Gestión Educativa en la Nube',
        hero_subtitle: 'La solución completa para la administración moderna de instituciones educativas'
    };
}

// ==========================================
// APLICAR COLORES DINÁMICOS
// ==========================================

async function applySiteConfig() {
    const config = await loadSiteConfig();
    
    // Aplicar colores CSS
    document.documentElement.style.setProperty('--primary-color', config.primary_color);
    document.documentElement.style.setProperty('--secondary-color', config.secondary_color);
    document.documentElement.style.setProperty('--tertiary-color', config.tertiary_color || config.secondary_color);
    
    // Actualizar título del sitio
    if (config.site_name) {
        const currentTitle = document.title;
        const parts = currentTitle.split(' - ');
        if (parts.length > 1) {
            document.title = config.site_name + ' - ' + parts[1];
        } else {
            document.title = config.site_name;
        }
    }
    
    console.log('✅ Configuración aplicada:', config);
    
    return config;
}

// ==========================================
// INICIALIZAR AL CARGAR LA PÁGINA
// ==========================================

if (typeof document !== 'undefined') {
    document.addEventListener('DOMContentLoaded', async () => {
        await applySiteConfig();
    });
}
