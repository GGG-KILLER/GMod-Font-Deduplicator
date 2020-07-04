local fontsByParameters = {}
local fontsByAliases = {
    ['DebugFixed'] = 'DebugFixed',
    ['DebugFixedSmall'] = 'DebugFixedSmall',
    ['Default'] = 'Default',
    ['Marlett'] = 'Marlett',
    ['Trebuchet18'] = 'Trebuchet18',
    ['Trebuchet24'] = 'Trebuchet24',
    ['HudHintTextLarge'] = 'HudHintTextLarge',
    ['HudHintTextSmall'] = 'HudHintTextSmall',
    ['CenterPrintText'] = 'CenterPrintText',
    ['HudSelectionText'] = 'HudSelectionText',
    ['CloseCaption_Normal'] = 'CloseCaption_Normal',
    ['CloseCaption_Bold'] = 'CloseCaption_Bold',
    ['CloseCaption_BoldItalic'] = 'CloseCaption_BoldItalic',
    ['ChatFont'] = 'ChatFont',
    ['TargetID'] = 'TargetID',
    ['TargetIDSmall'] = 'TargetIDSmall',
    ['HL2MPTypeDeath'] = 'HL2MPTypeDeath',
    ['BudgetLabel'] = 'BudgetLabel',
    ['HudNumbers'] = 'HudNumbers'
}
local clamp = math.Clamp

local function btoi(bool) return bool and 1 or 0 end

local function generateKeyForFontData(fontData)
    assert(type(fontData) == 'table', 'bar argument #1 to \'generateKeyForFontData\' (table expected, got ' .. type(fontData) .. ')')

    return string.format('font:%s'
                         .. '|extended:%d'
                         .. '|size:%d'
                         .. '|weight:%d'
                         .. '|blursize:%d'
                         .. '|scanlines:%d'
                         .. '|antialias:%d'
                         .. '|underline:%d'
                         .. '|italic:%d'
                         .. '|strikeout:%d'
                         .. '|symbol:%d'
                         .. '|rotary:%d'
                         .. '|shadow:%d'
                         .. '|additive:%d'
                         .. '|outline:%d',
                         fontData.font or 'Arial',
                         btoi(fontData.extended or false),
                         clamp(fontData.size or 13, 4, 255),
                         fontData.weight or 500,
                         clamp(fontData.blursize or 0, 0, 80),
                         fontData.scanlines or 0,
                         btoi(fontData.antialias or true),
                         btoi(fontData.underline or false),
                         btoi(fontData.italic or false),
                         btoi(fontData.strikeout or false),
                         btoi(fontData.symbol or false),
                         btoi(fontData.rotary or false),
                         btoi(fontData.shadow or false),
                         btoi(fontData.additive or false),
                         btoi(fontData.outline or false))
end

--[[==================================================]]
--[[          Detouring of library functions          ]]
--[[==================================================]]

--[[============================]]
--[[ Detour: surface.CreateFont ]]
--[[============================]]
local surface_CreateFont = surface.CreateFont
function surface.CreateFont(fontName, fontData)
    assert(type(fontName) == 'string', 'bad argument #1 to \'surface.CreateFont\' (string expected, got ' .. type(fontName) .. ')')
    assert(type(fontData) == 'table', 'bad argument #2 to \'surface.CreateFont\' (table expected, got ' .. type(fontData) .. ')')

    if fontsByAliases[fontName] then
        error('A font with this name has already been created', 2)
    else
        local key = generateKeyForFontData(fontData)
        if fontsByParameters[key] then
            local created = fontsByParameters[key]
            fontsByAliases[fontName] = created
        else
            fontsByParameters[key] = fontName
            fontsByAliases[fontName] = fontName
            surface_CreateFont(fontName, fontData)
        end
    end
end

--[[=========================]]
--[[ Detour: surface.SetFont ]]
--[[=========================]]
local surface_SetFont = surface.SetFont
function surface.SetFont(fontName)
    assert(type(fontName) == 'string', 'bad argument #1 to \'surface.SetFont\' (string expected, got ' .. type(fontName) .. ')')

    surface_SetFont(fontsByAliases[fontName] or fontName)
end

--[[============================]]
--[[ Detour: draw.GetFontHeight ]]
--[[============================]]
local draw_GetFontHeight = draw.GetFontHeight
function draw.GetFontHeight(font)
    assert(type(font) == 'string', 'bad argument #1 to \'draw.GetFontHeight\' (string expected, got ' .. type(font) .. ')')

    return draw_GetFontHeight(fontsByAliases[font] or font)
end



--[[==================================================]]
--[[           Detouring of Panel functions           ]]
--[[==================================================]]
local Panel = FindMetaTable 'Panel'
local originalPanelFontLookup = setmetatable({}, { __mode = 'k' })

--[[=======================]]
--[[ Detour: Panel:GetFont ]]
--[[=======================]]
local Panel_GetFont = Panel.GetFont
function Panel:GetFont()
    return originalPanelFontLookup[self] or Panel_GetFont(self)
end

--[[===============================]]
--[[ Detour: Panel:SetFontInternal ]]
--[[===============================]]
local Panel_SetFontInternal = Panel.SetFontInternal
function Panel:SetFontInternal(fontName)
    assert(type(fontName) == 'string', 'bad argument #1 \'Panel:SetFontInternal\' (string expected, got ' .. type(fontName) .. ')')

    originalPanelFontLookup[self] = fontName
    Panel_SetFontInternal(self, fontsByAliases[fontName] or fontName)
end

--[[================================]]
--[[ Detour: Panel:SetUnderlineFont ]]
--[[================================]]
local Panel_SetUnderlineFont = Panel.SetUnderlineFont
function Panel:SetUnderlineFont(fontName)
    assert(type(fontName) == 'string', 'bad argument #1 \'Panel:SetUnderlineFont\' (string expected, got ' .. type(fontName) .. ')')

    Panel_SetUnderlineFont(self, fontsByAliases[fontName] or fontName)
end
