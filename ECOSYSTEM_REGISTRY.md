# 🌐 Registro de Ecosistema — WoWPeru_Wardrobe

Ficha técnica oficial de registro en la infraestructura multi-addon de **WoW Perú - Reino Andino**.

---

## 1. Identidad del Addon

| Campo | Valor |
|---|---|
| **Nombre Técnico** | `WoWPeru_Wardrobe` |
| **Título en Cliente** | `|cFFD4AF37WoW Perú|r - Guardarropa & Transfiguración` |
| **Versión** | `1.0.0` |
| **Tipo de Sistema** | Guardarropa, Catálogo Cosmético y Transfiguración Visual |
| **Repositorio GitHub** | [DarckRovert/WoWPeru_Wardrobe](https://github.com/DarckRovert/WoWPeru_Wardrobe) |
| **Directorio de Instalación** | `Interface\AddOns\WoWPeru_Wardrobe\` |

---

## 2. Red y Mensajería de Addon

| Propiedad | Valor |
|---|---|
| **Prefijo Oficial** | `WP_WARDROBE` |
| **Canales de Red** | `WHISPER` (a sí mismo / servidor) |
| **OpCodes Manejados** | `REQ_CATALOG`, `REQ_APPLY`, `REQ_UNLOCK`, `RES_CATALOG`, `RES_APPLY`, `RES_UNLOCK` |
| **Presupuesto Máximo** | < 220 bytes (Límite protocolo WoW: 255 bytes) |
| **Transporte Seguro** | Paginación por lotes de 20 ítems con control de secuencia |

---

## 3. Persistencia de Datos

| Variable Global | Tipo | Ámbito | Propósito |
|---|---|---|---|
| `WoWPeru_Wardrobe_Cache` | Tabla Lua (`SavedVariables`) | Por Cuenta | Almacena caché local de nombres de apariencias |
| `WoWPeru_Wardrobe_Registro` | Tabla Lua (`SavedVariables`) | Por Cuenta | Buffer de diagnóstico local pasivo (máx. 80 entradas) |
| `WoWPeru_Wardrobe_Ajustes` | Tabla Lua (`SavedVariablesPerCharacter`) | Por Personaje | Guarda preferencias de visualización del jugador |

---

## 4. Matriz de Integración del Ecosistema

| Sistema Coexistente | Modo de Interacción | Flujo de Datos |
|---|---|---|
| **`WoWPeru_Companion`** | Telemetría / Detección P2P | Registrado en lista de presencia social de addons activos |
| **`WowPeruVisualShop`** | Coexistencia Armónica | `/tienda` reservado para tienda visual; `/armario` para transfiguración |
| **`AzerothCore (Eluna)`** | Cliente - Servidor Autoritativo | Backend `60_WardrobeSystem.lua` y tabla MySQL `character_transmog_collection` |
| **`PaperDollFrame (Blizzard)`** | Hook No Destructivo | Intercepta visualización sin alterar stats ni tooltips reales |

---

## 5. Garantías de Rendimiento

- **Tiempo de Cuadro:** < 0.02 ms por fotograma (renderizado escalonado a 0.01s por modelo).
- **Consumo de Memoria:** ~ 1.8 MB (incluyendo texturas TGA y caché de colecciones).
- **Compatibilidad de Hardware:** 100% verificado para PCs de cabina con procesadores Dual-Core y gráficos integrados Intel HD.
