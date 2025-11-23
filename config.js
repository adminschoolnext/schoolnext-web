// ==========================================
// CONFIGURACIÓN DE SUPABASE
// ==========================================

const SUPABASE_CONFIG = {
    url: 'https://tateyrmgucrzjiaqxpbu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJxdGV5cm1ndWN6cmppYXF4cHB1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM5MzczNDcsImV4cCI6MjA3OTUxMzM0N30.ApTukbdfmhl2qVFpGJNC-sLeLTocEneRbZK0has0syI' // Reemplaza con tu anon key completa
};

// ==========================================
// CARGAR CONFIGURACIÓN DEL SITIO
// ==========================================

async function loadSiteConfig() {
    try {
        const response = await fetch(
            `${SUPABASE_CONFIG.url}/rest/v1/config?select=*&limit=1`,
            {
                headers: {
                    'apikey': SUPABASE_CONFIG.anonKey,
                    'Authorization': `Bearer ${SUPABASE_CONFIG.anonKey}`
                }
            }
        );
        
        if (!response.ok) {
            throw new Error('Error cargando configuración');
        }
        
        const data = await response.json();
        
        if (data && data.length > 0) {
            return data[0];
        }
    } catch (error) {
        console.error('Error cargando site_config:', error);
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
    document.documentElement.style.setProperty('--tertiary-color', config.tertiary_color);
    
    // Actualizar título del sitio
    if (config.site_name) {
        document.title = config.site_name + ' - ' + document.title.split(' - ')[1] || config.site_name;
    }
    
    return config;
}

// ==========================================
// INICIALIZAR AL CARGAR LA PÁGINA
// ==========================================

document.addEventListener('DOMContentLoaded', async () => {
    await applySiteConfig();
});
