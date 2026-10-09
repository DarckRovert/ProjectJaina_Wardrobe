--  Limites.lua -- ¿contra que pared vamos a chocar de verdad?
--
--  🔴 POR QUE EXISTE. El dueno pregunto por que no hacemos ya las apariencias
--  en el DLL, y su miedo era concreto y razonable:
--
--      «tengo miedo de que mas adelante otra vez no podamos hacer algo por
--       estar limitados»
--
--  La respuesta honesta no es un argumento: es una medida. Esta sonda prueba,
--  DENTRO DEL JUEGO, cada cosa que Ascension hace con su DLL y que se sospecha
--  que 3.3.5a no puede. Lo que salga NO es opinion.
--
--    🎯 Cuando alguien duda de un criterio y ese criterio ya ha fallado antes,
--       no se defiende: se sustituye por una medida.
--
--  El resultado se manda al registro del servidor:
--      [limites] <prueba> = SI / NO / <numero>
--
--  Se dispara con la orden `!limites` (control remoto) o `/limites`.

--  🪤 LA TABLA DEL ADDON SE LLAMA `PLARM`, NO `PeruLandArmario`.
--  Escribir `local PLARM = PeruLandArmario` la deja en `nil`, y la primera
--  linea que la use tira el archivo ENTERO al cargarse -- sin error visible,
--  porque los errores de Lua vienen apagados de fabrica. El sintoma es que
--  «esa parte no existe»: ni la ventana, ni el comando, ni la respuesta.
--
--    🎯 Un archivo que no carga y uno que carga y no hace nada se ven igual
--       desde fuera. Por eso cada archivo avisa de su nombre al cargar.
local PREFIJO = "WP_WARDROBE"

local resultados = {}

local function anota(nombre, valor)
    resultados[#resultados + 1] = nombre .. "=" .. tostring(valor)
end

--- ¿Existe esta funcion del cliente? Se prueba LLAMANDOLA, no preguntando si
--- esta definida: en Eluna multiestado hay funciones que existen y revientan
--- al usarse, y en el cliente hay metodos que solo fallan al invocarse.
local function metodo(objeto, nombre, ...)
    if type(objeto[nombre]) ~= "function" then return false end
    local ok = pcall(objeto[nombre], objeto, ...)
    return ok
end

local function Medir()
    resultados = {}
    --  Avisar ANTES de medir. Si algo revienta a mitad, esta linea distingue
    --  «no se ejecuto» de «se ejecuto y fallo» -- que son arreglos opuestos y
    --  desde fuera se ven igual.
    SendAddonMessage(PREFIJO, "limites|0|empieza", "WHISPER", UnitName("player"))

    -- 1. ¿Cuantos munecos 3D aguanta? Es el limite que decide si la rejilla
    --    puede pasar de 18 a 40, o si hay que paginar mas fino.
    --
    --    🔴 SE INFORMA EN CADA TRAMO, NO AL FINAL. La primera version creaba
    --    los 40 de golpe y DESCONECTABA al cliente: la medida moria con la
    --    sesion y no quedaba ni una pista. Informar por tramos convierte una
    --    caida en el propio resultado -- el ultimo tramo que llego es el
    --    limite.
    --
    --      🎯 Una prueba que puede tumbar lo que mide tiene que ir contando
    --         por el camino, no al terminar.
    local caja = {}
    for tramo = 1, 7 do
        local hasta = tramo * 6           -- 6..42: se busca DONDE se rompe
        local t0 = debugprofilestop and debugprofilestop() or 0
        for i = #caja + 1, hasta do
            local m = CreateFrame("DressUpModel", nil, UIParent)
            m:SetSize(64, 64); m:SetPoint("TOPLEFT", -2000, 0); m:SetAlpha(0); m:Show()
            pcall(function() m:SetUnit("player") end)
            caja[i] = m
        end
        local armados = 0
        for _, m in ipairs(caja) do
            local r; pcall(function() r = m:GetModel() end)
            if type(r) == "string" and r ~= "" then armados = armados + 1 end
        end
        SendAddonMessage(PREFIJO, string.format("limites|m|munecos=%d armados=%d ms=%d",
            hasta, armados, debugprofilestop and math.floor(debugprofilestop() - t0) or -1),
            "WHISPER", UnitName("player"))
    end
    for _, m in ipairs(caja) do m:Hide(); m:SetParent(nil) end

    -- 2. Camara propia por pieza (su C_UICamera). Si SetCamera y
    --    SetCameraPosition responden, no hace falta DLL para encuadrar.
    local m = CreateFrame("DressUpModel", nil, UIParent)
    m:SetSize(64, 64); m:SetPoint("TOPLEFT", -2000, 0); m:SetAlpha(0); m:Show()
    pcall(function() m:SetUnit("player") end)
    anota("SetCamera",         metodo(m, "SetCamera", 0))
    anota("SetCameraPosition", metodo(m, "SetCameraPosition", 1, 0, 0))
    anota("SetCameraDistance", metodo(m, "SetCameraDistance", 2))
    anota("SetPosition",       metodo(m, "SetPosition", 0, 0, 0))
    anota("SetFacing",         metodo(m, "SetFacing", 0.5))
    anota("SetLight",          metodo(m, "SetLight", 1, 0, -1, 1, -1, 1, 1, 1, 1, 0, 1, 1, 1))
    anota("Undress",           metodo(m, "Undress"))
    anota("TryOn",             metodo(m, "TryOn", 913458))
    anota("GetModel",          metodo(m, "GetModel"))
    -- estas son de clientes modernos: se espera que NO existan
    anota("SetItemAppearance", type(m.SetItemAppearance) == "function")
    anota("SetSheathed",       type(m.SetSheathed) == "function")
    m:Hide(); m:SetParent(nil)

    -- 3. Filtrar y ordenar muchas apariencias en el cliente. Es lo que de
    --    verdad decide si el DLL hace falta: con decenas de miles, Lua se
    --    arrastra. Con los nuestros, no.
    local n = 20000
    local lista = {}
    for i = 1, n do lista[i] = { id = i, nombre = "conjunto " .. i, rareza = i % 4 } end
    local t1 = debugprofilestop and debugprofilestop() or 0
    local filtrado = {}
    for _, e in ipairs(lista) do
        if e.rareza == 3 and e.nombre:find("7") then filtrado[#filtrado + 1] = e end
    end
    table.sort(filtrado, function(a, b) return a.nombre < b.nombre end)
    if debugprofilestop then
        anota("ms_filtrar_20000", math.floor(debugprofilestop() - t1))
    end
    anota("filtrados", #filtrado)

    -- 4. Cuanta memoria de Lua consume el addon. El cliente de 3.3.5a se
    --    vuelve inestable muy por encima de ~100 MB.
    UpdateAddOnMemoryUsage()
    anota("KB_addon", math.floor(GetAddOnMemoryUsage("ProjectJaina_Wardrobe") or GetAddOnMemoryUsage("PeruLandArmario") or 0))
    anota("KB_lua_total", math.floor(collectgarbage("count")))

    -- 5. Tooltips propios y hipervinculos: si esto va, la ficha rica no
    --    necesita DLL.
    local tt = CreateFrame("GameTooltip", "ProjectJainaLimitesTT", nil, "GameTooltipTemplate")
    tt:SetOwner(UIParent, "ANCHOR_NONE")
    anota("SetHyperlink", metodo(tt, "SetHyperlink", "item:913458"))
    anota("AddDoubleLine", metodo(tt, "AddDoubleLine", "a", "b"))

    -- 6. La extension propia: ¿esta cargada y responde?
    anota("DLL_presente", type(_G.ProjectJaina_Extension) == "function" or type(_G.PeruLand_Extension) == "function")

    --  Se manda en trozos: un mensaje de addon no pasa de 255 bytes.
    local linea, i = "", 0
    for _, r in ipairs(resultados) do
        if #linea + #r + 1 > 200 then
            i = i + 1
            SendAddonMessage(PREFIJO, "limites|" .. i .. "|" .. linea, "WHISPER", UnitName("player"))
            linea = ""
        end
        linea = (linea == "" and r) or (linea .. " " .. r)
    end
    if linea ~= "" then
        i = i + 1
        SendAddonMessage(PREFIJO, "limites|" .. i .. "|" .. linea, "WHISPER", UnitName("player"))
    end
    if PLARM and PLARM.Diag then PLARM.Diag(table.concat(resultados, " ")) end
end

PLARM.MedirLimites = Medir

local rx = CreateFrame("Frame")
rx:RegisterEvent("CHAT_MSG_ADDON")
rx:SetScript("OnEvent", function(_, _, pre, msg, _, quien)
    if pre ~= PREFIJO or msg ~= "limites" then return end
    --  🔴 SOLO MENSAJES DEL SERVIDOR (29-09-2026): el servidor nos los manda
    --     como susurro de nosotros mismos. Sin esto, OTRO jugador podia
    --     mandarnos mensajes con este prefijo y manejar el addon: abrir una
    --     web con la extension, enviar ordenes en nuestro nombre o pintar
    --     respuestas falsas.
    if quien ~= UnitName("player") then return end
    --  Sin `pcall`, un fallo a mitad deja la medida sin resultados Y sin
    --  error visible: exactamente el escenario que esta sonda existe para
    --  evitar.
    local ok, err = pcall(Medir)
    if not ok then
        SendAddonMessage(PREFIJO, "limites|X|REVENTO " .. tostring(err):sub(1, 150),
                         "WHISPER", UnitName("player"))
    end
end)

SLASH_PLLIMITES1 = "/limites"        -- 🪤 sin guion bajo, o no queda registrado
SlashCmdList["PLLIMITES"] = Medir

if PLARM and PLARM.Diag then PLARM.Diag("cargado: Limites") end
