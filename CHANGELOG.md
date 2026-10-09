# 📜 Registro de Cambios — Wanos_Wardrobe

Todas las modificaciones notables de este proyecto están documentadas en este archivo según el estándar [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/) y siguen las directrices de [Versionado Semántico](https://semver.org/lang/es/).

---

## [1.0.0] - 2026-10-05

### Añadido
- **Módulo Oficial #15:** Integración formal de `Wanos_Wardrobe` en el ecosistema oficial de Project Jaina.
- **Renderizado 3D Escalonado:** Algoritmo en `Ficha.lua` de 1 modelo por fotograma cada 0.01s con cola de descarte atómica al pasar de página.
- **Hook Seguro en Hoja de Personaje:** Soporte en `FichaPersonaje.lua` para no alterar stats ni tooltips del equipo equipado.
- **Comandos Slash Oficiales:** Registro de `/armario`, `/wardrobe`, `/guardarropa` y `/arm`.
- **Backend Eluna y Esquema MySQL:** Script `60_WardrobeSystem.lua` y migración `transmog_collection.sql` para validación autoritativa en el servidor.
- **Ficha Técnica:** `ECOSYSTEM_REGISTRY.md` con especificación de protocolo `WP_WARDROBE`.
- **Marco Legal y Atribución:** Inclusión de `NOTICE.md` y `LICENSE` reconociendo los aportes de PeruLand y Ascension WoW.

### Modificado
- **Sanitización de Red:** Migración completa de prefijo `PLARMARIO` a `WP_WARDROBE`.
- **Rebranding y Rutas:** Estandarización de rutas de texturas a `Interface\AddOns\ProjectJaina_Wardrobe\arte\`.
- **Fondo Base Defensivo:** Incorporación de marco liso oscuro y borde dorado en `Ventana.lua` para garantizar renderizado perfecto sin depender de MPQs externos.

### Eliminado
- **Erradicación de Telemetría:** Eliminación total de la sobreescritura `seterrorhandler` en `Registro.lua` que interceptaba errores ajenos del cliente.
- **Supresión de Enlaces Externos:** Purgadas todas las URLs ajenas a Project Jaina.
- **Desacoplamiento de DLLs:** Supresión de dependencias duras de funciones nativas de C++ inyectadas en cliente.
