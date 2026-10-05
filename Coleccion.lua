-- ============================================================================
--  LA COLECCION   ·   01-09-2026
-- ============================================================================
--  La rejilla, las pestanas, las ranuras, el buscador y la paginacion.
--
--  🔴 ESTE ARCHIVO NO TIENE NI UNA VARIABLE DE PAGINA NI DE FILTRO.
--
--  Ese es el arreglo de fondo. La pagina en la que estas, el filtro que
--  pusiste y la lista que sale viven en el SERVIDOR, y aqui se leen de
--  `PLARM.Contrato.Estado`. Antes habia tres trozos de codigo escribiendo el
--  numero de pagina y ninguno sabia de los otros: por eso al pulsar un
--  conjunto la paginacion se quedaba bloqueada y la etiqueta decia otra cosa.
--
--    🎯 Un dato, un dueno. Si esta pantalla necesita saber en que pagina
--       esta, PREGUNTA; no lo apunta.
--
--  🔑 Y EL LLENADO VA ESCALONADO, una ficha por fotograma, como su
--  `InternalUpdateAppearances`. Es lo que hace que 18 munecos 3D no den un
--  tiron. La cola se cancela entera al cambiar de pagina.
-- ============================================================================

PLARM = PLARM or {}
PLARM.Coleccion = {}

local c = PLARM.color
local E = nil        -- el estado del contrato; se toma al crear

--  🎨 GALERIA: 5 x 2 tarjetas grandes con fondo (el servidor pagina de 10:
--     `M.POR_PAGINA` en lua_scripts/armario-catalogo.lua, van juntos).
local COLS, FILAS = 5, 2
local HUECO = PLARM.MX(16)

--  Las cuatro secciones. Son los `appearanceType` de Ascension, con los
--  nuestros: piezas sueltas, conjuntos, atuendos guardados y tienda.
--  Las cuatro secciones. Son los `appearanceType` de Ascension, con los
--  nuestros: piezas sueltas, conjuntos, atuendos guardados y tienda.
--
--  🪤 LAS ARMAS VAN DENTRO DE «PIEZAS», no en pestana propia. Se probo darles
--  una y el dueno lo corto: un arma es una pieza mas -- la ranura se elige en
--  la fila de iconos, igual que cabeza o botas. Una pestana por tipo de pieza
--  acabaria en diez pestanas.
--
--  Lo que si hacia falta era que la fila de ranuras se VEA y que pulsar una
--  pieza haga algo, que es lo que fallaba de verdad.
local SECCIONES = {
    { clave = "S", cat = 100, texto = "Conjuntos" },
    { clave = "I", cat = 15,  texto = "Piezas" },   -- empieza en armas: es lo
                                                    -- que mas se busca
    { clave = "O", cat = 101, texto = "Guardados" },
    { clave = "V", cat = 102, texto = "Tienda" },
    --  🪄 30-09-2026: TRANSFIGURAR. Lo que has coleccionado jugando, por ranura
    --  (200 + ranura de equipo; empieza en el pecho). Ver armario-catalogo.lua.
    { clave = "T", cat = 204, texto = "Transfigurar" },
}

local ORDENES = {
    [0] = "A - Z", [1] = "Z - A", [2] = "Rareza", [3] = "Recientes", [4] = "Numero",
}

function PLARM.Coleccion.Crear(padre, x, y, ancho, alto)
    E = PLARM.Contrato.Estado
    local P = CreateFrame("Frame", nil, padre)
    P:SetPoint("TOPLEFT", x, y)
    P:SetSize(ancho, alto)

    local seccion  = SECCIONES[1]
    local pestanas = {}
    local ranuras  = {}
    local fichas   = {}

    -- -----------------------------------------------------------------------
    --  Pestanas de seccion
    -- -----------------------------------------------------------------------
    local px = 0
    for i, s in ipairs(SECCIONES) do
        --  🎨 GALERIA: las secciones van en la BARRA DE LA IZQUIERDA (maqueta:
        --     x 5-112, una cada 97 px desde y 97).
        local b = PLARM.SeccionLateral(padre, s.texto, PLARM.MX(106), PLARM.MY(94))
        b:SetPoint("TOPLEFT", padre, "TOPLEFT", PLARM.MX(6), -PLARM.MY(97 + (i - 1) * 97))
        px = px + 122
        b:PonerIcono(({ "GIcoConjuntos", "GIcoPiezas", "GIcoGuardados", "GIcoTienda", "GIcoPiezas" })[i])
        --  ⚠️ «Armas» y «Piezas» comparten la clave "I": lo que las
        --  distingue es la CATEGORIA de partida. Sin volver a fijarla aqui,
        --  la pestana heredaba la ranura que hubiera pulsado antes en la fila
        --  de iconos y saltaba a otra cosa.
        local catInicial = s.cat
        b:SetScript("OnClick", function()
            seccion = s
            s.cat = catInicial
            for _, o in ipairs(pestanas) do o:Marcar(false) end
            b:Marcar(true)
            P:CambiarSeccion()
        end)
        pestanas[i] = b
        --  Para poder cambiar de pestana desde las pruebas, sin teclado.
        b.pulsar = function() b:GetScript("OnClick")() end
    end
    pestanas[1]:Marcar(true)
    P.pestanas = pestanas

    -- -----------------------------------------------------------------------
    --  Buscador
    -- -----------------------------------------------------------------------
    local buscador = CreateFrame("EditBox", nil, P)
    buscador:SetSize(PLARM.MX(296), PLARM.MY(39))
    buscador:SetPoint("TOPLEFT", PLARM.MX(4), 0)
    buscador:SetAutoFocus(false)
    buscador:SetFontObject("GameFontHighlightSmall")
    PLARM.Tres(buscador, "GCaja", "BACKGROUND", 0.04)
    buscador:SetTextInsets(PLARM.MX(40), 8, 0, 0)
    local lupa = PLARM.Icono(buscador, "GLupa", 14)
    lupa:SetPoint("LEFT", PLARM.MX(14), 0)
    lupa:SetVertexColor(unpack(PLARM.TINTE_ICONO))
    buscador:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)

    local pista = PLARM.Texto(buscador, 10, c.textoTenue)
    pista:SetPoint("LEFT", PLARM.MX(40), 0)
    pista:SetText("Buscar...")
    buscador:SetScript("OnTextChanged", function(s)
        PLARM.Ver(pista, s:GetText() == "")
        --  Se espera un poco antes de preguntar: si no, cada tecla es un
        --  viaje al servidor y escribir "guardia" son siete.
        s.espera = 0.3
    end)
    buscador:SetScript("OnUpdate", function(s, e)
        if not s.espera then return end
        s.espera = s.espera - e
        if s.espera <= 0 then s.espera = nil; P:Refrescar() end
    end)

    -- -----------------------------------------------------------------------
    --  Filtro y Ordenar  --  copiados de Ascension, ver Filtro.lua
    -- -----------------------------------------------------------------------
    local btnFiltro, btnOrden, menuFiltro, menuOrden = PLARM.CrearFiltros(
        P, E,
        function() P:Refrescar() end,
        --  La ranura que se esta mirando: es lo que decide que opciones se
        --  ensenan. Sin esto el menu saldria entero siempre, que es lo que
        --  hace ilegibles los menus largos.
        function() return P.catActual end)
    --  🪤 A LA DERECHA, BAJO EL BUSCADOR -- NO A SU IZQUIERDA.
    --  Puestos al lado del buscador pisaban la pestaña «Tienda»: esa fila ya
    --  esta llena. Ascension los pone en su propia linea, a la derecha, y por
    --  eso les caben con el buscador al lado.
    --  🎨 Las dos cajas de la maqueta, a la derecha del buscador.
    btnFiltro:SetSize(PLARM.MX(116), PLARM.MY(39))
    btnOrden:SetSize(PLARM.MX(122), PLARM.MY(39))
    PLARM.EstiloCaja(btnFiltro, "GEmbudo", true)
    PLARM.EstiloCaja(btnOrden, "GOrden", true)
    btnFiltro:SetPoint("TOPLEFT", PLARM.MX(314), 0)
    btnOrden:SetPoint("TOPLEFT", PLARM.MX(442), 0)
    menuFiltro:SetPoint("TOPRIGHT", btnFiltro, "BOTTOMRIGHT", 0, -4)
    menuOrden:SetPoint("TOPRIGHT", btnOrden, "BOTTOMRIGHT", 0, -4)

    -- -----------------------------------------------------------------------
    --  Botones de ranura (solo en la seccion de piezas)
    -- -----------------------------------------------------------------------
    local filaRanuras = CreateFrame("Frame", nil, P)
    filaRanuras:SetPoint("TOPLEFT", PLARM.MX(2), -PLARM.MY(48))
    filaRanuras:SetSize(ancho, 28)

    local rx = 0
    for _, info in ipairs(C_AppearanceCollection.GetCategoriesForType("APPEARANCE_TYPE_ITEM")) do
        local b = CreateFrame("Button", nil, filaRanuras)
        b:SetSize(22, 22)
        b:SetPoint("LEFT", rx, 0)
        rx = rx + 25
        local nombre, textura = C_AppearanceCollection.GetCategoryInfo(info.cat)
        b.icono = b:CreateTexture(nil, "ARTWORK")
        b.icono:SetPoint("TOPLEFT", 5, -5)
        b.icono:SetPoint("BOTTOMRIGHT", -5, 5)
        b.icono:SetTexture(textura)
        b.icono:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        b.borde = PLARM.BordeArte(b, "RanuraOff", "RanuraOn")
        b.cat, b.nombre = info.cat, nombre
        b:SetScript("OnEnter", function(s)
            GameTooltip:SetOwner(s, "ANCHOR_TOP")
            GameTooltip:SetText(s.nombre)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        b:SetScript("OnClick", function(s)
            if seccion.clave == "T" then
                --  En «Transfigurar» la ranura elige QUE coleccionado se ve.
                seccion.cat = 200 + s.cat
            else
                seccion = SECCIONES[2]
                SECCIONES[2].cat = s.cat
            end
            for _, o in ipairs(ranuras) do
                for i = 1, 4 do o.borde[i]:SetVertexColor(unpack(c.borde)) end
            end
            for i = 1, 4 do s.borde[i]:SetVertexColor(unpack(c.oro)) end
            P:Refrescar()
        end)
        ranuras[#ranuras + 1] = b
        --  Para poder elegir la ranura desde las pruebas, sin raton.
        b.pulsar = function() b:GetScript("OnClick")(b) end
    end
    P.ranuras = ranuras

    -- -----------------------------------------------------------------------
    --  Barra de progreso: "Tienes 120 de 547"
    -- -----------------------------------------------------------------------
    local progreso = PLARM.Texto(P, 11, c.oroClaro)
    --  🎨 GALERIA: a la izquierda, con su barra dorada al lado.
    --  🎨 Como la maqueta: el texto encima y una barra FINA debajo (x 751-950).
    progreso:ClearAllPoints()
    progreso:SetPoint("TOPLEFT", PLARM.MX(608), -PLARM.MY(7))
    progreso:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    progreso:SetTextColor(0.86, 0.84, 0.8)
    local ANCHO_BARRA = PLARM.MX(199)
    local barra = CreateFrame("Frame", nil, P)
    barra:SetSize(ANCHO_BARRA, PLARM.MY(6))
    barra:SetPoint("TOPLEFT", PLARM.MX(608), -PLARM.MY(28))
    PLARM.Pieza(barra, "GBarra", "BACKGROUND")
    local lleno = CreateFrame("Frame", nil, barra)
    lleno:SetPoint("TOPLEFT"); lleno:SetPoint("BOTTOMLEFT"); lleno:SetWidth(1)
    PLARM.Pieza(lleno, "GBarraLlena", "ARTWORK")
    local suSetText = progreso.SetText
    progreso.SetText = function(self, t)
        --  La barra solo tiene sentido con «Tienes N de M».
        local hay = t and t:find("Tienes") and (E.total or 0) > 0
        PLARM.Ver(barra, hay)
        if hay then
            local k = math.max(0, math.min(1, (E.tengo or 0) / E.total))
            lleno:SetWidth(math.max(1, ANCHO_BARRA * k))
            PLARM.Ver(lleno, k > 0)
            t = string.format("Tienes %d de %d  \194\183  %d%%", E.tengo or 0, E.total, math.floor(k * 100 + 0.5))
        end
        suSetText(self, t)
    end

    -- -----------------------------------------------------------------------
    --  La rejilla
    -- -----------------------------------------------------------------------
    local rejilla = CreateFrame("Frame", nil, P)
    rejilla:SetPoint("TOPLEFT", 0, -82)
    rejilla:SetSize(ancho, FILAS * (PLARM.Ficha.ALTO + HUECO))

    local anchoRejilla = COLS * PLARM.Ficha.ANCHO + (COLS - 1) * HUECO
    local margen = math.floor((ancho - anchoRejilla) / 2)
    for i = 1, COLS * FILAS do
        local f = PLARM.Ficha.Crear(rejilla, i)
        local col, fila = (i - 1) % COLS, math.floor((i - 1) / COLS)
        f:SetPoint("TOPLEFT", margen + col * (PLARM.Ficha.ANCHO + HUECO),
                              -fila * (PLARM.Ficha.ALTO + HUECO))
        f:Hide()
        fichas[i] = f
    end

    -- -----------------------------------------------------------------------
    --  Paginacion
    -- -----------------------------------------------------------------------
    local pie = CreateFrame("Frame", nil, P)
    pie:SetPoint("TOPLEFT", rejilla, "BOTTOMLEFT", 0, -12)
    pie:SetSize(ancho, 22)

    local etiqueta = PLARM.Texto(pie, 11, c.textoSuave)
    etiqueta:SetPoint("CENTER")

    --  🎨 Pequeñas: la maqueta no trae paginacion y el dueño las vio grandes.
    --  🎨 Pegadas al texto, a los dos lados (el dueño: «mal posicionadas»);
    --     se recolocan cada vez que cambia el texto (PintarPie).
    local izq = PLARM.Boton(pie, "<", 24.1, 24.1)
    izq:SetPoint("RIGHT", etiqueta, "LEFT", -12, 0)
    local der = PLARM.Boton(pie, ">", 24.1, 24.1)
    der:SetPoint("LEFT", etiqueta, "RIGHT", 12, 0)

    --  🔴 LAS FLECHAS LAS ESCRIBE UN SOLO SITIO: esta funcion. Antes eran
    --  unas solas compartidas por tres paneles, y el que no estaba a la vista
    --  las apagaba -por eso al elegir un conjunto ya no se podia volver-.
    local function PintarPie()
        --  🔴 EL PIE YA NO REPITE EL CONTADOR DE ARRIBA.
        --
        --  Antes ponia «Pagina 1 de 2 · 21 de 21» mientras la barra de arriba
        --  decia «Tienes 21 de 21». Dos cifras iguales en la misma pantalla
        --  que significan cosas distintas --lo filtrado y lo que tienes-- se
        --  leen como un error, y encima en la tienda **no cuadraban**: «32 de
        --  32» arriba y «0 de 34» abajo.
        --
        --    🎯 Si dos sitios ensenan el mismo numero, uno de los dos sobra.
        --       El de abajo es de la paginacion; lo que se tiene va arriba.
        local texto = ("P\195\161gina %d de %d"):format(E.pagina, E.paginas)
        --  Solo se dice cuantos hay si el filtro esta escondiendo algo.
        if (E.filtrados or 0) > 0 and (E.filtrados or 0) < (E.total or 0) then
            texto = texto .. ("   ·   %d de %d"):format(E.filtrados, E.total)
        end
        etiqueta:SetText(texto)
        izq:Apagar(E.paginas <= 1)
        der:Apagar(E.paginas <= 1)
    end

    -- -----------------------------------------------------------------------
    --  Llenado escalonado
    -- -----------------------------------------------------------------------
    --  Su `InternalUpdateAppearances` en una funcion: una ficha por fotograma
    --  con una cola que se cancela. La bandera `cola` es el equivalente de su
    --  `pendingUpdate`, y ponerla a nil es su `MarkDirty`.
    local cola, colaToken = nil, 0
    local motor = CreateFrame("Frame")
    motor:SetScript("OnUpdate", function(self, e)
        if not cola then self:Hide() return end
        --  🔴 UNA FICHA POR FOTOGRAMA, SIN ESPERAR A LA ANTERIOR.
        --
        --  Se probo a esperar a que cada muneco terminara y fue PEOR: las
        --  fichas aparecian de una en una, cada seis segundos. Ascension no
        --  espera -- puede permitirselo porque su DLL ya tiene los datos en
        --  local. Nosotros dependemos del servidor, y la solucion no es
        --  frenar la rejilla: es que la ficha sea utilizable ANTES de tener
        --  el muneco (ver `Ficha.lua`: sale el icono y el muneco lo sustituye
        --  cuando llegan sus datos).
        self.reloj = (self.reloj or 0) + e
        if self.reloj < 0.01 then return end
        self.reloj = 0
        local trabajo = table.remove(cola, 1)
        if not trabajo then
            cola = nil
            self:Hide()
            return
        end
        trabajo()
    end)
    motor:Hide()

    --  🔴 UNA REJILLA VACIA PARECE ROTA. Y a veces esta vacia con razon: la
    --  tienda esconde lo que ya tienes, asi que si los tienes todos no queda
    --  nada que ofrecer. El dueno lo vio y penso que estaba estropeada, y es
    --  lo que pensaria cualquiera.
    --
    --    🎯 «No hay nada» y «no funciona» se ven igual si no lo dices. Todo
    --       hueco vacio necesita explicar POR QUE esta vacio.
    local vacio = PLARM.Texto(P, 12, c.textoSuave)
    vacio:SetPoint("CENTER", 0, 20)
    vacio:Hide()

    local function Llenar(lista)
        PLARM._pinta = PLARM._pinta or { refrescar = 0, llenar = 0, poner = 0, apar = 0 }
        PLARM._pinta.llenar = PLARM._pinta.llenar + 1
        if not lista or #lista == 0 then
            local por = {
                V = "Ya tienes todo lo que hay en la tienda.",
                O = "Todavia no has guardado ningun conjunto.",
                S = "No hay conjuntos que coincidan.",
                I = "No hay piezas de esta ranura.",
                T = "Aun no has coleccionado nada para esta ranura. Cada pieza que te equipas jugando se guarda aqui.",
            }
            local texto = por[seccion.clave] or "Aqui no hay nada."
            if (buscador:GetText() or "") ~= "" then
                texto = "Nada coincide con lo que buscas."
            end
            vacio:SetText(texto)
            vacio:Show()
        else
            vacio:Hide()
        end
        cola = nil                       -- cancela lo que quedara pendiente
        colaToken = colaToken + 1
        local token = colaToken
        cola = {}

        --  🔴 SE PINTA YA, CON LO QUE HAYA.
        --
        --  Antes se esperaba la respuesta de los nombres antes de pintar
        --  nada. Si ese unico mensaje se perdia -- o llegaba mal --, la
        --  rejilla ENTERA se quedaba vacia: ni iconos, ni nombres, ni
        --  munecos. Un mensaje, toda la ventana.
        --
        --    🎯 Nada que se pinte debe depender de que UNA respuesta llegue.
        --       Se pinta con lo que hay y se repinta cuando llegue lo demas.
        for i, f in ipairs(fichas) do
            local d = lista and lista[i]
            if d then
                d.pendiente, d.puesto = false, false
                --  🔴 SE OLVIDA LO QUE HABIA, SIEMPRE.
                --
                --  `Poner` tiene un atajo: si la celda ya ensena ese mismo
                --  conjunto y esta vestida, no rehace nada. Al volver de la
                --  pagina 2 a la 1 los datos SON los mismos, asi que el atajo
                --  saltaba... pero mientras tanto el cliente habia borrado los
                --  munecos (lo hace cada vez que cambia la apariencia del
                --  jugador). Resultado: quince celdas con el personaje del
                --  jugador, y ninguna forma de notarlo desde el atajo.
                --
                --  🔬 Se llego aqui MIDIENDO, no probando: el contador del DLL
                --  dijo `saltados=64 aplicados=0`, o sea que el enganche si
                --  cortaba. Si cortaba y aun asi salia el equipo del jugador,
                --  esas celdas no se estaban revistiendo -- y eso solo puede
                --  ser el atajo.
                --
                --    🎯 Un atajo que se fia de su propio estado miente cuando
                --       alguien de fuera cambia ese estado. Aqui el «de fuera»
                --       es el cliente, y no avisa.
                f.datos, f.vestida = nil, false
                cola[#cola + 1] = function()
                    if colaToken ~= token then return end
                    PLARM._pinta.poner = PLARM._pinta.poner + 1
                    f:Poner(d)
                end
            else
                f:Hide()
            end
        end
        motor:Show()
        PintarPie()

        --  🔴 LOS NOMBRES SOLO REPINTAN EL TEXTO. NO REHACEN EL MUNECO.
        --
        --  El comentario ya decia «solo repintan» y era mentira: llamaba a
        --  `f:Poner(...)`, que rehace la celda entera -- las 18 en el mismo
        --  fotograma, saltandose esta cola.
        --
        --  El cliente no puede armar 18 personajes de golpe: salian 3 y las
        --  otras 15 se quedaban con el equipo del jugador. Ese era el «me
        --  salen todos repetidos» que se reporto seis veces.
        --
        --    🎯 Un comentario no es una comprobacion. Este decia exactamente
        --       lo que habia que hacer, y debajo hacia lo contrario.
        --  🔴 EL NOMBRE SE SACA DE LA RESPUESTA, NO DE LA ENTRADA.
        --
        --  🚤 Aqui estaba el fallo, visto en pantalla el 19-09-2026: las 18
        --     celdas de la rejilla mostraban «...», siempre, en todas las
        --     paginas y en todas las pestanas.
        --
        --     El callback ignoraba su argumento y le pasaba a `PonerNombre`
        --     **la entrada de `lista`** — que solo trae `id`, `t`, `total` y
        --     `r`, y **nunca tuvo nombre**. El nombre llegaba, se guardaba en
        --     la cache, y nadie lo leia.
        --
        --  🔎 Y el diagnostico enganaba de lado a lado: el servidor decia
        --     `nom: 18 de 18 ids resolvieron, 18 partes` y `Trocear mando 4
        --     mensajes`, o sea que por su lado estaba todo bien. Tampoco era
        --     el limite de 10 mensajes/segundo. Los datos llegaban enteros y
        --     se tiraban en la ultima linea.
        --
        --    🎯 Que el emisor diga que lo mando y el receptor lo reciba **no
        --       significa que alguien lo use**. Entre «llega» y «se pinta» hay
        --       un paso mas, y es donde hay que mirar cuando los dos extremos
        --       parecen correctos.
        local ids = {}
        for _, e in ipairs(lista or {}) do ids[#ids + 1] = e.id end
        C_Appearance.PedirNombres(ids, function(nombres)
            if colaToken ~= token then return end
            --  🔴 EL NOMBRE SE GUARDA EN LA ENTRADA, FUERA DEL `if`.
            --
            --  🚤 Y ese `if` es justo donde estuvo el fallo, dos veces. La
            --     version de antes hacia `if f.datos and lista[i] then
            --     f:PonerNombre(lista[i]) end`, y la respuesta llega **antes de
            --     que ninguna celda exista**: `Poner` va en una cola que se
            --     procesa poco a poco, para no armar 18 personajes de golpe.
            --
            --  🔬 Medido con una sonda, porque dos hipotesis seguidas
            --     fallaron y el servidor decia que mandaba los 18 bien:
            --
            --         pedidos=18  con_nombre=18  celdas=18
            --         **con_datos=0  pintables=0**
            --
            --     O sea: los nombres llegaban enteros y **el bucle descartaba
            --     las 18 celdas** porque todavia no tenian datos. Resultado:
            --     toda la rejilla con «...» debajo de cada muñeco, en todas las
            --     paginas y en todas las pestañas.
            --
            --  ✅ La entrada de `lista` es **el MISMO objeto** que recibe
            --     `Poner` (la cola captura `d = lista[i]`), asi que escribir el
            --     nombre ahi llega igual aunque la celda no exista aun.
            --
            --    🎯 Cuando el emisor manda bien y el receptor recibe bien, el
            --       fallo esta en el PASO DE EN MEDIO — aqui, en la condicion
            --       que decidia a quien darselo.
            for i, e in ipairs(lista or {}) do
                local c = nombres and nombres[e.id]
                if c and c.nombre and c.nombre ~= "" then
                    e.nombreCompleto = c.nombre
                end
                local f = fichas[i]
                if f and f.datos then f:PonerNombre(e) end
            end
        end)
    end

    -- -----------------------------------------------------------------------
    --  Refrescar: filtrar y pedir la pagina
    -- -----------------------------------------------------------------------
    --  🔬 CUANTAS VECES SE REPINTA. Un parpadeo es la rejilla vaciandose y
    --  volviendose a llenar, y «dos parpadeos» puede ser dos llenados o un
    --  llenado mas un revestido de fuera -- que se arreglan en sitios
    --  distintos y en pantalla se ven igual.
    function P:Refrescar(pagina)
        PLARM._pinta = PLARM._pinta or { refrescar = 0, llenar = 0, poner = 0, apar = 0 }
        PLARM._pinta.refrescar = PLARM._pinta.refrescar + 1
        PLARM.Ver(filaRanuras, seccion.clave == "I" or seccion.clave == "T")
        --  🎨 Con la fila de ranuras (Piezas) la rejilla baja y las tarjetas
        --     encogen un poco, para que la paginacion quepa igual abajo.
        local conRanuras = seccion.clave == "I" or seccion.clave == "T"
        rejilla:ClearAllPoints()
        rejilla:SetPoint("TOPLEFT", 0, -PLARM.MY(conRanuras and 80 or 60))
        --  medido en la maqueta: 270 de alto (a la misma escala que el juego)
        local alto = PLARM.MY(conRanuras and 250 or 270)
        rejilla:SetHeight(FILAS * alto + (FILAS - 1) * HUECO)
        for i, f in ipairs(fichas) do
            local col, fila = (i - 1) % COLS, math.floor((i - 1) / COLS)
            f:SetHeight(alto)
            --  🪤 El marco del muñeco es MAS ANCHO que la tarjeta para que un
            --     personaje entero la llene; con un busto (Piezas) se salia
            --     por los lados. En Piezas va dentro de la tarjeta.
            if f.hueco then
                local ext = conRanuras and -5 or 18
                f.hueco:ClearAllPoints()
                f.hueco:SetPoint("TOPLEFT", -ext, conRanuras and -5 or -3)
                f.hueco:SetPoint("BOTTOMRIGHT", ext, 40)
            end
            f:ClearAllPoints()
            f:SetPoint("TOPLEFT", col * (PLARM.Ficha.ANCHO + HUECO), -fila * (alto + HUECO))
        end
        PLARM.Ver(progreso, seccion.clave ~= "O")
        --  🪤 La barra la enciende SetText, y en Guardados no se llama: se
        --     quedaba la de Conjuntos, llena y sin texto (visto 26-09-2026).
        if seccion.clave == "O" then PLARM.Ver(barra, false) end

        local texto = buscador:GetText() or ""
        if seccion.clave == "O" then
            --  🔑 LOS ATUENDOS NO SE FILTRAN NI SE PAGINAN: son veinte como
            --  mucho y son tuyos. Meterlos por el mismo camino que el
            --  catalogo -- filtro, paginas, rareza-- seria complicar algo que
            --  cabe entero en una pantalla.
            --
            --    🎯 No todo lo que se ensena en una rejilla necesita el
            --       mecanismo de la rejilla.
            C_AppearanceOutfit.GetOutfits(function(lista)
                local entradas = {}
                for _, a in ipairs(lista or {}) do
                    entradas[#entradas + 1] = {
                        id = 0, atuendo = a.nombre, piezasFijas = a.piezas,
                        t = 1, total = 1, r = 1,
                    }
                end
                E.tengo, E.total, E.paginas, E.pagina = #entradas, #entradas, 1, 1
                Llenar(entradas)
            end)
        elseif seccion.clave == "V" then
            --  🪤 LA TIENDA NO ACTUALIZABA LA BARRA DE ARRIBA, asi que se
            --  quedaba con el «Tienes 32 de 32» de la pestana anterior --un
            --  dato de otra cosa, y ademas contradecia al pie-. Aqui lo que
            --  importa no es cuanto tienes: es cuanto queda por comprar.
            progreso:SetText("")
            C_VanityCollection.QueryItems(pagina or 1, E.flags or 0, texto,
                function(...)
                    --  🪤 `E.total` es TODO lo de la tienda, tambien lo tuyo;
                    --     la rejilla esconde lo tuyo. Salia «34 a la venta»
                    --     encima de «Ya tienes todo». Lo que queda es
                    --     `E.filtrados`.
                    local quedan = E.filtrados or 0
                    progreso:SetText(quedan > 0
                        and ("|cffE8B54D%d|r a la venta"):format(quedan)
                        or "")
                    Llenar(...)
                end)
        else
            --  🔑 Se apunta la ranura que se esta mirando: el menu de filtro
            --  la usa para enseñar solo las opciones que tienen sentido aqui
            --  (nada de «Tela» cuando miras armas), que es como lo hace
            --  Ascension.
            P.catActual = seccion.cat
            --  🔴 EN LA COLECCION NO SE ENSENA LO QUE NO TIENES.
            --
            --  Lo pidio el dueno mirando su armario: *«no deberia ver sets que no
            --  tengo... mas bien asi deberia salir los que no puedo ponerme:
            --  bloqueados»*. Antes salian los 34 y los que no tenia iban en gris.
            --
            --  🩤 Se respeta el filtro del jugador: si marca «Sin coleccionar» es
            --  que QUIERE ver lo que le falta, y forzar esto le dejaria la rejilla
            --  vacia sin explicarle por que.
            --
            --  ⚠️ Y NO se aplica a la tienda, que se pide mas arriba: ahi lo que
            --  importa es justo lo que todavia NO tienes.
            local F_SOLO_MIOS, SIN_COLECCIONAR = 524288, 2
            local flags = E.flags or 0
            if bit.band(flags, SIN_COLECCIONAR) == 0 then
                flags = bit.bor(flags, F_SOLO_MIOS)
            end
            C_AppearanceCollection.ApplyCategoryFilter(
                seccion.clave, seccion.cat, texto, E.orden or 0, flags,
                function()
                    progreso:SetText(string.format(
                        "Tienes |cffE8B54D%d|r de %d", E.tengo, E.total))
                    C_AppearanceCollection.GetCategoryAppearances(pagina or 1, Llenar)
                end)
        end
    end

    function P:CambiarSeccion()
        buscador:SetText("")
        P:Refrescar(1)
    end

    --  Pasar pagina. Da la vuelta al final, como su `NextPage`.
    local function Pasar(cuanto)
        local n = E.pagina + cuanto
        if n < 1 then n = E.paginas elseif n > E.paginas then n = 1 end
        P:Refrescar(n)
    end
    izq:SetScript("OnClick", function() Pasar(-1) end)
    der:SetScript("OnClick", function() Pasar(1) end)
    P:EnableMouseWheel(true)
    P:SetScript("OnMouseWheel", function(_, d) Pasar(d > 0 and -1 or 1) end)

    --  El servidor avisa; la ventana no pregunta.
    PLARM.Eventos.Registrar("APPEARANCE_COLLECTED", function() P:Refrescar(E.pagina) end)

    --  🔴 AL CAMBIAR TU APARIENCIA, EL CLIENTE REHACE TODOS LOS MUNECOS.
    --
    --  Cualquier `DressUpModel` armado con `SetUnit("player")` se reconstruye
    --  solo cuando el jugador cambia de aspecto, y al hacerlo BORRA lo que le
    --  hubieramos probado encima. Resultado: aplicas un conjunto y las 18
    --  celdas pasan a ensenar tu ropa nueva, todas iguales.
    --
    --  El dueno lo reporto tres veces y las tres se busco en otro sitio -- en
    --  la cache, en el protocolo, en el numero de mensajes. Ninguno era.
    --
    --    🎯 Si algo se deshace SOLO despues de una accion concreta, no lo
    --       estas haciendo mal: te lo estan deshaciendo. Busca quien.
    --
    --  Hay que volver a vestirlas, y saltandose el atajo de «ya ensena eso»
    --  -- porque justamente ya no lo ensena.
    --  🔴 Y SE VUELVEN A VESTIR **POR LA COLA**, NO LAS 18 DE GOLPE.
    --
    --  Aqui estaba el fallo que costo cinco dias, y se veia en dos capturas
    --  separadas veinte minutos: recien abierta la rejilla salian las 18 bien;
    --  un rato despues, quince de ellas mostraban el personaje del jugador.
    --
    --  La secuencia completa:
    --
    --    1. La cola escalonada llena las 18 celdas -- correcto.
    --    2. Algo cambia la apariencia del jugador y el cliente **borra lo
    --       probado en todos los `DressUpModel` que usan `SetUnit("player")`**
    --       (esta documentado en el 79).
    --    3. Este manejador las revestia **todas en el mismo fotograma**. El
    --       cliente no puede armar 18 personajes a la vez: salian ~3 y las
    --       demas se quedaban con lo del jugador.
    --
    --    🎯 Por eso el numero era SIEMPRE 3, y por eso ningun arreglo sobre
    --       «cuando vestir» podia servir: el destrozo venia despues, por otro
    --       camino que se saltaba la cola.
    --
    --    🎯 Y la leccion de metodo: el sintoma aparecia MINUTOS despues de
    --       abrir, asi que probar recien abierto daba «funciona». Un fallo que
    --       tarda necesita una prueba que espere -- ya estaba escrito para las
    --       desconexiones y no se aplico aqui.
    --
    --  Es el mismo error que tenia el aviso de los nombres, en un segundo
    --  sitio: **dos caminos distintos esquivaban la misma cola**.
    PLARM.Eventos.Registrar("APPEARANCE_CHANGED", function()
        PLARM._pinta = PLARM._pinta or { refrescar = 0, llenar = 0, poner = 0, apar = 0 }
        PLARM._pinta.apar = PLARM._pinta.apar + 1
        colaToken = colaToken + 1
        local token = colaToken
        cola = {}
        for _, f in ipairs(fichas) do
            if f.datos then
                local d = f.datos
                f.datos, f.vestida = nil, false
                cola[#cola + 1] = function()
                    if colaToken ~= token then return end
                    f:Poner(d)
                end
            end
        end
        motor:Show()
    end)
    PLARM.Eventos.Registrar("WEB_SHOP_PURCHASE_SUCCESS", function() P:Refrescar(E.pagina) end)
    PLARM.Eventos.Registrar("PENDING_APPEARANCE_CHANGED", function()
        for _, f in ipairs(fichas) do
            if f.datos then
                f.datos.pendiente = false
                for _, id in pairs(E.pendiente) do
                    if id == f.datos.id then f.datos.pendiente = true end
                end
                f:Pintar()
            end
        end
    end)

    P.fichas = fichas
    return P
end

--  Marca de carga: si este archivo revienta, su linea NO sale y se ve al
--  instante cual es. Los errores de Lua vienen apagados de fabrica.
PLARM_CARGADO = (PLARM_CARGADO or "") .. " Coleccion"
