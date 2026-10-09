# 📜 Aviso Legal y Atribución — ProjectJaina_Wardrobe

Este proyecto incorpora código, conceptos arquitectónicos y recursos de múltiples fuentes de la comunidad de emulación y desarrollo de World of Warcraft:

---

## 1. Arquitectura Base y Localización
- **Proyecto Origen:** PeruLand Armario
- **Autoría Base:** Equipo de Desarrollo de PeruLand
- **Aportes Asimilados:** Renderizado escalonado por fotogramas a 0.01s (`Ficha.lua`), desacoplamiento visual en hoja de personaje (`FichaPersonaje.lua`) y texturas de interfaz.

---

## 2. Plantillas de Colección y Concepto Visual
- **Proyecto de Inspiración:** Ascension WoW (`AwAddons` / `VanityCollection`)
- **Autoría Original:** Ascension WoW Development Team
- **Aportes Asimilados:** Concepto de previsualización 3D mediante `DressUpModel` y navegación temática por categorías.

---

## 3. Re-ingeniería, Hardening y Gobernanza (Project Jaina)
- **Mantenimiento y Adaptación:** DarckRovert & Project Jaina Engineering Team
- **Servidor y Ecosistema:** [Project Jaina — Project Jaina](https://darckrovert.github.io/ProjectJaina_Web/)
- **Transformaciones Arquitectónicas Implementadas:**
  1. Erradicación total del secuestro global de errores (`seterrorhandler` en `Registro.lua`).
  2. Supresión de telemetría y transmisiones masivas de logs por canales de chat.
  3. Eliminación de dependencias de librerías DLL inyectadas en cliente (`PeruLand.dll`).
  4. Sustitución de dominios y URLs externas por la infraestructura oficial de Project Jaina.
  5. Creación del backend autoritativo en Eluna (`60_WardrobeSystem.lua`) y persistencia en MySQL (`character_transmog_collection`).
  6. Estandarización de protocolos de red bajo el prefijo unificado `WP_WARDROBE`.
