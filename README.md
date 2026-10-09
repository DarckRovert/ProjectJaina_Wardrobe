# 🇵🇪 Project Jaina — Guardarropa & Transfiguración (v1.0.0)

**Versión:** 1.0.0 (WotLK 3.3.5a Staggered Render Edition)  
**Autor:** DarckRovert & Project Jaina Team  
**Servidor Destino:** [Project Jaina](https://worldofwanos.com/) — Project Jaina  
**Entorno de Ejecución:** World of Warcraft 3.3.5a (Build 12340) | Lua 5.1 / Eluna C++  
**Repositorio Oficial:** [DarckRovert/Wanos_Wardrobe](https://github.com/DarckRovert/Wanos_Wardrobe)

---

[![WoW Client](https://img.shields.io/badge/WoW%20Client-3.3.5a%20(Build%2012340)-blue.svg)](https://worldofwanos.com/)
[![Servidor](https://img.shields.io/badge/Servidor-WoW%20Perú-gold.svg)](https://worldofwanos.com/)
[![Version](https://img.shields.io/badge/version-1.0.0-brightgreen.svg)](https://github.com/DarckRovert/Wanos_Wardrobe/releases)
[![Build Status](https://img.shields.io/badge/CI-Passing-success.svg)](https://github.com/DarckRovert/Wanos_Wardrobe/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 🌟 ¿Qué es Wanos_Wardrobe?

**Wanos_Wardrobe** es el **módulo oficial #15** del ecosistema de addons de **Project Jaina - Project Jaina**. Proporciona una interfaz moderna, inmersiva y de alto rendimiento para la colección y transfiguración de apariencias visuales en el cliente World of Warcraft 3.3.5a (Wrath of the Lich King).

Inspirado en interfaces de guardarropa avanzadas y optimizado específicamente para el motor 3.3.5a, este addon ha sido completamente **sanitizado, re-ingenierizado y protegido contra fallos de concurrencia y congelamiento de FPS**.

```
┌────────────────────────────────────────────────────────────────────────┐
│               ARQUITECTURA DE GUARDARROPA Y TRANSFIGURACIÓN            │
├────────────────────────┬──────────────────────┬────────────────────────┤
│ ⏱️ RENDER ESCALONADO   │ 🛡️ HOJA DE PERSONAJE │ 🗄️ BACKEND ELUNA       │
│ 1 modelo por frame a   │ Hook no destructivo  │ Autoridad en servidor, │
│ 0.01s (Cero freezes    │ en PaperDollFrame    │ persistencia MySQL     │
│ en PCs de cabina)      │ (stats reales)       │ y red WP_WARDROBE      │
└────────────────────────┴──────────────────────┴────────────────────────┘
```

---

## 🚀 Funcionalidades Principales

### 1. ⏱️ Renderizado 3D Escalonado (Staggered Model Loading)
- Renderiza los modelos 3D (`DressUpModel`) a un ritmo controlado de **1 modelo por fotograma cada 0.01 segundos**.
- **Cero Bloqueos de Pantalla:** Elimina el micro-congelamiento del cliente al abrir páginas con 12 o 18 modelos simultáneos.
- **Cancelación Atómica:** Al pasar de página rápidamente o cerrar la ventana, la cola anterior se vacía instantáneamente para no malgastar memoria ni ciclos de CPU.

### 2. 🛡️ Protección de la Hoja de Personaje (`PaperDollFrame`)
- Intercepta suavemente la visualización en la ficha del personaje (`C`) sin alterar las texturas, tooltips ni atributos reales del equipo equipado.
- El jugador puede probarse cualquier atuendo en el guardarropa sin que sus estadísticas o visualización de combate se desvirtúen.

### 3. 🗄️ Backend Autoritativo en Eluna & MySQL
- Respaldado en el servidor por el script [`60_WardrobeSystem.lua`](file:///E:/AzerothCore/server/lua_scripts/60_WardrobeSystem.lua) y la tabla `character_transmog_collection` en la base de datos `acore_characters`.
- Validación estricta de propiedad de la apariencia antes de aplicar cualquier cambio visual.
- Soporte para cobro dual: Oro nativo o Tokens Andinos oficiales.

### 4. 🔒 100% Libre de Telemetría Invasiva y Libre de Taint
- Se erradicó por completo el secuestro global de errores (`seterrorhandler`), protegiendo la estabilidad de todos los demás addons instalados.
- Libre de llamadas a extensiones DLL externas.
- Todos los paquetes de red viajan encapsulados bajo el prefijo oficial `WP_WARDROBE`.

---

## 💻 Comandos de Barra (Slash Commands)

| Comando | Acción |
|---|---|
| `/armario` | Abre o cierra la ventana principal del Guardarropa. |
| `/wardrobe` | Alias internacional en inglés para abrir el Guardarropa. |
| `/guardarropa` | Alias alternativo en español. |
| `/arm` | Abreviatura rápida de apertura. |
| `/armario diag` | Muestra el estado del registro interno de diagnóstico local. |

---

## 📊 Especificaciones Técnicas

| Métrica | Parámetro Oficial |
|---|---|
| **Prefijo de Red** | `WP_WARDROBE` |
| **Tiempo de Cuadro (Frame Time)** | < 0.02 ms por fotograma |
| **Memoria en Ejecución** | ~ 1.8 MB (incluyendo texturas y caché de catálogo) |
| **Compatibilidad** | Intel HD Graphics, PCs de cabina con procesadores Dual-Core |
| **Persistencia Servidor** | MySQL tabla `character_transmog_collection` |

---

## 📥 Instalación en el Cliente WoW

1. Asegúrate de que la carpeta `Wanos_Wardrobe` se encuentre dentro de:
   ```
   World of Warcraft/Interface/AddOns/Wanos_Wardrobe/
   ```
2. Inicia el cliente de juego Project Jaina y verifica que el addon esté marcado en la lista de accesorios del personaje.
3. Dentro del juego, escribe `/armario` o `/wardrobe` para abrir la interfaz.

---

## 📜 Licencia y Atribución

Distribuido bajo la licencia [MIT](LICENSE).  
Para consultar los detalles de autoría, genealogía y componentes de terceros, consulta el archivo [NOTICE.md](NOTICE.md).
