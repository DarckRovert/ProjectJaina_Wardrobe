--  🎬 TRANSICION ENTRE VENTANAS DEL ECOSISTEMA WOW PERÚ
--  Efecto de fundido cruzado suave entre el Armario, la Tienda y el Pase.
if WoWPeru_Cruzar or PeruLand_Cruzar then return end

local SALIDA, ENTRADA = 0.30, 0.35

local function Fundir(f, desde, hasta, dura, alFinal)
    local t = 0
    f:SetAlpha(desde)
    local reloj = f.__wpFundido or f.__plFundido or CreateFrame("Frame")
    f.__wpFundido = reloj
    reloj:SetScript("OnUpdate", function(r, e)
        t = t + e
        local k = t / dura
        if k >= 1 then
            r:SetScript("OnUpdate", nil)
            f:SetAlpha(hasta)
            if alFinal then alFinal() end
            return
        end
        --  suave al principio y al final
        k = k * k * (3 - 2 * k)
        f:SetAlpha(desde + (hasta - desde) * k)
    end)
end

--- La ventana aparece desde transparente. Seguro de llamar siempre.
function WoWPeru_Aparecer(f)
    if not f or not f.SetAlpha then return end
    Fundir(f, 0, 1, ENTRADA)
end
PeruLand_Aparecer = WoWPeru_Aparecer

--- Desvanece `origen`, lo esconde y luego llama a `abrir`.
function WoWPeru_Cruzar(origen, abrir)
    if not origen or not origen:IsShown() then
        if abrir then abrir() end
        return
    end
    local raton = origen.IsMouseEnabled and origen:IsMouseEnabled()
    if raton then origen:EnableMouse(false) end
    if abrir then abrir() end
    Fundir(origen, origen:GetAlpha() or 1, 0, SALIDA, function()
        origen:Hide()
        origen:SetAlpha(1)
        if raton then origen:EnableMouse(true) end
    end)
end
PeruLand_Cruzar = WoWPeru_Cruzar

