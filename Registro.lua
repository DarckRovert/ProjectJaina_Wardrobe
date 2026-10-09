--[[
    ProjectJaina_Wardrobe - Registro.lua
    Sistema de diagnóstico y registro local pasivo de Project Jaina.
    100% libre de telemetría invasiva y libre de manipulación de seterrorhandler.
]]

local PREFIJO = "WP_WARDROBE"

Wanos_Wardrobe_Registro = Wanos_Wardrobe_Registro or ProjectJaina_Wardrobe_Registro or {}
        ProjectJaina_Wardrobe_Registro = Wanos_Wardrobe_Registro

local guardado = ProjectJaina_Wardrobe_Registro
local vistos = {}

--- Apunta un registro local de diagnóstico (error, carga, aviso).
local function Apuntar(clase, texto)
    texto = tostring(texto):gsub("[\r\n|]", " "):sub(1, 180)
    local firma = clase .. texto:sub(1, 60)

    vistos[firma] = (vistos[firma] or 0) + 1
    local n = vistos[firma]
    if n ~= 1 and n ~= 10 and n ~= 100 then return end

    local linea = string.format("%s|%s%s", clase, texto, n > 1 and (" (x" .. n .. ")") or "")

    guardado = guardado or {}
    guardado[#guardado + 1] = date("%H:%M:%S") .. " " .. linea
    while #guardado > 80 do table.remove(guardado, 1) end
end

-- Exportar para uso interno del addon
ProjectJaina_Wardrobe_Apuntar = Apuntar
PeruLandArmarioApuntar = Apuntar -- Compatibilidad con módulos internos heredados

-- ---------------------------------------------------------------------------
-- Control de Carga y Diagnóstico Local
-- ---------------------------------------------------------------------------
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, evento, cual)
    if evento == "ADDON_LOADED" and (cual == "Wanos_Wardrobe" or cual == "ProjectJaina_Wardrobe") then
        Wanos_Wardrobe_Registro = Wanos_Wardrobe_Registro or ProjectJaina_Wardrobe_Registro or {}
        ProjectJaina_Wardrobe_Registro = Wanos_Wardrobe_Registro
        guardado = ProjectJaina_Wardrobe_Registro
        Apuntar("carga", "ProjectJaina_Wardrobe inicializado correctamente.")
    elseif evento == "PLAYER_ENTERING_WORLD" then
        local piezas = {}
        for nombre, existe in pairs({
            Estilo    = PLARM ~= nil,
            Sonda     = PLARM and PLARM.MedirLimites ~= nil or _G.SlashCmdList["PLSONDA"] ~= nil,
            Limites   = PLARM and PLARM.MedirLimites ~= nil,
            Contrato  = PLARM and PLARM.Contrato ~= nil,
            Ficha     = PLARM and PLARM.Ficha ~= nil,
            Ventana   = PLARM and PLARM.Abrir2 ~= nil,
        }) do
            piezas[#piezas + 1] = nombre .. (existe and "=si" or "=NO")
        end
        table.sort(piezas)
        Apuntar("modulos", table.concat(piezas, " "))
    end
end)
