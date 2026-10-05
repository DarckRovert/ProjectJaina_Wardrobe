--  Filtro.lua  ·  EL MENU DE FILTRO Y EL DE ORDENAR   ·   04-09-2026
-- ============================================================================
--  🔴 POR QUE EXISTE, Y POR QUE ES UNA COPIA DE ASCENSION Y NO UNA IDEA MIA.
--
--  Primero se filtro la rejilla A LA FUERZA -- solo lo usable por tu clase y
--  solo lo coleccionado-- y el dueno lo corrigio dos veces:
--
--      *«muestrame solamente lo que puedo usar... en Ascension habia filtros»*
--      *«me has puesto un filtro demasiado agresivo y basico... ellos lo
--        tienen bastante bien cuidado y funcional. No quiero que me inventes
--        cosas, quiero que lo hagas como ellos lo tienen»*
--
--  Asi que se saco su addon del cliente y se leyo:
--  `Interface\AddOns\Ascension_AppearanceUI\AppearanceCollectionMixin.lua`,
--  funcion `CreateFilters()`. Esto es lo que hay ahi, tal cual.
--
--  🔑 LO QUE ENSENA SU CODIGO, Y QUE NO SE HABRIA ADIVINADO:
--
--   1. **NO tienen un filtro «solo lo que puedo usar»**. Eso me lo invente.
--      Ellos filtran por TIPO -tela, cuero, malla, placas, hacha, daga...- y
--      es el jugador quien elige. Mucho mas flexible: un mago puede querer
--      mirar placas para un conjunto de otro personaje.
--
--   2. **Cada opcion solo aparece si tiene sentido en la categoria que miras.**
--      No enseñan «Tela» cuando estas viendo armas. Ese detalle es la mitad de
--      lo que hace que su menu no abrume: la lista es larga, pero nunca la ves
--      entera.
--
--   3. **El de ordenar es de UNA sola opcion** (`SetSingleOptionMode(true)`),
--      y el de filtrar de varias. Son dos comportamientos distintos.
--
--    🎯 La regla del proyecto que aqui se salto y costo dos vueltas: mirar su
--       cliente ANTES de construir, no cuando algo falla.
-- ============================================================================

local PLARM = PLARM

--  🪤 `PLARM.Color` NO SE LEE EN LA CABECERA.
--
--  Los .lua de un addon se cargan en el orden del .toc y **el cuerpo del
--  archivo se ejecuta al cargarlo**: si aqui arriba se hace `local c =
--  PLARM.Color`, se guarda el nil de ese instante y todo lo que use `c`
--  revienta con «attempt to index upvalue 'c'». Paso al anadir este archivo:
--  dejo el armario sin abrir.
--
--  Es la misma trampa que los `SavedVariables` (79 §23): lo que viene de
--  fuera se lee CUANDO SE USA, no al cargar.
local function Col() return PLARM.color end

--  Los bits que entiende el servidor (armario-catalogo.lua). Se escriben aqui
--  una sola vez: si se anade uno, va en los dos sitios.
--  🔑 ESTOS BITS YA EXISTIAN EN EL SERVIDOR, con `PasaFlags` entero escrito:
--  tengo/no tengo, rareza, como se consigue y tipo. Lo unico que faltaba era
--  la interfaz para usarlos.
--
--    🎯 Antes de escribir un filtro nuevo, mira si el servidor ya sabe
--       filtrar. Aqui sabia, y estuve a punto de inventar bits nuevos.
local F = {
    COLECCIONADO   = 1,      -- F_TENGO
    SIN_COLECCIONAR= 2,      -- F_NO_TENGO
    --  🔴 LAS CUATRO RAREZAS SON LAS NUESTRAS, NO LAS DE WOW.
    --  Aqui se pusieron «Normal / Poco comun / Raro / Epico», que son las de
    --  Blizzard, y las nuestras estaban escritas desde hace dias en
    --  `Estilo.lua` -> `PLARM.RAREZAS`: Comun, Raro, Epico y Legendario.
    --  El dueno lo vio en la primera captura del menu.
    --
    --    🎯 Si una lista ya existe en el proyecto, se LEE; no se vuelve a
    --       escribir de memoria. Dos listas que dicen lo mismo acaban
    --       diciendo cosas distintas.
    Q_COMUN        = 32,
    Q_RARO         = 64,
    Q_EPICO        = 128,
    Q_LEGENDARIO   = 256,
    --  tipo de armadura
    TELA           = 512,
    CUERO          = 1024,
    MALLA          = 2048,
    PLACAS         = 4096,
    ESCUDO         = 8192,
    --  tipo de arma
    ARMA_1M        = 16384,
    ARMA_2M        = 32768,
    DISTANCIA      = 65536,
    --  Transfigurar (02-10-2026): por defecto solo lo de tu clase; esta
    --  casilla ensena tambien lo de las demas (F_TODAS_CLASES del servidor).
    TODAS_CLASES   = 1048576,
}

--  🔑 QUE OPCIONES SE VEN EN CADA CATEGORIA, que es el detalle que hace util
--  su menu. `cat` es la ranura que se esta mirando; nil = conjuntos.
local ARMAS   = { [15] = true, [16] = true, [17] = true }
local ARMADURA= { [0]=true, [2]=true, [4]=true, [5]=true, [6]=true,
                  [7]=true, [8]=true, [9]=true, [14]=true, [15]=true }

--  🪤 30-09-2026: la seccion Conjuntos manda cat = 100 (y la Tienda 102), no
--     nil, asi que «Tela/Cuero/Malla/Placas» no salian NUNCA en Conjuntos y el
--     menu acababa en un «TIPO» sin nada debajo. El servidor si sabe filtrar
--     conjuntos por armadura (armario-catalogo.lua, «tipo de armadura»).
local CONJUNTOS = { [100] = true, [102] = true }
local function esArma(cat)     return cat and ARMAS[cat] end
local function esArmadura(cat) return not cat or ARMADURA[cat] or CONJUNTOS[cat] end

--  La lista, en el mismo orden que la suya: primero coleccion, luego calidad,
--  luego tipo.
local function esTransfigurar(cat) return cat and cat >= 200 end
local function noTransfigurar(cat) return not esTransfigurar(cat) end
local OPCIONES = {
    { bit = F.TODAS_CLASES,    texto = "Ver todas las clases", cuando = esTransfigurar },
    { bit = F.COLECCIONADO,    texto = "Coleccionado",    cuando = noTransfigurar },
    { bit = F.SIN_COLECCIONAR, texto = "Sin coleccionar", cuando = noTransfigurar },
    { sep = true },
    { titulo = "Rareza" },
    --  Nombres y colores tomados de `PLARM.RAREZAS`, que es donde viven.
    { bit = F.Q_COMUN,      texto = "Comun",      rareza = 1 },
    { bit = F.Q_RARO,       texto = "Raro",       rareza = 2 },
    { bit = F.Q_EPICO,      texto = "Epico",      rareza = 3 },
    { bit = F.Q_LEGENDARIO, texto = "Legendario", rareza = 4 },
    --  El titulo «Tipo» solo si debajo sale alguna opcion (en Guardados no).
    { sep = true,      cuando = function(c) return esArmadura(c) or esArma(c) end },
    { titulo = "Tipo", cuando = function(c) return esArmadura(c) or esArma(c) end },
    { bit = F.TELA,      texto = "Tela",    cuando = esArmadura },
    { bit = F.CUERO,     texto = "Cuero",   cuando = esArmadura },
    { bit = F.MALLA,     texto = "Malla",   cuando = esArmadura },
    { bit = F.PLACAS,    texto = "Placas",  cuando = esArmadura },
    { bit = F.ESCUDO,    texto = "Escudo",  cuando = function(c) return esArmadura(c) and not CONJUNTOS[c] end },
    { bit = F.ARMA_1M,   texto = "Una mano",     cuando = esArma },
    { bit = F.ARMA_2M,   texto = "Dos manos",    cuando = esArma },
    { bit = F.DISTANCIA, texto = "A distancia",  cuando = esArma },
}

--  El de ordenar es de UNA opcion, como el suyo.
local ORDENES = {
    { valor = 0, texto = "Conseguido recientemente" },
    { valor = 1, texto = "Conseguido hace mas tiempo" },
    { sep = true },
    { valor = 2, texto = "Nombre  A - Z" },
    { valor = 3, texto = "Nombre  Z - A" },
    { sep = true },
    { valor = 4, texto = "Rareza  mayor primero" },
    { valor = 5, texto = "Rareza  menor primero" },
}

--  Suma y resta de bits sin `bit`, que en 3.3.5a no siempre esta.
local function tiene(flags, b) return flags % (b * 2) >= b end
local function poner(flags, b, si)
    if si and not tiene(flags, b) then return flags + b end
    if not si and tiene(flags, b) then return flags - b end
    return flags
end
PLARM.FiltroTiene = tiene

-- ---------------------------------------------------------------------------
--- Crea el par de botones y sus menus. `alCambiar` se llama al tocar algo.
--- `dameCat` devuelve la ranura que se esta mirando, para esconder lo que no
--- toca -- es la parte que hace util el menu, no un adorno.
-- ---------------------------------------------------------------------------
function PLARM.CrearFiltros(padre, estado, alCambiar, dameCat)
    local menus = {}

    local function CerrarOtros(salvo)
        for _, m in ipairs(menus) do
            if m ~= salvo then m:Hide() end
        end
    end

    -- ------------------------------------------------------------- filtro
    local btnFiltro = PLARM.Boton(padre, "Filtro", 64, 20)
    local menuF = CreateFrame("Frame", nil, padre)
    menuF:SetFrameStrata("DIALOG")
    PLARM.Fondo(menuF, Col().fondo, 0.98)
    PLARM.Borde(menuF, Col().oro, 1)
    menuF:Hide()
    menus[#menus + 1] = menuF

    local filas = {}
    for i, o in ipairs(OPCIONES) do
        local f = {}
        if o.sep then
            f.linea = menuF:CreateTexture(nil, "ARTWORK")
            f.linea:SetHeight(1)
            f.linea:SetTexture(unpack(Col().borde))
        elseif o.titulo then
            f.texto = PLARM.Texto(menuF, 10, Col().oro, true)
            f.texto:SetText(o.titulo:upper())
        else
            f.caja = CreateFrame("CheckButton", nil, menuF, "UICheckButtonTemplate")
            f.caja:SetSize(20, 20)
            --  El color sale de la tabla de rarezas del propio addon.
            local col = o.color
            if o.rareza and PLARM.RAREZAS[o.rareza] then
                col = PLARM.RAREZAS[o.rareza].color
            end
            f.texto = PLARM.Texto(menuF, 11, col or Col().texto)
            f.texto:SetText(o.texto)
            f.caja:SetScript("OnClick", function(s)
                estado.flags = poner(estado.flags or 0, o.bit, s:GetChecked())
                alCambiar()
            end)
        end
        f.op = o
        filas[i] = f
    end

    --  Se recolocan cada vez que se abre: las que no tocan se esconden y las
    --  demas suben, para que no queden huecos.
    local function Recolocar()
        local cat = dameCat and dameCat() or nil
        local y, ancho = -8, 176
        for _, f in ipairs(filas) do
            local ver = (not f.op.cuando) or f.op.cuando(cat)
            if f.caja then PLARM.Ver(f.caja, ver) end
            if f.texto then PLARM.Ver(f.texto, ver) end
            if f.linea then PLARM.Ver(f.linea, ver) end
            if ver then
                if f.linea then
                    f.linea:ClearAllPoints()
                    f.linea:SetPoint("TOPLEFT", 8, y - 3)
                    f.linea:SetPoint("TOPRIGHT", -8, y - 3)
                    y = y - 9
                elseif f.caja then
                    f.caja:ClearAllPoints()
                    f.caja:SetPoint("TOPLEFT", 6, y)
                    f.texto:ClearAllPoints()
                    f.texto:SetPoint("LEFT", f.caja, "RIGHT", 1, 0)
                    f.caja:SetChecked(tiene(estado.flags or 0, f.op.bit))
                    y = y - 22
                else
                    f.texto:ClearAllPoints()
                    f.texto:SetPoint("TOPLEFT", 10, y - 2)
                    y = y - 18
                end
            end
        end
        menuF:SetSize(ancho, -y + 6)
    end

    btnFiltro:SetScript("OnClick", function()
        if menuF:IsShown() then menuF:Hide() return end
        CerrarOtros(menuF)
        Recolocar()
        menuF:Show()
    end)

    -- ------------------------------------------------------------ ordenar
    local btnOrden = PLARM.Boton(padre, "Ordenar", 68, 20)
    local menuO = CreateFrame("Frame", nil, padre)
    menuO:SetFrameStrata("DIALOG")
    PLARM.Fondo(menuO, Col().fondo, 0.98)
    PLARM.Borde(menuO, Col().oro, 1)
    menuO:Hide()
    menus[#menus + 1] = menuO

    local marcas, y = {}, -8
    for _, o in ipairs(ORDENES) do
        if o.sep then
            local l = menuO:CreateTexture(nil, "ARTWORK")
            l:SetHeight(1)
            l:SetTexture(unpack(Col().borde))
            l:SetPoint("TOPLEFT", 8, y - 3)
            l:SetPoint("TOPRIGHT", -8, y - 3)
            y = y - 9
        else
            local b = CreateFrame("Button", nil, menuO)
            b:SetSize(196, 20)
            b:SetPoint("TOPLEFT", 4, y)
            local marca = PLARM.Texto(b, 12, Col().oroClaro)
            marca:SetPoint("LEFT", 6, 0)
            local et = PLARM.Texto(b, 11, Col().texto)
            et:SetPoint("LEFT", 20, 0)
            et:SetText(o.texto)
            b.marca, b.valor = marca, o.valor
            b:SetScript("OnClick", function()
                estado.orden = o.valor
                for _, m in ipairs(marcas) do
                    m.marca:SetText(m.valor == o.valor and "•" or "")
                end
                menuO:Hide()
                alCambiar()
            end)
            marcas[#marcas + 1] = b
            y = y - 22
        end
    end
    menuO:SetSize(204, -y + 6)

    btnOrden:SetScript("OnClick", function()
        if menuO:IsShown() then menuO:Hide() return end
        CerrarOtros(menuO)
        for _, m in ipairs(marcas) do
            m.marca:SetText(m.valor == (estado.orden or 0) and "•" or "")
        end
        menuO:Show()
    end)

    --  🔬 Para poder probarlos por SSH, sin raton.
    PLARM._menuFiltro, PLARM._menuOrden = menuF, menuO
    PLARM._filasFiltro, PLARM._filasOrden = filas, marcas

    return btnFiltro, btnOrden, menuF, menuO
end
