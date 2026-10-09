# 🔌 Especificación Técnica y API — Wanos_Wardrobe

[![GitHub](https://img.shields.io/badge/GitHub-DarckRovert%2FWanos_Wardrobe-black?logo=github)](https://github.com/DarckRovert/Wanos_Wardrobe)
[![Ecosistema](https://img.shields.io/badge/Ecosistema-WoW%20Per%C3%BA%203.3.5a-gold.svg)](https://projectjaina.com/)

## 📌 Resumen Arquitectónico
Suite completa de guardarropa y transfiguración visual con renderizado 3D escalonado a 0.01s por fotograma, sincronización autoritativa con backend Eluna y almacenamiento en MySQL.

- **Rol en el Ecosistema:** Módulo Oficial #15 — Guardarropa & Transfiguración
- **Archivo Principal TOC:** `Wanos_Wardrobe.toc`
- **Compatibilidad del Motor:** World of Warcraft 3.3.5a (Build 12340)

---

## ⌨️ Comandos de Consola (Slash Commands)
- `/armario`: Acceso principal o comando del addon.
- `/guardarropa`: Acceso principal o comando del addon.
- `/wardrobe`: Acceso principal o comando del addon.
- `/armariodiag`: Acceso principal o comando del addon.

---

## 📡 Protocolo de Red y Eventos
- `WP_WARDROBE`: Prefijo registrado para sincronización de datos.

### Eventos del Motor 3.3.5a Gestionados
- `PLAYER_LOGIN` / `ADDON_LOADED`: Inicialización atómica de tablas de configuración y hooks.
- `PLAYER_ENTERING_WORLD`: Sincronización de estado tras transiciones de pantalla o mapa.
- `PLAYER_LOGOUT`: Guardado seguro en disco de las variables locales.

---

## 💾 Persistencia de Datos (SavedVariables)
- `Wanos_Wardrobe_Ajustes`: Almacenamiento estructurado de configuración y estado persistente.
- `Wanos_Wardrobe_Cache`: Almacenamiento estructurado de configuración y estado persistente.
- `Wanos_Wardrobe_Registro`: Almacenamiento estructurado de configuración y estado persistente.

---

## 🛠️ Buenas Prácticas de Integración
1. Toda invocación a funciones públicas debe verificar previamente la existencia del espacio de nombres en `_G`.
2. Las tablas de configuración deben consultarse en modo lectura sin sobreescribir valores por omisión no validados.
3. El intercambio de datos con otros addons debe efectuarse a través del bus oficial `Wanos_Companion` o hooks de eventos estándar.
