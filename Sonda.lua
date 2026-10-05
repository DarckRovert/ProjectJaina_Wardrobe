--  Sonda.lua -- ¿SE ARMO EL PERSONAJE?  (instrumento, no arreglo)
--
--  🔴 POR QUE EXISTE. El fallo del muneco vacio se persiguio dos dias a base
--  de proponer causas y comprobarlas despues. El metodo que SI lo resolvio la
--  primera vez fue apagar los parches y encenderlos por mitades -- pero para
--  eso hace falta una senal automatica de "se armo / no se armo", o cada
--  vuelta acaba en una captura y en pedirle al dueno que mire.
--
--    🎯 Instrumentar antes que arreglar. Un fallo que solo se ve mirando
--       cuesta una persona por intento; uno que se ve en el registro, cero.
--
--  Como funciona: se crea un DressUpModel escondido, se le pide el jugador y,
--  un segundo despues, se le pregunta `GetModel()`. Si el personaje se armo
--  devuelve la ruta de su .m2; si no, devuelve vacio. El resultado se manda al
--  servidor, que lo escribe en su registro -- asi se lee por SSH.
--
--  ⚠️ Un segundo de espera no es capricho: `SetUnit` no arma nada en el acto.
--     Preguntar en el mismo fotograma da siempre vacio, tambien cuando todo
--     funciona, y eso es un instrumento que miente.

local PREFIJO = "WP_WARDROBE"

--  Un tooltip escondido para preguntarle al cliente por un objeto suelto
--  (orden `item|<id>`). Se crea UNA vez, aqui: crearlo dentro del manejador
--  con un nombre distinto cada vez deja marcos vivos para siempre.
local sondaItem = CreateFrame("GameTooltip", "WoWPeru_Wardrobe_SondaItem", nil,
                              "GameTooltipTemplate")
sondaItem:SetOwner(UIParent, "ANCHOR_NONE")

local sonda = CreateFrame("DressUpModel", "WoWPeru_Wardrobe_Sonda3D", UIParent)
sonda:SetSize(64, 64)
sonda:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -500, 500)   -- fuera de pantalla
sonda:Hide()

--  🪤 CONTROL. Sin esto la sonda decia "VACIO" tambien cuando todo estaba
--  bien, y eso manda a buscar el fallo donde no esta -- ya paso una vez con
--  la autoprueba del armario.
--
--    🎯 Un instrumento se valida contra algo que TIENE que salir. Aqui, un
--       modelo de Blizzard puesto a mano: si ese falla, el roto es la sonda.
local control = CreateFrame("DressUpModel", "WoWPeru_Wardrobe_Control3D", UIParent)
control:SetSize(64, 64)
control:SetPoint("CENTER")          -- ⚠️ en pantalla: un marco fuera de la
control:SetAlpha(0)                 --    vista puede no llegar a dibujarse
control:Show()

local function Informe()
    control:SetModel("character\human\male\humanmale.m2")
    sonda:SetAlpha(0)
    sonda:SetPoint("CENTER")        -- misma razon que el control
    sonda:Show()
    sonda:SetUnit("player")
    local esperado = GetTime() + 1.5
    sonda:SetScript("OnUpdate", function(s)
        if GetTime() < esperado then return end
        s:SetScript("OnUpdate", nil)
        local function Ruta(m)
            local r = ""
            pcall(function()
                local x = m:GetModel()
                r = (type(x) == "string") and x or ""
            end)
            return r
        end
        local ruta, ctrl = Ruta(s), Ruta(control)
        local _, raza = UnitRace("player")

        --  🔬 ¿EXISTEN LAS FUNCIONES QUE USA ASCENSION PARA ENSENAR UN ARMA
        --  SOLA? Se pregunta en vez de suponerlo: `SetDisplayInfo(<invisible>)`
        --  + `TryOn(arma)` es SU receta, y si aqui esa funcion no existe, el
        --  `pcall` se traga el fallo y la celda se queda en el icono -- que es
        --  exactamente lo que se vio, y no dice POR QUE.
        --
        --    🎯 «No funciono» tiene dos causas muy distintas: la funcion no
        --       existe, o existe y el modelo elegido no vale. Se arreglan en
        --       sitios opuestos.
        local api = {}
        --  Que hay para CONGELAR la animacion. El dueno lo vio en sus
        --  capturas: «los munecos de los sets nunca se mueven; lo unico que
        --  se mueve son los efectos». Ascension llama `FreezeSequence()`.
        for _, n in ipairs({ "ClearModel", "StopSequence", "SetSequenceTime",
                             "RefreshUnit", "SetCamera", "Undress" }) do
            api[#api + 1] = n .. "=" .. tostring(type(s[n]) == "function")
        end

        --  Y la prueba de verdad: ponerle el invisible y ver si sale modelo.
        local conInvisible = ""
        pcall(function()
            local p = CreateFrame("DressUpModel", nil, UIParent)
            p:SetSize(64, 64); p:SetPoint("CENTER"); p:SetAlpha(0); p:Show()
            p:SetCreature(12999)
            local x = p:GetModel()
            conInvisible = (type(x) == "string") and x or "(vacio)"
        end)

        local texto = ("sonda|%s|control=%s|%s|%s"):format(
            (ruta ~= "" and "ARMADO" or "VACIO"),
            (ctrl ~= "" and "ok" or "ROTO"),
            tostring(raza), ruta)
        pcall(SendAddonMessage, PREFIJO,
              "sonda|api|" .. table.concat(api, " ") .. "|invisible=" .. conInvisible,
              "WHISPER", UnitName("player"))
        SendAddonMessage(PREFIJO, texto, "WHISPER", UnitName("player"))
        --  Diagnostico: solo con `/armario diag`. Antes llenaba el chat.
        if PLARM and PLARM.Diag then PLARM.Diag(texto) end
    end)
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
    --  3 s: da tiempo a que lleguen las fichas de lo puesto
    local t = GetTime() + 3
    f:SetScript("OnUpdate", function(s)
        if GetTime() < t then return end
        s:SetScript("OnUpdate", nil)
        Informe()
    end)
end)

--  El servidor puede pedirla, para poder estrechar el fallo pieza a pieza
--  sin cerrar y abrir el juego en cada vuelta.
--  El nombre real del marco, en UN solo sitio. Escrito dos veces es como se
--  desincroniza (ver el arreglo de `cerrar` mas abajo).
local NOMBRE_VENTANA = "WoWPeru_Wardrobe_Frame"

--  Las unicas ordenes que se acusan. Lo demas que entra por este canal son
--  RESPUESTAS DEL SERVIDOR, y contestarlas duplicaria el trafico -- ver el
--  aviso grande abajo.
local ORDENES_DE_PRUEBA = {
    ["abrir"] = true, ["cerrar"] = true, ["aplicar"] = true,
    ["pestana"] = true, ["ficha"] = true, ["pulsar"] = true,
    ["comprar"] = true, ["web"] = true, ["limites"] = true,
    ["celdas"] = true, ["pagina"] = true, ["contador"] = true,
    ["vestidos"] = true, ["pendientes"] = true, ["item"] = true, ["nombres"] = true, ["preview"] = true,
    ["ranura"] = true, ["hielo"] = true, ["pintado"] = true,
    ["pintado0"] = true,
}

-- ---------------------------------------------------------------------------
--  El acuse: cada orden contesta QUE PASO, no solo que llego
-- ---------------------------------------------------------------------------
--  🔴 POR QUE (03-09-2026). El mando remoto mandaba ordenes y no contestaba
--  nada, asi que «no se movio la pantalla» podia significar tres cosas muy
--  distintas y todas se veian igual:
--
--      · la orden no llego                  -> el instrumento esta roto
--      · llego y el addon no la entendio    -> falta el manejador
--      · llego, se ejecuto, y no hizo nada  -> ESE es el fallo de verdad
--
--  Se perdio una tanda entera de pruebas por no distinguirlas. Ahora cada
--  orden devuelve el ESTADO que se puede comprobar desde fuera: si la ventana
--  esta abierta y en que pestana. Asi el que prueba no tiene que creerse nada.
local function Acuse(orden)
    local v = _G[NOMBRE_VENTANA]
    local abierta = (v and v:IsShown()) and "si" or "no"
    local pest = "?"
    if v and v.coleccion and v.coleccion.pestanas then
        for i, b in ipairs(v.coleccion.pestanas) do
            if b.elegida then pest = tostring(i) end
        end
    end
    local yo = UnitName("player")
    pcall(SendAddonMessage, PREFIJO,
          ("ack|%s|ventana=%s|pestana=%s"):format(orden, abierta, pest),
          "WHISPER", yo)
end

local rx = CreateFrame("Frame")
rx:RegisterEvent("CHAT_MSG_ADDON")
rx:SetScript("OnEvent", function(_, _, pre, msg, _, quien)
    if pre ~= PREFIJO then return end
    --  🔴 SOLO MENSAJES DEL SERVIDOR (29-09-2026): el servidor nos los manda
    --     como susurro de nosotros mismos. Sin esto, OTRO jugador podia
    --     mandarnos mensajes con este prefijo y manejar el addon: abrir una
    --     web con la extension, enviar ordenes en nuestro nombre o pintar
    --     respuestas falsas.
    if quien ~= UnitName("player") then return end
    --  🪤 El addon se oye a si mismo: sin esto, el acuse dispararia otro acuse.
    if msg:sub(1, 4) == "ack|" then return end

    --  🪤 ESCRIBIR EL COMANDO CON EL TECLADO NO ES FIABLE. Mandar "/armario"
    --  a la ventana pierde letras (se quedaba en "/a") y, dentro del juego,
    --  las teclas sueltas se toman como atajos: una prueba abria el mapa en
    --  vez del armario. El control remoto no depende del foco ni del ritmo.
    if msg == "sonda" then
        Informe()
    elseif msg == "abrir" then
        if PLARM.Abrir2 then PLARM.Abrir2() end
    elseif msg == "cerrar" then
        --  🪤 Aqui ponia `_G["PeruLandArmarioVentana"]`, y la ventana se llama
        --  `PeruLandArmarioV2` (Ventana.lua:29). O sea que `v` era SIEMPRE nil
        --  y `cerrar` no hacia nada -- sin dar ningun error, claro.
        --
        --  Costo una tanda de pruebas falsas el 03-09-2026: se uso `cerrar`
        --  como orden de CONTROL --la que dice si el mando funciona-- y como
        --  no cerraba nada, se dio por muerto un canal que estaba vivo.
        --
        --    🎯 Un control que esta roto es peor que no tener control: hace
        --       fallar la prueba de que las demas pruebas valen.
        local v = _G[NOMBRE_VENTANA]
        if v then v:Hide() end
    elseif msg:sub(1, 4) == "web|" then
        --  Prueba de la extension del cliente. `PeruLand_AbrirWeb` es lo
        --  primero que 3.3.5a NO puede hacer desde Lua: abrir el navegador.
        if PeruLand_AbrirWeb then
            PeruLand_AbrirWeb(msg:sub(5))
            if PeruLand_Log then PeruLand_Log("probando AbrirWeb con: " .. msg:sub(5)) end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffC83842[Armario]|r sin extension")
        end
    elseif msg:sub(1, 1) == ">" then
        --  Pasarela: manda al servidor lo que venga detras del ">", tal cual.
        --  Sirve para probar CUALQUIER mensaje del protocolo sin anadir una
        --  orden nueva cada vez.
        PLARM.Contrato.Mandar(msg:sub(2))
    elseif msg == "recargar" then
        --  🔴 OJO: ESTO **NO** SIRVE PARA PROBAR UN CAMBIO EN EL ADDON.
        --
        --  Aqui ponia que `ReloadUI` «relee los .lua del disco». Es FALSO en
        --  este cliente, y ya estaba avisado en el CLAUDE.md: *«el .lua no se
        --  recarga con /reload»*. `ReloadUI` rehace la interfaz con el codigo
        --  que ya estaba en memoria.
        --
        --  Costo dos rondas el 03-09-2026: se desplegaba el arreglo, se mandaba
        --  `recargar`, se probaba... y se estaba probando el codigo VIEJO. La
        --  segunda vez ademas parecia que el arreglo no funcionaba.
        --
        --    🎯 Para cargar un .lua nuevo hay que CERRAR Y ABRIR el cliente.
        --       No hay atajo, y creer que lo hay da resultados falsos.
        --
        --  Sigue valiendo para lo que si hace: rehacer la interfaz cuando se
        --  queda en un estado raro, sin salir del mundo.
        ReloadUI()
    elseif msg:sub(1, 6) == "ficha|" then
        --  Abre la ventana del conjunto (muneco grande, colores, precio).
        --  `pulsar|` es otra cosa: significa "pruebatelo", que es lo que hace
        --  el boton Ponerme de esa ventana.
        if PLARM.Emergente and PLARM.Emergente.Abrir then
            PLARM.Emergente.Abrir(tonumber(msg:sub(7)))
        end
    elseif msg:sub(1, 7) == "pulsar|" then
        --  🔴 PULSA LA CELDA DE VERDAD, NO UN EVENTO A MANO.
        --
        --  Antes disparaba `FICHA_PULSADA` con solo el id, y el manejador
        --  necesita ADEMAS la ranura. Sin ella no hace nada -- asi que la
        --  sonda decia «no pasa nada» tambien cuando el clic real funcionaba
        --  perfectamente. Un instrumento que no reproduce lo que hace el
        --  jugador mide otra cosa.
        --
        --    🎯 Para probar un clic, pulsa el boton; no imites lo que crees
        --       que el boton hace.
        local id = tonumber(msg:sub(8))
        local v = _G[NOMBRE_VENTANA]
        local hecho = false
        if v and v.coleccion and v.coleccion.fichas then
            for _, fi in ipairs(v.coleccion.fichas) do
                if fi and fi.datos and fi.datos.id == id then
                    PLARM.Eventos.Disparar("FICHA_PULSADA", fi.datos)
                    hecho = true
                    break
                end
            end
        end
        if not hecho then
            PLARM.Eventos.Disparar("FICHA_PULSADA", { id = id })
        end
        pcall(SendAddonMessage, PREFIJO,
              ("sonda|pulsar|%d celda=%s"):format(id, tostring(hecho)),
              "WHISPER", UnitName("player"))
    elseif msg:sub(1, 8) == "comprar|" then
        --  Para poder probar la compra sin que nadie tenga que hacer clic.
        PLARM.Contrato.Mandar("comprar|" .. msg:sub(9))
    elseif msg:sub(1, 8) == "pestana|" then
        --  Cambiar de pestana sin teclado, para poder probar Piezas, Armas,
        --  Guardados y Tienda desde SSH.
        local n = tonumber(msg:sub(9))
        local col = PLARM.Ventana and PLARM.Ventana.coleccion
        col = col or (_G["WoWPeru_Wardrobe_Frame"] and _G["WoWPeru_Wardrobe_Frame"].coleccion) or (_G["PeruLandArmarioV2"] and _G["PeruLandArmarioV2"].coleccion)
        if col and col.pestanas and col.pestanas[n] then col.pestanas[n].pulsar() end
    elseif msg == "aplicar" then
        if PLARM.Aplicar2 then PLARM.Aplicar2() end

    elseif msg:sub(1, 8) == "probarm|" then
        --  🔬 ¿DIBUJA `SetModel` UN ARMA SUELTA?
        --
        --  Es la pregunta que decide como se ensenan las armas. Ascension usa
        --  `SetDisplayInfo(<invisible>)` + `TryOn`, y aqui `SetDisplayInfo` no
        --  existe; se probo su equivalente `SetCreature(12999)` y **no dibuja
        --  nada** (el volcado de celdas confirmo que la rama si se ejecutaba:
        --  cat=15 en las cuatro). Queda `SetModel` con la ruta del `.m2`.
        --
        --    🎯 Antes de montar la tuberia --tabla, consulta, mensaje nuevo--
        --       se comprueba que la pieza final funciona. Construir primero y
        --       descubrir al final que la base no dibuja es el camino caro.
        --  🪤 POR EL CANAL VIAJA SOLO EL NOMBRE DEL ARCHIVO, SIN RUTA.
        --
        --  Las barras invertidas no sobreviven el viaje: MySQL las trata como
        --  escape, y esta consola tambien se las come. Una ruta llegaba como
        --  `ItemObjectComponentsWeaponx.mdx` -- sin dar error, y encima
        --  `GetModel()` contestaba que si, asi que la prueba parecia buena.
        --
        --    🎯 Cuando un caracter se pierde en tres capas distintas, no se
        --       escapa mejor: se deja de mandar. El prefijo es siempre el
        --       mismo, asi que lo pone quien lo necesita.
        local ruta = "Item\\ObjectComponents\\Weapon\\" .. msg:sub(9)
        local p = CreateFrame("DressUpModel", nil, UIParent)
        --  🔴 VISIBLE Y GRANDE, A PROPOSITO. `GetModel()` contesto que SI con
        --  una ruta que no existia: miente igual que `GetTexture`, que ya esta
        --  documentado. La unica comprobacion honesta aqui es CAPTURAR LA
        --  PANTALLA Y MIRARLA.
        p:SetSize(300, 300); p:SetPoint("CENTER"); p:SetAlpha(1); p:Show()
        p:SetLight(1, 0, -1, 1, -1, 1.05, 1, 1, 1, 0, 1, 1, 1)
        pcall(function() p:SetModel(ruta) end)
        --  ⚠️ Con espera: preguntar en el acto da vacio aunque funcione.
        local t = 0
        p:SetScript("OnUpdate", function(s, dt)
            t = t + dt
            if t < 1.5 then return end
            s:SetScript("OnUpdate", nil)
            local x = ""
            pcall(function() local r = s:GetModel(); x = type(r) == "string" and r or "" end)
            pcall(SendAddonMessage, PREFIJO,
                  "sonda|setmodel|" .. (x ~= "" and "SI" or "NO"),
                  "WHISPER", UnitName("player"))
        end)

    elseif msg:sub(1, 8) == "probarc|" then
        --  🔬 ¿FUNCIONA `TryOn` SOBRE UNA CRIATURA?
        --
        --  Es la pregunta que decide si la via de Ascension --el arma colgada
        --  de un portador invisible-- es posible aqui sin el DLL. Con la
        --  criatura invisible (12999) no se dibujo nada, pero eso admite DOS
        --  explicaciones opuestas:
        --
        --      · `TryOn` no funciona sobre criaturas  -> via muerta
        --      · funciona, y ese modelo concreto no vale -> hay que buscar otro
        --
        --  Se prueba con una criatura VISIBLE: si el arma aparece encima, la
        --  via existe y solo falta el portador adecuado.
        --
        --    🎯 Un experimento que puede salir mal por dos motivos distintos
        --       no ha probado nada. Se cambia UNA cosa cada vez.
        local cid, iid = msg:match("^probarc|(%d+)|(%d+)$")
        if cid then
            local p = CreateFrame("DressUpModel", nil, UIParent)
            p:SetSize(300, 300); p:SetPoint("CENTER"); p:SetAlpha(1); p:Show()
            p:SetLight(1, 0, -1, 1, -1, 1.05, 1, 1, 1, 0, 1, 1, 1)
            pcall(function()
                p:SetCreature(tonumber(cid))
                p:TryOn(tonumber(iid))
            end)
        end

    elseif msg:sub(1, 7) == "pagina|" then
        --  Cambiar de pagina sin raton: es el caso que fallaba (ir a la 2 y
        --  volver a la 1 dejaba las celdas con el personaje del jugador), asi
        --  que tiene que poder probarse sin depender de que alguien pulse.
        local n = tonumber(msg:sub(8))
        local v = _G[NOMBRE_VENTANA]
        if n and v and v.coleccion and v.coleccion.Refrescar then
            v.coleccion:Refrescar(n)
        end

    elseif msg:sub(1, 7) == "ranura|" then
        --  Elegir la ranura (0 cabeza, 4 pecho, 7 pies...) sin raton. Hace
        --  falta para poder COMPROBAR el encuadre por pieza: la pestana de
        --  piezas abre en armas, que son justo las que no se encuadran.
        local cat = tonumber(msg:sub(8))
        local v = _G[NOMBRE_VENTANA]
        if cat and v and v.coleccion and v.coleccion.ranuras then
            for _, b in ipairs(v.coleccion.ranuras) do
                if b.cat == cat and b.pulsar then b.pulsar() end
            end
        end

    elseif msg == "vestidos" then
        --  Cuantas veces se ha vestido CADA celda. Si sale mas de 1, algo la
        --  esta rehaciendo -- y cada rehecho es un parpadeo.
        local v = _G[NOMBRE_VENTANA]
        local partes = {}
        if v and v.coleccion and v.coleccion.fichas then
            for i = 1, math.min(9, #v.coleccion.fichas) do
                local fi = v.coleccion.fichas[i]
                partes[#partes + 1] = ("%d/%d"):format(
                    (fi and fi.vecesPoner) or 0, (fi and fi.vecesVestir) or 0)
            end
        end
        pcall(SendAddonMessage, PREFIJO,
              ("sonda|vestidos|poner/vestir %s"):format(table.concat(partes, " ")),
              "WHISPER", UnitName("player"))

    elseif msg == "pintado" then
        --  🔬 Cuantas veces se ha repintado la rejilla, y por que via.
        local x = PLARM._pinta
        pcall(SendAddonMessage, PREFIJO,
              x and string.format("sonda|pintado|refrescar=%d llenar=%d poner=%d apariencia=%d",
                                  x.refrescar, x.llenar, x.poner, x.apar)
                or "sonda|pintado|sin datos",
              "WHISPER", UnitName("player"))
    elseif msg == "pintado0" then
        PLARM._pinta = { refrescar = 0, llenar = 0, poner = 0, apar = 0 }
        pcall(SendAddonMessage, PREFIJO, "sonda|pintado|a cero",
              "WHISPER", UnitName("player"))

    elseif msg == "hielo" then
        --  🔬 QUE ESTA DECIDIENDO EL VIGIA DEL CONGELADO.
        --
        --  🔴 Existe porque «la ficha congelada y las celdas animadas» admite
        --  causas incompatibles que en pantalla se ven igual: el vigia no ve la
        --  ventana, no ve la ficha, decide bien y el DLL no aplica, o el DLL no
        --  esta. Preguntarlo cuesta un segundo; elegir de palabra costo dias.
        local h = PLARM._hielo
        if not h then
            pcall(SendAddonMessage, PREFIJO, "sonda|hielo|EL VIGIA NO CORRIO",
                  "WHISPER", UnitName("player"))
        else
            pcall(SendAddonMessage, PREFIJO,
                  string.format("sonda|hielo|vent=%s ficha=%s qui=%s ult=%s dll=%s/%s",
                      tostring(h.v), tostring(h.ficha), tostring(h.quiero),
                      tostring(h.ultimo), tostring(h.hayCong), tostring(h.hayDesc)),
                  "WHISPER", UnitName("player"))
        end

    elseif msg == "piel" then
        --  🔬 Apagar la composicion del personaje (el corte del nivel de en
        --  medio) y repintar la pagina para que las celdas se rehagan con el
        --  cuerpo sin componer. Es lo que hace su `SetModelApplyComponents`.
        --  🪤 NO SE REPINTA LA PAGINA DESDE AQUI. `Refrescar` pide filtro,
        --  pagina y nombres de golpe, y esa rafaga de mensajes de addon
        --  **desconecta al jugador** (son susurros, y a los 10 por segundo el
        --  servidor corta sin dejar rastro). Ya paso: la primera prueba de
        --  esta orden tiro la sesion.
        --
        --  Basta con apagar la bandera: las celdas se rehacen solas al cambiar
        --  de ranura, que es una orden aparte.
        if PeruLand_SinPiel then pcall(PeruLand_SinPiel) end
        if PeruLand_ContadorPiel then pcall(PeruLand_ContadorPiel) end
        pcall(SendAddonMessage, PREFIJO, "sonda|piel|composicion APAGADA y pagina repintada",
              "WHISPER", UnitName("player"))

    elseif msg == "pielon" then
        if PeruLand_ConPiel then pcall(PeruLand_ConPiel) end
        pcall(SendAddonMessage, PREFIJO, "sonda|piel|composicion encendida",
              "WHISPER", UnitName("player"))

    elseif msg:sub(1, 6) == "color|" then
        --  🔬 Pulsar la muestra de color N, que es lo unico que no se puede
        --  probar sin raton. Contesta cuantas hay y cual se pulso.
        local n = tonumber(msg:sub(7)) or 1
        local m = PLARM._muestras
        local hay = m and #m or 0
        if m and m[n] then
            local f = m[n]:GetScript("OnClick")
            if f then pcall(f, m[n]) end
        end
        pcall(SendAddonMessage, PREFIJO,
              string.format("sonda|color|muestras=%d pulsada=%d", hay, n),
              "WHISPER", UnitName("player"))

    elseif msg == "verruleta" then
        --  🔬 DEJAR EL AVISO DE CARGA FIJO Y CONTARLO TODO.
        --
        --  «No se ve» admite varias causas que en pantalla son identicas: que
        --  el marco no se muestre, que la textura no cargue, que tenga tamaño
        --  cero, que este transparente o que este tapada. Y el aviso real dura
        --  menos de un segundo, asi que ni da tiempo a mirarlo.
        --
        --  Esto lo fuerza a quedarse, y ademas pone en la SEGUNDA celda una
        --  textura de control que se sabe que funciona (el icono de un objeto):
        --  si esa se ve y la otra no, el problema es la textura, no el marco.
        local v = _G[NOMBRE_VENTANA]
        local info = "sin celdas"
        if v and v.coleccion and v.coleccion.fichas then
            local fs = v.coleccion.fichas
            for i, fi in ipairs(fs) do
                if fi and fi.cargando then
                    fi.cargando:Show()
                    if i == 2 and fi.cargando.ruleta then
                        fi.cargando.ruleta:SetTexture("Interface\Icons\INV_Misc_QuestionMark")
                        fi.cargando.ruleta:SetBlendMode("BLEND")
                    end
                end
            end
            local f1 = fs[1]
            if f1 and f1.cargando and f1.cargando.ruleta then
                local r = f1.cargando.ruleta
                info = string.format("marco=%s tex=%s ancho=%.0f alto=%.0f alpha=%.2f nivel=%d",
                    tostring(f1.cargando:IsShown()),
                    tostring(r:GetTexture()):sub(-28),
                    r:GetWidth() or -1, r:GetHeight() or -1,
                    r:GetAlpha() or -1, f1.cargando:GetFrameLevel())
            end
        end
        pcall(SendAddonMessage, PREFIJO, "sonda|verruleta|" .. info,
              "WHISPER", UnitName("player"))

    elseif msg == "ruleta" then
        local v = _G[NOMBRE_VENTANA]
        local vis = 0
        if v and v.coleccion and v.coleccion.fichas then
            for _, fi in ipairs(v.coleccion.fichas) do
                if fi and fi.cargando and fi.cargando:IsShown() then vis = vis + 1 end
            end
        end
        pcall(SendAddonMessage, PREFIJO,
              string.format("sonda|ruleta|anima=%s visibles=%d",
                            tostring(PLARM.RULETA_ANIMA), vis),
              "WHISPER", UnitName("player"))

    elseif msg == "fichapj" then
        --  🔬 Abrir la ficha del personaje y decir QUE OBJETO ve el cliente en
        --  cada ranura. Sirve para comprobar que el cosmetico no ha tocado el
        --  equipo: los numeros de aqui tienen que ser los mismos que los de
        --  `character_inventory`.
        pcall(function() ToggleCharacter("PaperDollFrame") end)
        local partes = {}
        for _, r in ipairs({0,2,3,4,5,6,7,8,9,14,15,16,17}) do
            local id = GetInventoryItemID("player", r + 1)   -- 1-based en Lua
            if id then partes[#partes + 1] = r .. "=" .. id end
        end
        pcall(SendAddonMessage, PREFIJO,
              "sonda|fichapj|" .. table.concat(partes, " "),
              "WHISPER", UnitName("player"))

    elseif msg == "clavar" then
        --  🔬 EL CONGELADO DE ASCENSION, BIEN HECHO.
        --
        --  Su comentario dice *«esto se vera a saltos si la animacion tiene
        --  mucho movimiento»*. Un congelado que produce saltos **no para el
        --  motor**: fija el instante en cada fotograma y el motor sigue
        --  avanzando entre medias. Eso si existe en 3.3.5a.
        --
        --  🪤 Ya se intento una vez y «vibraba»: porque se clavaba en un
        --  instante que cambiaba. Clavado SIEMPRE en el mismo, no vibra.
        local v = _G[NOMBRE_VENTANA]
        local n = 0
        if v and v.coleccion and v.coleccion.fichas then
            for _, fi in ipairs(v.coleccion.fichas) do
                local m = fi and fi.modelo
                if m and not fi.clavado then
                    fi.clavado = CreateFrame("Frame")
                    fi.clavado:SetScript("OnUpdate", function()
                        pcall(function() m:SetSequenceTime(0, 0) end)
                    end)
                    n = n + 1
                end
            end
        end
        pcall(SendAddonMessage, PREFIJO, "sonda|clavar|" .. n .. " celdas clavadas",
              "WHISPER", UnitName("player"))

    elseif msg == "tiempo" then
        --  🔬 ¿`SetSequenceTime` congela el muñeco, como su `FreezeSequence`?
        --
        --  De las nueve funciones que usa su interfaz, solo TRES estan en su
        --  DLL (`SetModelApplyComponents`, `C_UICamera`, `SetSpellVisual`).
        --  `FreezeSequence` es **Lua suyo**, y su comentario -«se vera a
        --  saltos si la animacion tiene mucho movimiento»- dice que congelan
        --  en el instante actual. En 3.3.5a eso es `SetSequenceTime`.
        local v = _G[NOMBRE_VENTANA]
        local n = 0
        if v and v.coleccion and v.coleccion.fichas then
            for _, fi in ipairs(v.coleccion.fichas) do
                local m = fi and fi.modelo
                if m then
                    if pcall(function() m:SetSequenceTime(0, 0) end) then n = n + 1 end
                end
            end
        end
        pcall(SendAddonMessage, PREFIJO,
              "sonda|tiempo|aplicado a " .. n .. " celdas",
              "WHISPER", UnitName("player"))

    elseif msg == "descongelar" then
        --  🔬 Apagar la bandera GLOBAL para poder probar el congelado por
        --  muñeco. Sin esto la prueba miente: los muñecos ya estan a
        --  velocidad 0 y `FreezeSequence` no tiene nada que hacer -- salio
        --  `congelados=0 fallos=18` y parecia que el offset estaba mal.
        --
        --    🎯 Para medir si algo congela, primero hay que asegurarse de que
        --       se estaba moviendo.
        if PeruLand_Descongelar then pcall(PeruLand_Descongelar) end
        pcall(SendAddonMessage, PREFIJO, "sonda|descongelar|bandera global apagada",
              "WHISPER", UnitName("player"))

    elseif msg == "freeze" then
        --  🔬 ¿Existe `FreezeSequence` como metodo del muñeco, y congela?
        --
        --  Se prueba sobre las celdas de verdad y se pide el contador del DLL,
        --  que dice cuantas congelo y que velocidad leyo. Sin eso, «no se
        --  mueve» y «no se ejecuta» se ven igual en pantalla.
        local v = _G[NOMBRE_VENTANA]
        local hay, ok, err = 0, 0, 0
        local errTexto = nil
        if v and v.coleccion and v.coleccion.fichas then
            for _, fi in ipairs(v.coleccion.fichas) do
                local m = fi and fi.modelo
                if m and type(m.FreezeSequence) == "function" then
                    hay = hay + 1
                    local bien, e = pcall(function() m:FreezeSequence() end)
                    if bien then ok = ok + 1
                    else err = err + 1; errTexto = errTexto or tostring(e) end
                end
            end
        end
        pcall(SendAddonMessage, PREFIJO,
              string.format("sonda|freeze|en=%d ok=%d err=%d | %s", hay, ok, err,
                            (errTexto or "sin error"):gsub("[|]", "/"):sub(1, 150)),
              "WHISPER", UnitName("player"))
        if PeruLand_ContadorCongelar then pcall(PeruLand_ContadorCongelar) end

    elseif msg == "contador" then
        if PeruLand_ContadorComponentes then PeruLand_ContadorComponentes() end

    elseif msg:sub(1, 5) == "item|" then
        --  🔬 ¿EL CLIENTE PUEDE RESOLVER ESTE OBJETO, SI O NO?
        --  Pide el objeto a pelo y contesta 2 s despues. Separa «el armario no
        --  lo pide» de «lo pide y el servidor no contesta», que en pantalla se
        --  ven igual: la celda girando.
        --  🪤 SIN `PLARM.Tras` NI `CreateFrame` CON NOMBRE. La primera version
        --  usaba las dos cosas y **no contesto nunca**: los errores de Lua
        --  vienen apagados de fabrica en este cliente, asi que un fallo aqui
        --  se ve exactamente igual que "la orden no llego". Reloj propio.
        local id = tonumber(msg:sub(6)) or 0
        local antes = GetItemInfo(id) and "ya" or "no"
        local ok = pcall(function() sondaItem:SetHyperlink("item:" .. id) end)
        pcall(SendAddonMessage, PREFIJO,
              ("sonda|item|%d recibida antes=%s hyperlink=%s"):format(
                  id, antes, tostring(ok)),
              "WHISPER", UnitName("player"))
        local reloj = CreateFrame("Frame")
        local hasta = GetTime() + 2
        reloj:SetScript("OnUpdate", function(s)
            if GetTime() < hasta then return end
            s:SetScript("OnUpdate", nil)
            pcall(SendAddonMessage, PREFIJO,
                  ("sonda|item|%d despues=%s"):format(
                      id, tostring(GetItemInfo(id))),
                  "WHISPER", UnitName("player"))
        end)

    elseif msg == "preview" then
        --  🔬 QUE PASA AL PULSAR UN ARMA O UN COLOR. Tres cosas distintas que
        --  en pantalla se ven igual -- «no pasa nada»-- y se arreglan en
        --  sitios opuestos:
        --      montaje vacio      -> el clic no llego / falto la ranura
        --      montaje con id     -> llego, mirar si el cliente conoce el id
        --      muneco sin modelo  -> llego, se conoce, y el TryOn no pinto
        local v = _G[NOMBRE_VENTANA]
        local m = v and v.modeloGrande
        local trozos = {}
        for cat, id in pairs((v and v.montaje) or {}) do
            trozos[#trozos + 1] = ("%s=%s%s"):format(
                tostring(cat), tostring(id),
                GetItemInfo(id) and "" or "(SIN-INFO)")
        end
        local ruta = "sin-muneco"
        if m then
            pcall(function()
                local x = m:GetModel()
                ruta = (type(x) == "string" and x ~= "") and "ARMADO" or "VACIO"
            end)
        end
        pcall(SendAddonMessage, PREFIJO,
              ("sonda|preview|%s|montaje: %s"):format(
                  ruta, (#trozos > 0 and table.concat(trozos, " ") or "VACIO")),
              "WHISPER", UnitName("player"))

    elseif msg == "nombres" then
        --  🔬 ¿EL NOMBRE NO LLEGA, O LLEGA TARDE?  Se pregunta AHORA por las
        --  celdas que salieron con "...". Si ahora si hay nombre, el dato
        --  llegaba tarde y lo que falta es reintentar (como ya se hace con el
        --  icono); si sigue vacio, el servidor no lo manda.
        local v = _G[NOMBRE_VENTANA]
        local partes = {}
        if v and v.coleccion and v.coleccion.fichas then
            for i = 1, #v.coleccion.fichas do
                local fi = v.coleccion.fichas[i]
                local d = fi and fi.datos
                if d and d.id and #partes < 4 then
                    local puesto = fi.nombre and fi.nombre:GetText() or "?"
                    if puesto == "..." or puesto == "" then
                        local _, _, n = C_Appearance.GetAppearanceDisplayInfo(d.id)
                        partes[#partes + 1] = d.id .. ":ahora=" .. tostring(n)
                    end
                end
            end
        end
        pcall(SendAddonMessage, PREFIJO,
              "sonda|nombres|" .. (#partes > 0 and table.concat(partes, " ")
                                   or "todas con nombre"),
              "WHISPER", UnitName("player"))

    elseif msg == "pendientes" then
        --  🔬 POR QUE NO SE VISTE UNA CELDA. Son TRES causas distintas que en
        --  pantalla se ven igual -la celda girando- y se arreglan en sitios
        --  opuestos:
        --
        --      sin-id    el servidor no mando la pieza  -> mirar el catalogo
        --      sin-info  el cliente no resuelve el item -> falta en item_template
        --      con-info  se resuelve y aun asi no viste -> es el addon
        --
        --  Sin separarlas se vuelve al mismo bucle de parchar a ciegas que ya
        --  costo veinte intentos.
        local v = _G[NOMBRE_VENTANA]
        local partes = {}
        if v and v.coleccion and v.coleccion.fichas then
            --  🔬 UNA CELDA QUE SI FUNCIONA, DE CONTROL.
            --  Sin ella, un "sin-id" en todas no distingue «el servidor no
            --  manda la pieza» de «la sonda mira el campo equivocado» -- que
            --  es justo lo que paso el primer intento: leia `fi.entrada` y el
            --  campo se llama `fi.datos`, asi que TODO salia sin-id.
            local function ver(i, fi)
                local d = fi and fi.datos
                local id = d and d.id
                if not id then return i .. ":sin-id" end
                if not GetItemInfo(id) then return i .. ":" .. id .. ":sin-info" end
                return i .. ":" .. id .. ":con-info"
            end
            for i = 1, #v.coleccion.fichas do
                local fi = v.coleccion.fichas[i]
                if fi and fi.vestida and not partes.control then
                    partes.control = true
                    partes[#partes + 1] = "OK" .. ver(i, fi)
                end
            end
            for i = 1, #v.coleccion.fichas do
                local fi = v.coleccion.fichas[i]
                if fi and not fi.vestida and #partes < 5 then
                    partes[#partes + 1] = ver(i, fi)
                end
            end
        end
        pcall(SendAddonMessage, PREFIJO,
              "sonda|pendientes|" .. (table.concat(partes, " ") ~= "" and
              table.concat(partes, " ") or "ninguna"),
              "WHISPER", UnitName("player"))

    elseif msg == "celdas" then
        --  🔬 QUE HAY DE VERDAD EN CADA CELDA: id, categoria y nombre.
        --
        --  🔴 Existe porque la rejilla enseno cascos con nombres de arma, y
        --  eso admite varias explicaciones incompatibles --el servidor manda
        --  mal la categoria / la celda la lee mal / el nombre llega tarde y se
        --  cruza--. Se pueden pasar horas eligiendo entre ellas de palabra.
        --
        --    🎯 Cuando dos hipotesis igual de razonables explican lo mismo,
        --       deja de razonar y saca el dato. Aqui son cuatro lineas.
        local v = _G[NOMBRE_VENTANA]
        local partes = {}
        if v and v.coleccion and v.coleccion.fichas then
            --  🪤 SOLO CUATRO, Y CORTO. Un mensaje de addon pasado de 255
            --  bytes se DESCARTA sin dar error: la primera version mandaba
            --  seis celdas con su nombre entero y no llego nunca -- y el
            --  acuse decia que la orden si se habia ejecutado, o sea que el
            --  instrumento parecia bien y el dato no aparecia.
            --  🔬 LO QUE HAY QUE SABER: cuales se VISTIERON de verdad.
            --  Se reporta una letra por celda -- V vestida, . no-- porque el
            --  sintoma («salen repetidos») no distingue «no se visitio» de
            --  «se vistio mal», y son arreglos distintos.
            local est = {}
            for i = 1, #v.coleccion.fichas do
                local fi = v.coleccion.fichas[i]
                est[#est + 1] = (fi and fi.vestida) and "V" or "."
            end
            partes[#partes + 1] = table.concat(est)
        end
        pcall(SendAddonMessage, PREFIJO,
              "sonda|celdas|" .. table.concat(partes, " ~ "),
              "WHISPER", UnitName("player"))

    elseif msg:sub(1, 9) == "encuadre|" then
        --  🔬 CALIBRAR EL ENCUADRE SIN REINICIAR EL CLIENTE.
        --
        --  `encuadre|<cat>|<x>|<y>|<z>` cambia como se ve esa ranura y
        --  repinta la rejilla. `cat` puede ser un numero (0 cabeza, 4 pecho,
        --  7 pies, 15 armas...) o la palabra CONJUNTO.
        --
        --  🔴 Existe porque los numeros del encuadre **no se pueden razonar**:
        --  `SetPosition` mueve el modelo respecto a la camara y donde acaba un
        --  arma depende del hueso que la sujeta. La unica forma honesta de dar
        --  con ellos es probar y MIRAR. Sin esto, cada intento costaba cerrar
        --  el juego, copiar, abrir y volver a entrar: minuto y medio por
        --  numero, y son cuatro numeros por cada una de trece ranuras.
        --
        --    🎯 Cuando un valor solo se puede encontrar mirando, lo que hay
        --       que construir primero es la forma de mirar rapido.
        --  El cuarto numero es la ESCALA, que es lo que de verdad acerca:
        --  `SetPosition` solo desplaza. Opcional, para no romper ordenes viejas.
        local c, x, y, z, esc = msg:match(
            "^encuadre|([^|]+)|([%-%d%.]+)|([%-%d%.]+)|([%-%d%.]+)|?([%-%d%.]*)$")
        if c and PLARM.Ficha and PLARM.Ficha.ENCUADRE then
            local clave = tonumber(c) or c
            PLARM.Ficha.ENCUADRE[clave] = { tonumber(x), tonumber(y), tonumber(z),
                                            tonumber(esc) or 1.0 }
            --  🪤 `Refrescar` SOLO NO BASTA: la celda tiene un atajo que se
            --  salta el vestido si ya esta puesta (`Ficha.lua:314`), asi que
            --  repintar sin mas dejaba la rejilla exactamente igual y parecia
            --  que la calibracion no llegaba. Hay que soltar esa marca.
            --
            --    🎯 Un atajo que evita trabajo repetido tambien evita el
            --       trabajo que SI quieres repetir. Al calibrar, quitalo.
            local v = _G[NOMBRE_VENTANA]
            if v and v.coleccion then
                for _, fi in ipairs(v.coleccion.fichas or {}) do fi.vestida = false end
                if v.coleccion.Refrescar then v.coleccion:Refrescar() end
            end
        end
    end

    --  🔴🔴 SOLO SE ACUSAN LAS ORDENES DE PRUEBA, NUNCA EL PROTOCOLO.
    --
    --  Por este mismo canal llegan las respuestas del servidor (`filtro|`,
    --  `pag|`, `nom|`...). La primera version acusaba TODO lo que entraba, y
    --  con eso **cada respuesta del servidor generaba un mensaje de vuelta**:
    --  el trafico se duplicaba solo.
    --
    --  Eso no es un detalle: los mensajes de addon son susurros y el servidor
    --  corta al jugador a los 10 por segundo, **sin caida, sin aviso y sin una
    --  linea en ningun registro**. Es lo que ya boto al dueno varias veces y
    --  costo dias encontrar. Se vio en el propio acuse:
    --
    --      ack|filtro|21|32|32|2|32|ventana=si|pestana=2     <- de mas
    --      ack|pag|22|1|2/2|913274:1:4:0:15,...              <- de mas
    --
    --    🎯 Una herramienta de diagnostico que anade trafico puede CAUSAR el
    --       fallo que intenta medir. El instrumento tiene que ser mudo salvo
    --       cuando se le pregunta.
    if ORDENES_DE_PRUEBA[msg] or msg:match("^(%a+)|") and ORDENES_DE_PRUEBA[msg:match("^(%a+)|")] then
        local f = CreateFrame("Frame")
        local t = 0
        f:SetScript("OnUpdate", function(s, dt)
            t = t + dt
            if t < 1.2 then return end
            s:SetScript("OnUpdate", nil)
            Acuse(msg)
        end)
    end
end)

SLASH_PLSONDA1 = "/sonda"          -- 🪤 sin guion bajo, o no queda registrado
SlashCmdList["PLSONDA"] = Informe

if PLARM and PLARM.Diag then PLARM.Diag("cargado: Sonda") end
