--  ---------------------------------------------------------------------------
--  LA FICHA DE PERSONAJE: que se vea TU objeto, no el cosmetico
--  ---------------------------------------------------------------------------
--
--  🔴 ESTO YA ESTABA ARREGLADO Y SE PERDIO. El arreglo vivia dentro de
--  `Armario.lua`; cuando se retiro el armario viejo del `.toc` se fue con el,
--  y nadie lo movio. El dueño lo dijo antes que nadie: *«esto es algo que
--  solucionamos antes y que luego malogramos con un nuevo metodo»*.
--
--    🎯 Al retirar un archivo hay que mirar QUE MAS hacia. Un fichero viejo
--       casi nunca contiene solo lo viejo: contiene tambien los arreglos que
--       se le fueron pegando, y esos se van con el sin dar ningun error.
--
--  🔑 LA CAUSA, medida dentro del juego el 2026-08-30 con el pecho real 51275
--  y la apariencia 911700 encima:
--
--      GetInventoryItemID("player", 5)       -> 51275              (el REAL)
--      GetInventoryItemTexture("player", 5)  -> icono del 911700   (el FALSO)
--
--  Las dos NO coinciden: el id sale del objeto de verdad y la textura del
--  campo de apariencia. O sea que en 3.3.5a **el icono de la ficha lo pinta el
--  cosmetico**, y por eso la ficha mentia sobre lo que llevas puesto -- las
--  estadisticas y el tooltip siempre fueron los tuyos.
--
--  Ascension no hace esto: su cosmetico solo se ve en el modelo 3D.
--
--  ⚠️ Se usa `hooksecurefunc` y NUNCA se sustituye la funcion de Blizzard.
--  Sustituirla contamina la cadena y bloquea las acciones protegidas del juego.
--
--  🪤 Y la ranura de un boton de la ficha es `boton:GetID()`, no `boton.slot`.
--  Una version anterior usaba `boton.slot` -- que no existe-- y salia por el
--  primer `return` sin dar ningun error, asi que parecia instalada.
--  ---------------------------------------------------------------------------

local function ArreglarIconoFicha(boton)
    if not boton or not boton.GetID then return end
    local ranura = boton:GetID()
    if not ranura then return end

    local id = GetInventoryItemID("player", ranura)
    if not id then return end                    -- ranura vacia: dejar el hueco

    local icono = GetItemIcon(id)
    if not icono then return end

    local textura = _G[boton:GetName() .. "IconTexture"]
    if textura then textura:SetTexture(icono) end
end

if PaperDollItemSlotButton_Update then
    hooksecurefunc("PaperDollItemSlotButton_Update", ArreglarIconoFicha)
end

--  Marca de carga: si este archivo revienta, su linea NO sale.
local log = WoWPeru_Wardrobe_Apuntar or PeruLandArmarioApuntar
if log then
    log("carga", "FichaPersonaje.lua")
end

--  ---------------------------------------------------------------------------
--  Y LA RANURA VACIA: NI ICONO NI TOOLTIP  (07-09-2026)
--  ---------------------------------------------------------------------------
--  🔴 ESTO SE PERDIO POR SEGUNDA VEZ, Y DE LA MISMA FORMA.
--
--  `ArreglarIconoFicha`, aqui arriba, sale por su primer `return` cuando la
--  ranura esta VACIA -- y esa es justo la que hay que limpiar. Arregla la
--  ranura con objeto y deja intacta la que miente.
--
--  Con el cosmetico pintandose lleve o no la pieza (07-09-2026), al dueno le
--  salieron en la ficha el yelmo, las hombreras y hasta el tooltip completo
--  del «Ashbringer de Fuego - roja» en ranuras que tenia vacias. Su frase:
--  *«MIL VECES TE HE DICHO: LA APARIENCIA NO MODIFICA EQUIPO, SOLO ES
--  VISUAL»*. Y tenia razon: el equipo REAL nunca cambio -- se comprobo en la
--  base, GearScore 242-- pero la ficha decia otra cosa.
--
--    🎯 Al partir un archivo en varios, lo que se pierde no es lo que estabas
--       mirando: es lo de al lado. La primera vez se perdio entero al sacar
--       `Armario.lua` del `.toc`; la segunda se copio la mitad.
--
--  `GetInventoryItemID` lee el inventario DE VERDAD, asi que devuelve nil en
--  una ranura vacia aunque tenga cosmetico encima. Con eso se sabe cual hay
--  que dejar en blanco.
--  ---------------------------------------------------------------------------

local HUECO_VACIO = {
    [1]  = "HEAD",     [2]  = "NECK",      [3]  = "SHOULDER", [4]  = "SHIRT",
    [5]  = "CHEST",    [6]  = "WAIST",     [7]  = "LEGS",     [8]  = "FEET",
    [9]  = "WRISTS",   [10] = "HANDS",     [11] = "FINGER",   [12] = "FINGER",
    [13] = "TRINKET",  [14] = "TRINKET",   [15] = "CHEST",    [16] = "MAINHAND",
    [17] = "SECONDARYHAND", [18] = "RANGED", [19] = "TABARD",
}

local function LimpiarRanuraVacia(boton)
    if not boton or not boton.GetID then return end
    local ranura = boton:GetID()
    if not ranura then return end
    if GetInventoryItemID("player", ranura) then return end   -- lleva algo: no tocar

    --  🩤 NO SE INVENTA LA RUTA DE LA TEXTURA.
    --
    --  La primera version ponia "Interface/PaperDoll/UI-PaperDoll-Slot-HEAD"
    --  a mano.  con una ruta que no existe **no da error y no
    --  cambia nada**, asi que el icono del cosmetico seguia ahi y parecia que
    --  la limpieza no se ejecutaba -- cuando si lo hacia (el tooltip si
    --  desaparecio).
    --
    --  Blizzard guarda la textura del hueco en el propio boton
    --  () y la usa en .
    --  Se usa la suya: es la correcta para cada ranura, sin adivinar.
    if boton.backgroundTextureName then
        SetItemButtonTexture(boton, boton.backgroundTextureName)
    else
        local textura = _G[boton:GetName() .. "IconTexture"]
        if textura then textura:SetTexture(nil) end
    end
end

if PaperDollItemSlotButton_Update then
    hooksecurefunc("PaperDollItemSlotButton_Update", LimpiarRanuraVacia)
end

--  El tooltip: sin objeto real no hay nada que contar. Sin esto sale la ficha
--  entera de un arma que no llevas, con su dano y su GearScore.
if PaperDollItemSlotButton_OnEnter then
    hooksecurefunc("PaperDollItemSlotButton_OnEnter", function(boton)
        if boton and boton.GetID and not GetInventoryItemID("player", boton:GetID()) then
            GameTooltip:Hide()
        end
    end)
end
