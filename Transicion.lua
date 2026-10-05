--  🎬 TRANSICION ENTRE EL ARMARIO Y EL PASE (26-09-2026)
--
--  El dueño: *«cuando estoy en el armario y le doy al pase, se cierra y se
--  abre todo muy bruscamente»*. Ahora la ventana que se va se desvanece y la
--  que llega aparece con un fundido.
--
--  🔑 El MISMO archivo va en PeruLandArmario y en PeruLandPase: el que cargue
--     primero define las funciones y el otro no las pisa. Asi funciona aunque
--     uno de los dos addons no este.
if PeruLand_Cruzar then return end

--  🪤 La primera version (0,12 s fuera, hueco, 0,20 s dentro) era «un
--     parpadeo practicamente» (el dueño). Ahora es un fundido CRUZADO: la
--     nueva empieza a aparecer mientras la vieja se va, sin pantalla vacia.
local SALIDA, ENTRADA = 0.30, 0.35

local function Fundir(f, desde, hasta, dura, alFinal)
    local t = 0
    f:SetAlpha(desde)
    local reloj = f.__plFundido or CreateFrame("Frame")
    f.__plFundido = reloj
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
function PeruLand_Aparecer(f)
    if not f or not f.SetAlpha then return end
    Fundir(f, 0, 1, ENTRADA)
end

--- Desvanece `origen`, lo esconde y luego llama a `abrir`.
function PeruLand_Cruzar(origen, abrir)
    if not origen or not origen:IsShown() then
        if abrir then abrir() end
        return
    end
    local raton = origen.IsMouseEnabled and origen:IsMouseEnabled()
    if raton then origen:EnableMouse(false) end
    --  La nueva se abre YA (y se funde desde 0 con PeruLand_Aparecer); la
    --  vieja se desvanece a la vez y se esconde al llegar a 0.
    if abrir then abrir() end
    Fundir(origen, origen:GetAlpha() or 1, 0, SALIDA, function()
        origen:Hide()
        origen:SetAlpha(1)
        if raton then origen:EnableMouse(true) end
    end)
end
