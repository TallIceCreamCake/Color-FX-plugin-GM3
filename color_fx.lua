-- Color FX Builder Plugin for grandMA3

local pluginName = "Color FX Builder"

local c  = Cmd
local ti = TextInput
local e  = Echo

-- ------------------------------------------------------------
-- Utils
-- ------------------------------------------------------------
local function trim(s)
    if not s then return s end
    return s:match("^%s*(.-)%s*$")
end

local function escape_for_lua_single_quote(s)
    if s == nil then return "" end
    s = tostring(s)
    s = s:gsub("\\", "\\\\")
    s = s:gsub("'", "\\'")
    s = s:gsub("\r", "")
    return s
end

local function getFirstFreeAppearance()
    local appearancesPool = ShowData().Appearances
    local last = 0
    for i = 1, 10000 do
        if appearancesPool[i] then last = i end
    end
    return last + 1
end

local function getFirstFreeMacro(DP)
    local macrosPool = ShowData().DataPools[DP].Macros
    local last = 0
    for i = 1, 10000 do
        if macrosPool[i] then last = i end
    end
    return last + 1
end

local function getFirstFreeSequence(DP)
    local seqPool = ShowData().DataPools[DP].Sequences
    local last = 0
    for i = 1, 10000 do
        if seqPool[i] then last = i end
    end
    return last + 1
end

local function getFirstFreeMatricks(DP)
    local mPool = ShowData().DataPools[DP].MAtricks
    local last = 0
    for i = 1, 10000 do
        if mPool[i] then last = i end
    end
    return last + 1
end

local function getFirstFreePoolNum(amount, pool)
    local object_num = 1
    local i = 1
    while object_num <= amount do
        if pool[i] ~= nil then
            object_num = 1
            i = i + 1
        else
            object_num = object_num + 1
            i = i + 1
        end
    end
    return (i - amount)
end

-- ------------------------------------------------------------
-- Group input
-- ------------------------------------------------------------
local function parseGroupInput(input, groupsPool)
    local result = {}
    if not input or input == "" then return nil end

    input = input:gsub('[Tt]hru', '-')
    input = input:gsub('%s+', '')

    for segment in input:gmatch('[^,]+') do
        local first, last = segment:match('(%d+)%-(%d+)')
        if first and last then
            first, last = tonumber(first), tonumber(last)
            if first <= last then
                for i = first, last do
                    if groupsPool[i] and #groupsPool[i].selectiondata > 0 then
                        table.insert(result, i)
                    end
                end
            else
                for i = first, last, -1 do
                    if groupsPool[i] and #groupsPool[i].selectiondata > 0 then
                        table.insert(result, i)
                    end
                end
            end
        else
            local num = tonumber(segment)
            if num and groupsPool[num] and #groupsPool[num].selectiondata > 0 then
                table.insert(result, num)
            end
        end
    end

    return (#result > 0) and result or nil
end

local function getGroups(DP)
    local DONE = "[DONE]"
    local groupsPool = ShowData().DataPools[DP].Groups
    local allGroups = {}
    local firstPass = true

    while true do
        local msg = "Entrez les groupes (ex: 1 thru 5, 8, 10)\nEntrez '" .. DONE .. "' pour continuer"
        if firstPass then
            msg = msg .. "\n\nLe champ ne peut pas être vide au premier passage"
        end
        local input = ti(msg, DONE)
        if input == nil then return nil end
        input = trim(input)

        if firstPass and input == "" then
            Confirm("Erreur", "Vous devez sélectionner au moins un groupe !")
        elseif input:upper() == DONE then
            if #allGroups == 0 then
                Confirm("Erreur", "Aucun groupe sélectionné !")
            else
                break
            end
        elseif input ~= "" then
            local parsed = parseGroupInput(input, groupsPool)
            if parsed then
                for _, g in ipairs(parsed) do
                    local exists = false
                    for _, ex in ipairs(allGroups) do
                        if ex == g then exists = true break end
                    end
                    if not exists then table.insert(allGroups, g) end
                end
                firstPass = false
            else
                Confirm("Erreur", "Format invalide ou groupes vides.\nUtilisez: 1 thru 5, 8, 10")
            end
        end
    end

    table.sort(allGroups)
    return allGroups
end

-- ------------------------------------------------------------
-- Layout number
-- ------------------------------------------------------------
local function getLayoutNumber(DP)
    local layoutsPool = ShowData().DataPools[DP].Layouts
    local userInput = ti("Entrez le numéro du Layout à créer:", "1")
    if not userInput then return nil end
    local layoutNum = tonumber(userInput:match("%d+"))
    if not layoutNum then
        Confirm("Erreur", "Numéro de layout invalide")
        return nil
    end
    if layoutsPool[layoutNum] then
        Confirm("Erreur", "Le Layout " .. layoutNum .. " existe déjà !\nVeuillez choisir un autre numéro.")
        return nil
    end
    return layoutNum
end

local function createLayout(layoutNum)
    c('Store Layout ' .. layoutNum .. ' "COLOR FX" /nu')
    c('Select Layout ' .. layoutNum .. ' /nu')
    e("Layout " .. layoutNum .. " 'COLOR FX' créé")
end

-- ------------------------------------------------------------
-- Presets input
-- ------------------------------------------------------------
local function parsePresetInput(input, presetsPool)
    local result = {}
    if not input or input == "" then return nil end

    input = input:gsub('[Tt]hru', '-')
    input = input:gsub('%s+', '')

    for segment in input:gmatch('[^,]+') do
        local first, last = segment:match('(%d+)%-(%d+)')
        if first and last then
            first, last = tonumber(first), tonumber(last)
            if first <= last then
                for i = first, last do
                    if presetsPool[i] and presetsPool[i].storeddata == 'Universal' then
                        table.insert(result, i)
                    end
                end
            else
                for i = first, last, -1 do
                    if presetsPool[i] and presetsPool[i].storeddata == 'Universal' then
                        table.insert(result, i)
                    end
                end
            end
        else
            local num = tonumber(segment)
            if num and presetsPool[num] and presetsPool[num].storeddata == 'Universal' then
                table.insert(result, num)
            end
        end
    end

    return (#result > 0) and result or nil
end

local function getColorPresets(DP)
    local DONE = "[DONE]"
    local presetsPool = ShowData().DataPools[DP].PresetPools[4]
    local allPresets = {}
    local firstPass = true

    while true do
        local msg = "Entrez les presets de couleur (ex: 1 thru 5, 8, 10)\nEntrez '" .. DONE .. "' pour continuer"
        if firstPass then
            msg = msg .. "\n\nLe champ ne peut pas être vide au premier passage"
        end

        local input = ti(msg, DONE)
        if input == nil then return nil end
        input = trim(input)

        if firstPass and input == "" then
            Confirm("Erreur", "Vous devez sélectionner au moins un preset de couleur !")
        elseif input:upper() == DONE then
            if #allPresets == 0 then
                Confirm("Erreur", "Aucun preset sélectionné !")
            else
                break
            end
        elseif input ~= "" then
            local parsed = parsePresetInput(input, presetsPool)
            if parsed then
                for _, p in ipairs(parsed) do
                    local exists = false
                    for _, ex in ipairs(allPresets) do
                        if ex == p then exists = true break end
                    end
                    if not exists then table.insert(allPresets, p) end
                end
                firstPass = false
            else
                Confirm("Erreur", "Format invalide ou presets inexistants.\nUtilisez: 1 thru 5, 8, 10")
            end
        end
    end

    table.sort(allPresets)
    return allPresets
end

-- ------------------------------------------------------------
-- Read preset color (RGB) from preset data
-- ------------------------------------------------------------
local function getPresetColor(presetNum, DP)
    local presetsPool = ShowData().DataPools[DP].PresetPools[4]
    local preset = presetsPool[presetNum]
    if not preset then
        e("ERREUR: Preset " .. presetNum .. " non trouvé")
        return 255, 255, 255
    end

    if preset.storeddata ~= 'Universal' then
        e("ATTENTION: Preset " .. presetNum .. " n'est pas Universal - Conversion...")
        c('universal 1 at preset 4.' .. presetNum .. ' /nu')
        c('store preset 4.' .. presetNum .. ' /m /nu')
        c('clearall /nu')
    end

    local presetData = GetPresetData(preset)
    if not presetData or not presetData[3] or not presetData[4] or not presetData[5] then
        e("ERREUR: Données RGB manquantes dans le preset " .. presetNum)
        return 255, 255, 255
    end

    local r = math.floor(255 * presetData[3][1].absolute / 100)
    local g = math.floor(255 * presetData[4][1].absolute / 100)
    local b = math.floor(255 * presetData[5][1].absolute / 100)
    return r, g, b
end

-- ------------------------------------------------------------
-- Create appearances for each chosen color preset
-- ------------------------------------------------------------
local function createColorAppearances(presets, DP)
    local presetsPool = ShowData().DataPools[DP].PresetPools[4]
    local appearancesPool = ShowData().Appearances

    local firstAppearance = getFirstFreeAppearance()
    local current = firstAppearance

    for _, presetNum in ipairs(presets) do
        local preset = presetsPool[presetNum]
        local presetName = preset and (preset.name or ("Preset " .. presetNum)) or ("Preset " .. presetNum)
        local r, g, b = getPresetColor(presetNum, DP)

        c('Store Appearance ' .. current .. ' /nu')
        appearancesPool[current]:Set('name', 'COLOR FX - ' .. presetName)
        appearancesPool[current]:Set('backr', r)
        appearancesPool[current]:Set('backg', g)
        appearancesPool[current]:Set('backb', b)
        appearancesPool[current]:Set('backalpha', 255)

        current = current + 1
    end

    return firstAppearance, current - 1
end

-- ------------------------------------------------------------
-- Create LOWFX / HIGHFX presets at end of pool 4
-- ------------------------------------------------------------
local function createLowHighPresets(presets, DP)
    local presetsPool = ShowData().DataPools[DP].PresetPools[4]
    if #presets < 2 then return nil, nil end

    local last = 0
    for i = 1, 10000 do
        if presetsPool[i] then last = i end
    end

    local lowNum = last + 1
    local highNum = last + 2

    c('Copy Preset 4.' .. presets[1] .. ' At 4.' .. lowNum .. ' /nu')
    presetsPool[lowNum]:Set('name', 'LOWFX')

    c('Copy Preset 4.' .. presets[2] .. ' At 4.' .. highNum .. ' /nu')
    presetsPool[highNum]:Set('name', 'HIGHFX')

    return lowNum, highNum
end

-- ------------------------------------------------------------
-- Create the SIN FX preset with steps (LOW/HIGH)
-- ------------------------------------------------------------
local function createColorFXPreset(groups, lowfxPresetNum, highfxPresetNum, DP)
    local colorFXPresetNum = highfxPresetNum + 2

    local groupSelection = ""
    for i, groupNum in ipairs(groups) do
        if i > 1 then groupSelection = groupSelection .. " + " end
        groupSelection = groupSelection .. "Group " .. groupNum
    end

    c(groupSelection)
    c('Step 1')
    c('At Preset 4.' .. lowfxPresetNum)
    c('Step 2')
    c('At Preset 4.' .. highfxPresetNum)

    c('Store Preset 4.' .. colorFXPresetNum)
    c('Label Preset 4.' .. colorFXPresetNum .. ' "COLOR FX SIN"')
    c('ClearAll')

    return colorFXPresetNum
end

-- ------------------------------------------------------------
--  Create Sequence 
-- ------------------------------------------------------------
local function createSequence(groups, colorFXPresetNum, DP)
    local seqNum = getFirstFreeSequence(DP)

    c('Store Sequence ' .. seqNum .. ' "COLOR FX" /nu')
    c('Store Sequence ' .. seqNum .. ' Cue 1 /nu')

    if #groups == 1 then
        c('Store Sequence ' .. seqNum .. ' Cue 1 Part 0.1 /nu')
        c('Assign Preset 4.' .. colorFXPresetNum .. ' At Sequence ' .. seqNum .. ' Cue 1 Part 0.1 /nu')
    else
        c('Store Sequence ' .. seqNum .. ' Cue 1 Part 0.1 Thru ' .. #groups .. ' /nu')
        c('Assign Preset 4.' .. colorFXPresetNum .. ' At Sequence ' .. seqNum .. ' Cue 1 Part 0.1 /nu')
        c('Copy Sequence ' .. seqNum .. ' Cue 1 Part 0.1 At Sequence ' .. seqNum .. ' Cue 1 Part 0.2 Thru ' .. #groups .. ' /Merge /nu')
    end

    return seqNum
end

-- ------------------------------------------------------------
--  ON/OFF SWITCH
-- ------------------------------------------------------------
local function configureSequenceAsSwitch(sequenceNum, controlApFirst, DP)
    local seqPool = ShowData().DataPools[DP].Sequences
    local appearances = ShowData().Appearances

    local AP_SWITCH_A = appearances[controlApFirst + 0].name
    local AP_SWITCH_I = appearances[controlApFirst + 1].name

    seqPool[sequenceNum]:Set('appearance', AP_SWITCH_I)
    seqPool[sequenceNum]:Set('prefercueappearance', true)

    if seqPool[sequenceNum][3] and seqPool[sequenceNum][3][1] then
        seqPool[sequenceNum][3][1]:Set('appearance', AP_SWITCH_A)
    end
end

-- ------------------------------------------------------------
-- Create MAtricks
-- ------------------------------------------------------------
local function createMatricks(sequenceNum, DP)
    local mPool = ShowData().DataPools[DP].MAtricks
    local mNum = getFirstFreeMatricks(DP)

    c('Store MAtricks ' .. mNum .. ' "COLOR FX" /nu')
    c('Assign MAtricks ' .. mNum .. ' At Sequence ' .. sequenceNum .. ' Cue 1 Part 0.* /nu')

    local mName = (mPool[mNum] and mPool[mNum].name) or "COLOR FX"
    return mNum, mName
end

-- ------------------------------------------------------------
-- Macro start number 
-- ------------------------------------------------------------
local function getMacroStartNumber()
    local userInput = ti("Entrez le numéro de la première Macro COULEUR (LOW/HIGH) à créer:", "1")
    if not userInput then return nil end
    local num = tonumber(userInput:match("%d+"))
    if not num then
        Confirm("Erreur", "Numéro de macro invalide")
        return nil
    end
    return num
end

-- ------------------------------------------------------------
-- Create color macros LOW/HIGH
-- ------------------------------------------------------------
local function createColorMacros(presets, firstMacro, firstColorAppearance, lowfxPresetNum, highfxPresetNum, DP)
    local macrosPool = ShowData().DataPools[DP].Macros
    local presetsPool = ShowData().DataPools[DP].PresetPools[4]
    local appearancesPool = ShowData().Appearances

    local current = firstMacro

    for i, presetNum in ipairs(presets) do
        local preset = presetsPool[presetNum]
        local presetName = preset and (preset.name or ("Preset " .. presetNum)) or ("Preset " .. presetNum)

        c('Store Macro ' .. current .. ' /o /nu')
        local macroName = presetName .. "_lowfx"
        macrosPool[current]:Set('name', macroName)
        macrosPool[current]:Set('appearance', appearancesPool[firstColorAppearance + (i - 1)].name)

        c('Store Macro ' .. current .. '.1 /o /nu')
        macrosPool[current][1]:Set('command',
            'Copy Preset 4.' .. presetNum .. ' At 4.' .. lowfxPresetNum .. ' /o /nu; Label Preset 4.' .. lowfxPresetNum .. ' "LOWFX"'
        )

        current = current + 1
    end

    for i, presetNum in ipairs(presets) do
        local preset = presetsPool[presetNum]
        local presetName = preset and (preset.name or ("Preset " .. presetNum)) or ("Preset " .. presetNum)

        c('Store Macro ' .. current .. ' /o /nu')
        local macroName = presetName .. "_highfx"
        macrosPool[current]:Set('name', macroName)
        macrosPool[current]:Set('appearance', appearancesPool[firstColorAppearance + (i - 1)].name)

        c('Store Macro ' .. current .. '.1 /o /nu')
        macrosPool[current][1]:Set('command',
            'Copy Preset 4.' .. presetNum .. ' At 4.' .. highfxPresetNum .. ' /o /nu; Label Preset 4.' .. highfxPresetNum .. ' "HIGHFX"'
        )

        current = current + 1
    end

    return firstMacro, current - 1
end

-- ------------------------------------------------------------
-- Create FORMS presets (Buggy...)
-- ------------------------------------------------------------
local function createFormPresets(DP)
    local phaserPool = ShowData().DataPools[DP].PresetPools[21]

    local firstTarget = getFirstFreePoolNum(4, phaserPool)
    local tempStart = getFirstFreePoolNum(111, phaserPool)

    c('Import Preset 21.' .. tempStart .. ' /File "predefined_phaser.xml" /nu')

    local sin_src     = tempStart + 0
    local snapin_src  = tempStart + 1
    local snapout_src = tempStart + 2
    local pwm_src     = tempStart + 3

    c('Copy Preset 21.' .. sin_src .. ' + ' .. snapin_src .. ' + ' .. snapout_src .. ' + ' .. pwm_src .. ' At Preset 21.' .. (tempStart + 107) .. ' /nu')
    c('Delete Preset 21.' .. tempStart .. ' Thru ' .. (tempStart + 106) .. ' /nc /nu')
    c('Move Preset 21.' .. (tempStart + 107) .. ' Thru ' .. (tempStart + 110) .. ' At Preset 21.' .. firstTarget .. ' /nu')

    phaserPool[firstTarget + 0]:Set('name', 'COLORFX_sin')
    phaserPool[firstTarget + 1]:Set('name', 'COLORFX_snapin')
    phaserPool[firstTarget + 2]:Set('name', 'COLORFX_snapout')
    phaserPool[firstTarget + 3]:Set('name', 'COLORFX_pwm')

    return firstTarget, {
        sine    = phaserPool[firstTarget + 0].name,
        snapin  = phaserPool[firstTarget + 1].name,
        snapout = phaserPool[firstTarget + 2].name,
        pwm     = phaserPool[firstTarget + 3].name
    }
end

-- ------------------------------------------------------------
-- CONTROL appearances
-- ------------------------------------------------------------
local function createControlAppearances(DP)
    local appearances = ShowData().Appearances
    local first = getFirstFreeAppearance()

    local files = {
        {name='COLOR FX - switch [active]', file='SYMBOL/symbols/switch_horizontal_right_black.png', alpha=nil},
        {name='COLOR FX - switch',          file='SYMBOL/symbols/switch_horizontal_left_white.png',  alpha=nil},

        {name='COLOR FX - group [active]',  file='SYMBOL/object/group1.png', alpha=255},
        {name='COLOR FX - group',           file='SYMBOL/object/group1.png', alpha=30*2.55},

        {name='COLOR FX - sine [active]',   file='SYMBOL/symbols/sine_black.png',    alpha=nil},
        {name='COLOR FX - sine',            file='SYMBOL/symbols/sine_white.png',    alpha=nil},
        {name='COLOR FX - snapin [active]', file='SYMBOL/symbols/snapin_black.png',  alpha=nil},
        {name='COLOR FX - snapin',          file='SYMBOL/symbols/snapin_white.png',  alpha=nil},
        {name='COLOR FX - snapout [active]',file='SYMBOL/symbols/snapout_black.png', alpha=nil},
        {name='COLOR FX - snapout',         file='SYMBOL/symbols/snapout_white.png', alpha=nil},
        {name='COLOR FX - pwm [active]',    file='SYMBOL/symbols/pwm_black.png',     alpha=nil},
        {name='COLOR FX - pwm',             file='SYMBOL/symbols/pwm_white.png',     alpha=nil},

        {name='COLOR FX - in_order [active]', file='SYMBOL/symbols/in_order_black.png', alpha=nil},
        {name='COLOR FX - in_order',          file='SYMBOL/symbols/in_order_white.png', alpha=nil},
        {name='COLOR FX - shuffle [active]',  file='SYMBOL/symbols/shuffle_black.png',  alpha=nil},
        {name='COLOR FX - shuffle',           file='SYMBOL/symbols/shuffle_white.png',  alpha=nil},

        {name='COLOR FX - mirrored [active]',     file='SYMBOL/symbols/mirrored_black.png',       alpha=nil},
        {name='COLOR FX - mirrored',              file='SYMBOL/symbols/mirrored_white.png',       alpha=nil},
        {name='COLOR FX - non_mirrored [active]', file='SYMBOL/symbols/non_mirrored_black.png',   alpha=nil},
        {name='COLOR FX - non_mirrored',          file='SYMBOL/symbols/non_mirrored_white.png',   alpha=nil},

        {name='COLOR FX - xphase_invert [active]', file='SYMBOL/symbols/arrow_left_black.png',  alpha=nil},
        {name='COLOR FX - xphase_invert',          file='SYMBOL/symbols/arrow_right_white.png', alpha=nil},
        {name='COLOR FX - xphase_0 [active]',      file='SYMBOL/symbols/0_degree_black.png',    alpha=nil},
        {name='COLOR FX - xphase_0',               file='SYMBOL/symbols/0_degree_white.png',    alpha=nil},
        {name='COLOR FX - xphase_90 [active]',     file='SYMBOL/symbols/90_degree_black.png',   alpha=nil},
        {name='COLOR FX - xphase_90',              file='SYMBOL/symbols/90_degree_white.png',   alpha=nil},
        {name='COLOR FX - xphase_180 [active]',    file='SYMBOL/symbols/180_degree_black.png',  alpha=nil},
        {name='COLOR FX - xphase_180',             file='SYMBOL/symbols/180_degree_white.png',  alpha=nil},
        {name='COLOR FX - xphase_360 [active]',    file='SYMBOL/symbols/360_degree_black.png',  alpha=nil},
        {name='COLOR FX - xphase_360',             file='SYMBOL/symbols/360_degree_white.png',  alpha=nil},

        {name='COLOR FX - xgroup_0 [active]',     file='SYMBOL/symbols/number_0_black.png',  alpha=nil},
        {name='COLOR FX - xgroup_0',              file='SYMBOL/symbols/number_0_white.png',  alpha=nil},
        {name='COLOR FX - xgroup_2 [active]',     file='SYMBOL/symbols/number_2_black.png',  alpha=nil},
        {name='COLOR FX - xgroup_2',              file='SYMBOL/symbols/number_2_white.png',  alpha=nil},
        {name='COLOR FX - xgroup_3 [active]',     file='SYMBOL/symbols/number_3_black.png',  alpha=nil},
        {name='COLOR FX - xgroup_3',              file='SYMBOL/symbols/number_3_white.png',  alpha=nil},
        {name='COLOR FX - xgroup_4 [active]',     file='SYMBOL/symbols/number_4_black.png',  alpha=nil},
        {name='COLOR FX - xgroup_4',              file='SYMBOL/symbols/number_4_white.png',  alpha=nil},
        {name='COLOR FX - xgroup_input [active]', file='SYMBOL/symbols/calculator_black.png',alpha=nil},
        {name='COLOR FX - xgroup_input',          file='SYMBOL/symbols/calculator_white.png',alpha=nil},

        {name='COLOR FX - xblock_0 [active]',     file='SYMBOL/symbols/number_0_black.png',  alpha=nil},
        {name='COLOR FX - xblock_0',              file='SYMBOL/symbols/number_0_white.png',  alpha=nil},
        {name='COLOR FX - xblock_2 [active]',     file='SYMBOL/symbols/number_2_black.png',  alpha=nil},
        {name='COLOR FX - xblock_2',              file='SYMBOL/symbols/number_2_white.png',  alpha=nil},
        {name='COLOR FX - xblock_3 [active]',     file='SYMBOL/symbols/number_3_black.png',  alpha=nil},
        {name='COLOR FX - xblock_3',              file='SYMBOL/symbols/number_3_white.png',  alpha=nil},
        {name='COLOR FX - xblock_4 [active]',     file='SYMBOL/symbols/number_4_black.png',  alpha=nil},
        {name='COLOR FX - xblock_4',              file='SYMBOL/symbols/number_4_white.png',  alpha=nil},
        {name='COLOR FX - xblock_input [active]', file='SYMBOL/symbols/calculator_black.png',alpha=nil},
        {name='COLOR FX - xblock_input',          file='SYMBOL/symbols/calculator_white.png',alpha=nil},

        {name='COLOR FX - xfade_0 [active]',      file='SYMBOL/symbols/number_0_black.png',  alpha=nil},
        {name='COLOR FX - xfade_0',               file='SYMBOL/symbols/number_0_white.png',  alpha=nil},
        {name='COLOR FX - xfade_1 [active]',      file='SYMBOL/symbols/number_1_black.png',  alpha=nil},
        {name='COLOR FX - xfade_1',               file='SYMBOL/symbols/number_1_white.png',  alpha=nil},
        {name='COLOR FX - xfade_2 [active]',      file='SYMBOL/symbols/number_2_black.png',  alpha=nil},
        {name='COLOR FX - xfade_2',               file='SYMBOL/symbols/number_2_white.png',  alpha=nil},
        {name='COLOR FX - xfade_4 [active]',      file='SYMBOL/symbols/number_4_black.png',  alpha=nil},
        {name='COLOR FX - xfade_4',               file='SYMBOL/symbols/number_4_white.png',  alpha=nil},
        {name='COLOR FX - xfade_input [active]',  file='SYMBOL/symbols/calculator_black.png',alpha=nil},
        {name='COLOR FX - xfade_input',           file='SYMBOL/symbols/calculator_white.png',alpha=nil},
    }

    local last = first + #files - 1
    c('Store Appearance ' .. first .. ' Thru ' .. last .. ' /nu')

    local a = first
    for _, it in ipairs(files) do
        appearances[a]:Set('name', it.name)
        appearances[a]:Set('mediafilename', it.file)
        appearances[a]:Set('backalpha', 0)
        appearances[a]:Set('imager', 255)
        appearances[a]:Set('imageg', 255)
        appearances[a]:Set('imageb', 255)
        if it.alpha ~= nil then
            appearances[a]:Set('imagealpha', it.alpha)
        end
        a = a + 1
    end

    return first, last
end

-- ------------------------------------------------------------
-- Create GROUP macros
-- ------------------------------------------------------------
local function createGroupMacros(groups, sequenceNum, firstMacro, controlApFirst, DP)
    local macro_pool  = ShowData().DataPools[DP].Macros
    local appearances = ShowData().Appearances
    local groups_pool = ShowData().DataPools[DP].Groups
    local sequence_pool = ShowData().DataPools[DP].Sequences

    local AP_GROUP_A  = appearances[controlApFirst + 2].name
    local AP_GROUP_I  = appearances[controlApFirst + 3].name

    local sequence_name = sequence_pool[sequenceNum] and sequence_pool[sequenceNum].name or tostring(sequenceNum)
    sequence_name = escape_for_lua_single_quote(sequence_name)

    local ap_active = escape_for_lua_single_quote(AP_GROUP_A)
    local ap_inactive = escape_for_lua_single_quote(AP_GROUP_I)

    local groupMacroFirst = firstMacro
    local groupMacroLast  = groupMacroFirst + (#groups - 1)
    local nextMacro       = groupMacroLast + 1

    for i, g in ipairs(groups) do
        local m = groupMacroFirst + (i - 1)

        local macroName = 'COLOR FX - group_' .. g

        c('Store Macro ' .. m .. ' /o /nu')
        macro_pool[m]:Set('name', macroName)
        macro_pool[m]:Set('appearance', AP_GROUP_I)
        c('Store Macro ' .. m .. '.1 /o /nu')

        local group_name = (groups_pool[g] and groups_pool[g].name) or ('Group ' .. g)
        group_name = escape_for_lua_single_quote(group_name)
        local macro_name_escaped = escape_for_lua_single_quote(macroName)

        local lua_command = [[
Lua "
if not DataPool().Sequences[']]..sequence_name..[['][3][1][]]..i..[[].selection then
    Cmd('Assign Group \']]..group_name..[[\' At Sequence \']]..sequence_name..[[\' Cue 1 Part 0.]]..i..[[ /nu')
    Cmd('Assign Appearance \']]..ap_active..[[\' at Macro \']]..macro_name_escaped..[[\' /nu')
else
    Cmd('Set Sequence \']]..sequence_name..[[\' Cue 1 Part 0.]]..i..[[ \'selection\' \'None\' /nu')
    Cmd('Assign Appearance \']]..ap_inactive..[[\' at Macro \']]..macro_name_escaped..[[\' /nu')
end
"
]]
        lua_command = lua_command:gsub("\r", "")
        lua_command = lua_command:gsub('\n%s+',' ')

        macro_pool[m][1]:Set('command', lua_command)
    end

    return groupMacroFirst, groupMacroLast, nextMacro
end

-- ------------------------------------------------------------
-- Create CONTROL macros (FORMS / ORDER / MIRROR / PHASE / XGROUP / XBLOCK / XFADE)
-- ------------------------------------------------------------
local function createControlMacros(matricksName, sequenceNum, controlAppearFirst, formNames, firstMacro, DP)
    local macro_pool  = ShowData().DataPools[DP].Macros
    local appearances = ShowData().Appearances

    local function ap(i) return appearances[i].name end
    local m = firstMacro

    local AP_SINE_A      = controlAppearFirst + 4
    local AP_SINE_I      = controlAppearFirst + 5
    local AP_SNAPIN_A    = controlAppearFirst + 6
    local AP_SNAPIN_I    = controlAppearFirst + 7
    local AP_SNAPOUT_A   = controlAppearFirst + 8
    local AP_SNAPOUT_I   = controlAppearFirst + 9
    local AP_PWM_A       = controlAppearFirst + 10
    local AP_PWM_I       = controlAppearFirst + 11

    local AP_INORDER_A   = controlAppearFirst + 12
    local AP_INORDER_I   = controlAppearFirst + 13
    local AP_SHUFFLE_A   = controlAppearFirst + 14
    local AP_SHUFFLE_I   = controlAppearFirst + 15

    local AP_MIR_A       = controlAppearFirst + 16
    local AP_MIR_I       = controlAppearFirst + 17
    local AP_NOMIR_A     = controlAppearFirst + 18
    local AP_NOMIR_I     = controlAppearFirst + 19

    local AP_PINV_A      = controlAppearFirst + 20
    local AP_PINV_I      = controlAppearFirst + 21
    local AP_P0_A        = controlAppearFirst + 22
    local AP_P0_I        = controlAppearFirst + 23
    local AP_P90_A       = controlAppearFirst + 24
    local AP_P90_I       = controlAppearFirst + 25
    local AP_P180_A      = controlAppearFirst + 26
    local AP_P180_I      = controlAppearFirst + 27
    local AP_P360_A      = controlAppearFirst + 28
    local AP_P360_I      = controlAppearFirst + 29

    local AP_XG0_A       = controlAppearFirst + 30
    local AP_XG0_I       = controlAppearFirst + 31
    local AP_XG2_A       = controlAppearFirst + 32
    local AP_XG2_I       = controlAppearFirst + 33
    local AP_XG3_A       = controlAppearFirst + 34
    local AP_XG3_I       = controlAppearFirst + 35
    local AP_XG4_A       = controlAppearFirst + 36
    local AP_XG4_I       = controlAppearFirst + 37
    local AP_XGIN_A      = controlAppearFirst + 38
    local AP_XGIN_I      = controlAppearFirst + 39

    local AP_XB0_A       = controlAppearFirst + 40
    local AP_XB0_I       = controlAppearFirst + 41
    local AP_XB2_A       = controlAppearFirst + 42
    local AP_XB2_I       = controlAppearFirst + 43
    local AP_XB3_A       = controlAppearFirst + 44
    local AP_XB3_I       = controlAppearFirst + 45
    local AP_XB4_A       = controlAppearFirst + 46
    local AP_XB4_I       = controlAppearFirst + 47
    local AP_XBIN_A      = controlAppearFirst + 48
    local AP_XBIN_I      = controlAppearFirst + 49

    local AP_XF0_A       = controlAppearFirst + 50
    local AP_XF0_I       = controlAppearFirst + 51
    local AP_XF1_A       = controlAppearFirst + 52
    local AP_XF1_I       = controlAppearFirst + 53
    local AP_XF2_A       = controlAppearFirst + 54
    local AP_XF2_I       = controlAppearFirst + 55
    local AP_XF4_A       = controlAppearFirst + 56
    local AP_XF4_I       = controlAppearFirst + 57
    local AP_XFIN_A      = controlAppearFirst + 58
    local AP_XFIN_I      = controlAppearFirst + 59

    local function storeMacro(num, name, appearName)
        c('Store Macro ' .. num .. ' /o /nu')
        macro_pool[num]:Set('name', name)
        macro_pool[num]:Set('appearance', appearName)
    end

    local function storeLines(num, from, to)
        c('Store Macro ' .. num .. '.' .. from .. ' Thru ' .. to .. ' /o /nu')
    end

    local function setLine(num, line, cmd)
        macro_pool[num][line]:Set('command', cmd)
    end

    local resetForms =
        'Assign Appearance "' .. ap(AP_SINE_I)    .. '" At Macro "COLOR FX - sine"; ' ..
        'Assign Appearance "' .. ap(AP_SNAPIN_I)  .. '" At Macro "COLOR FX - snapin"; ' ..
        'Assign Appearance "' .. ap(AP_SNAPOUT_I) .. '" At Macro "COLOR FX - snapout"; ' ..
        'Assign Appearance "' .. ap(AP_PWM_I)     .. '" At Macro "COLOR FX - pwm"'

    local function makeForm(label, presetName, apA, apI)
        storeMacro(m, "COLOR FX - " .. label, ap(apI))
        storeLines(m, 1, 3)
        setLine(m, 1, "Assign Preset 21.'" .. presetName .. "' At Sequence '" .. sequenceNum .. "' Cue 1 Part 0.*")
        setLine(m, 2, resetForms)
        setLine(m, 3, 'Assign Appearance "' .. ap(apA) .. '" At Macro "COLOR FX - ' .. label .. '"')
        m = m + 1
    end

    makeForm("sine",    formNames.sine,    AP_SINE_A,   AP_SINE_I)
    makeForm("snapin",  formNames.snapin,  AP_SNAPIN_A, AP_SNAPIN_I)
    makeForm("snapout", formNames.snapout, AP_SNAPOUT_A,AP_SNAPOUT_I)
    makeForm("pwm",     formNames.pwm,     AP_PWM_A,    AP_PWM_I)

    storeMacro(m, "COLOR FX - in_order", ap(AP_INORDER_I))
    storeLines(m, 1, 3)
    setLine(m, 1,
        'Set MAtricks "' .. matricksName .. '" Property DoShuffle 0; ' ..
        'Set MAtricks "' .. matricksName .. '" "xshuffle" 0; Set MAtricks "' .. matricksName .. '" "yshuffle" 0; Set MAtricks "' .. matricksName .. '" "zshuffle" 0'
    )
    setLine(m, 2,
        'Assign Appearance "' .. ap(AP_SHUFFLE_I) .. '" At Macro "COLOR FX - shuffle"; ' ..
        'Assign Appearance "' .. ap(AP_INORDER_A) .. '" At Macro "COLOR FX - in_order"'
    )
    setLine(m, 3, '')
    m = m + 1

    storeMacro(m, "COLOR FX - shuffle", ap(AP_SHUFFLE_I))
    storeLines(m, 1, 3)
    setLine(m, 1, 'Set MAtricks "' .. matricksName .. '" Property DoShuffle 1; Cook Sequence "' .. sequenceNum .. '" Cue 1 /Merge')
    setLine(m, 2,
        'Assign Appearance "' .. ap(AP_INORDER_I) .. '" At Macro "COLOR FX - in_order"; ' ..
        'Assign Appearance "' .. ap(AP_SHUFFLE_A) .. '" At Macro "COLOR FX - shuffle"'
    )
    setLine(m, 3, '')
    m = m + 1

    storeMacro(m, "COLOR FX - mirrored", ap(AP_MIR_I))
    storeLines(m, 1, 3)
    setLine(m, 1, 'Set MAtricks "' .. matricksName .. '" "xwings" 2; Set MAtricks "' .. matricksName .. '" "phasertransform" "Mirror"')
    setLine(m, 2,
        'Assign Appearance "' .. ap(AP_NOMIR_I) .. '" At Macro "COLOR FX - non_mirrored"; ' ..
        'Assign Appearance "' .. ap(AP_MIR_A) .. '" At Macro "COLOR FX - mirrored"'
    )
    setLine(m, 3, '')
    m = m + 1

    storeMacro(m, "COLOR FX - non_mirrored", ap(AP_NOMIR_I))
    storeLines(m, 1, 3)
    setLine(m, 1, 'Set MAtricks "' .. matricksName .. '" "xwings" 0; Set MAtricks "' .. matricksName .. '" "phasertransform" "None"')
    setLine(m, 2,
        'Assign Appearance "' .. ap(AP_MIR_I) .. '" At Macro "COLOR FX - mirrored"; ' ..
        'Assign Appearance "' .. ap(AP_NOMIR_A) .. '" At Macro "COLOR FX - non_mirrored"'
    )
    setLine(m, 3, '')
    m = m + 1

    storeMacro(m, "COLOR FX - xphase_invert", ap(AP_PINV_I))
    c('Store Macro ' .. m .. '.1 /o /nu')

    local matricksNameEsc = escape_for_lua_single_quote(matricksName)
    local apOnEsc  = escape_for_lua_single_quote(ap(AP_PINV_A))
    local apOffEsc = escape_for_lua_single_quote(ap(AP_PINV_I))

    local luaInvert = [[
Lua "
local matrick = DataPool().matricks[']]..matricksNameEsc..[[']
local macroName = 'COLOR FX - xphase_invert'
local apOn  = ']]..apOnEsc..[['
local apOff = ']]..apOffEsc..[['
if matrick then
  local phasetox = matrick:Get('phasetox',Enums.Roles.Display)
  phasetox = phasetox and phasetox:match('(%-?%d+).*')
  phasetox = tonumber(phasetox)
  if phasetox and phasetox > 0 then
    matrick:Set('phasetox', -phasetox)
    Cmd('Assign Appearance \''..apOn..'\' At Macro \''..macroName..'\' /nu')
  elseif phasetox and phasetox < 0 then
    matrick:Set('phasetox', math.abs(phasetox))
    Cmd('Assign Appearance \''..apOff..'\' At Macro \''..macroName..'\' /nu')
  end
end
"
]]
    luaInvert = luaInvert:gsub("\r", "")
    luaInvert = luaInvert:gsub('\n%s+', ' ')
    macro_pool[m][1]:Set('command', luaInvert)
    m = m + 1

    local resetPhase =
        'Assign Appearance "' .. ap(AP_P0_I)   .. '" At Macro "COLOR FX - xphase_0"; ' ..
        'Assign Appearance "' .. ap(AP_P90_I)  .. '" At Macro "COLOR FX - xphase_90"; ' ..
        'Assign Appearance "' .. ap(AP_P180_I) .. '" At Macro "COLOR FX - xphase_180"; ' ..
        'Assign Appearance "' .. ap(AP_P360_I) .. '" At Macro "COLOR FX - xphase_360"'

    local function makePhase(val, label, apA, apI)
        storeMacro(m, "COLOR FX - " .. label, ap(apI))
        storeLines(m, 1, 3)
        setLine(m, 1, 'Set MAtricks "' .. matricksName .. '" "phasefromx" 0; Set MAtricks "' .. matricksName .. '" "phasetox" ' .. val)
        setLine(m, 2, resetPhase)
        setLine(m, 3, 'Assign Appearance "' .. ap(apA) .. '" At Macro "COLOR FX - ' .. label .. '"')
        m = m + 1
    end

    makePhase(0,   "xphase_0",   AP_P0_A,   AP_P0_I)
    makePhase(90,  "xphase_90",  AP_P90_A,  AP_P90_I)
    makePhase(180, "xphase_180", AP_P180_A, AP_P180_I)
    makePhase(360, "xphase_360", AP_P360_A, AP_P360_I)

    local resetXGroup =
        'Assign Appearance "' .. ap(AP_XG0_I)   .. '" At Macro "COLOR FX - xgroup_0"; ' ..
        'Assign Appearance "' .. ap(AP_XG2_I)   .. '" At Macro "COLOR FX - xgroup_2"; ' ..
        'Assign Appearance "' .. ap(AP_XG3_I)   .. '" At Macro "COLOR FX - xgroup_3"; ' ..
        'Assign Appearance "' .. ap(AP_XG4_I)   .. '" At Macro "COLOR FX - xgroup_4"; ' ..
        'Assign Appearance "' .. ap(AP_XGIN_I)  .. '" At Macro "COLOR FX - xgroup_input"'

    local function makeXGroup(val, label, apA, apI)
        storeMacro(m, "COLOR FX - " .. label, ap(apI))
        storeLines(m, 1, 3)
        setLine(m, 1, 'Set MAtricks "' .. matricksName .. '" "xgroup" ' .. val)
        setLine(m, 2, resetXGroup)
        setLine(m, 3, 'Assign Appearance "' .. ap(apA) .. '" At Macro "COLOR FX - ' .. label .. '"')
        m = m + 1
    end

    makeXGroup(0,    "xgroup_0",      AP_XG0_A,  AP_XG0_I)
    makeXGroup(2,    "xgroup_2",      AP_XG2_A,  AP_XG2_I)
    makeXGroup(3,    "xgroup_3",      AP_XG3_A,  AP_XG3_I)
    makeXGroup(4,    "xgroup_4",      AP_XG4_A,  AP_XG4_I)
    makeXGroup("()", "xgroup_input",  AP_XGIN_A, AP_XGIN_I)

    local resetXBlock =
        'Assign Appearance "' .. ap(AP_XB0_I)   .. '" At Macro "COLOR FX - xblock_0"; ' ..
        'Assign Appearance "' .. ap(AP_XB2_I)   .. '" At Macro "COLOR FX - xblock_2"; ' ..
        'Assign Appearance "' .. ap(AP_XB3_I)   .. '" At Macro "COLOR FX - xblock_3"; ' ..
        'Assign Appearance "' .. ap(AP_XB4_I)   .. '" At Macro "COLOR FX - xblock_4"; ' ..
        'Assign Appearance "' .. ap(AP_XBIN_I)  .. '" At Macro "COLOR FX - xblock_input"'

    local function makeXBlock(val, label, apA, apI)
        storeMacro(m, "COLOR FX - " .. label, ap(apI))
        storeLines(m, 1, 3)
        setLine(m, 1, 'Set MAtricks "' .. matricksName .. '" "xblock" ' .. val)
        setLine(m, 2, resetXBlock)
        setLine(m, 3, 'Assign Appearance "' .. ap(apA) .. '" At Macro "COLOR FX - ' .. label .. '"')
        m = m + 1
    end

    makeXBlock(0,    "xblock_0",      AP_XB0_A,  AP_XB0_I)
    makeXBlock(2,    "xblock_2",      AP_XB2_A,  AP_XB2_I)
    makeXBlock(3,    "xblock_3",      AP_XB3_A,  AP_XB3_I)
    makeXBlock(4,    "xblock_4",      AP_XB4_A,  AP_XB4_I)
    makeXBlock("()", "xblock_input",  AP_XBIN_A, AP_XBIN_I)

    local resetXFade =
        'Assign Appearance "' .. ap(AP_XF0_I)   .. '" At Macro "COLOR FX - xfade_0"; ' ..
        'Assign Appearance "' .. ap(AP_XF1_I)   .. '" At Macro "COLOR FX - xfade_1"; ' ..
        'Assign Appearance "' .. ap(AP_XF2_I)   .. '" At Macro "COLOR FX - xfade_2"; ' ..
        'Assign Appearance "' .. ap(AP_XF4_I)   .. '" At Macro "COLOR FX - xfade_4"; ' ..
        'Assign Appearance "' .. ap(AP_XFIN_I)  .. '" At Macro "COLOR FX - xfade_input"'

    local function makeXFade(val, label, apA, apI)
        storeMacro(m, "COLOR FX - " .. label, ap(apI))
        storeLines(m, 1, 3)
        if val ~= "()" then
            setLine(m, 1,
                'Set MAtricks "' .. matricksName .. '" Property "fadefromx" ' .. val .. ' /nu; ' ..
                'Set Sequence "' .. sequenceNum .. '" Cue "offcue" CueFade ' .. val .. ' /nu'
            )
        else
            setLine(m, 1,
                'SetUserVariable "colorfxfade" () /nu; ' ..
                'Set MAtricks "' .. matricksName .. '" Property "fadefromx" $colorfxfade /nu; ' ..
                'Set Sequence "' .. sequenceNum .. '" Cue "offcue" CueFade $colorfxfade /nu; ' ..
                'DeleteUserVariable "colorfxfade" /nu'
            )
        end
        setLine(m, 2, resetXFade)
        setLine(m, 3, 'Assign Appearance "' .. ap(apA) .. '" At Macro "COLOR FX - ' .. label .. '"')
        m = m + 1
    end

    makeXFade(0,    "xfade_0",      AP_XF0_A,  AP_XF0_I)
    makeXFade(1,    "xfade_1",      AP_XF1_A,  AP_XF1_I)
    makeXFade(2,    "xfade_2",      AP_XF2_A,  AP_XF2_I)
    makeXFade(4,    "xfade_4",      AP_XF4_A,  AP_XF4_I)
    makeXFade("()", "xfade_input",  AP_XFIN_A, AP_XFIN_I)

    return firstMacro, m - 1
end

-- ------------------------------------------------------------
-- Layout helpers
-- ------------------------------------------------------------
local function applyLayoutProps(layoutElement, x, y, w, h, customText, customSize)
    if not layoutElement then return end
    layoutElement:Set('posx', 65536 + x)
    layoutElement:Set('posy', y)
    layoutElement:Set('POSITIONW', w)
    layoutElement:Set('POSITIONH', h)
    layoutElement:Set('visibilityobjectname', false)
    layoutElement:Set('visibilitybar', false)
    layoutElement:Set('visibilityindicatorbar', false)
    layoutElement:Set('visibilityborder', false)
    if customText then
        layoutElement:Set('CUSTOMTEXTTEXT', customText)
        layoutElement:Set('CUSTOMTEXTSIZE', customSize or 16)
    end
end

-- ------------------------------------------------------------
-- Populate Layout
-- ------------------------------------------------------------
local function populateLayout(layoutNum,
    sequenceNum, matricksNum,
    groupMacroFirst, groupMacroLast,
    controlMacroFirst, controlMacroLast,
    colorMacroFirst, presetsCount, colorFXPresetNum,
    groups, DP
)
    local layout_pool = ShowData().DataPools[DP].Layouts
    local groups_pool = ShowData().DataPools[DP].Groups

    local startX = -480
    local startY = 150
    local gapX = 60
    local gapY = 60
    local size = 50

    local vSpaceTop = math.floor(gapY * 0.5)
    local vSpaceAfterRow2 = math.floor(gapY * 0.5)
    local hSpaceSection = gapX
    local colorGapX = gapX - 5

    local function createLabel(x, y, w, h, text, txtSize)
        local children = layout_pool[layoutNum]:Children()
        local idx = #children + 1
        c('Store Layout ' .. layoutNum .. '.' .. idx .. ' /nu')
        local el = layout_pool[layoutNum][idx]
        applyLayoutProps(el, x, y, w, h, text, txtSize or 18)
    end

    local ctrl = {}
    for i = controlMacroFirst, controlMacroLast do ctrl[#ctrl+1] = i end
    local formsStart  = 1
    local orderStart  = 5
    local mirrorStart = 7
    local phaseStart  = 9
    local xgroupStart = 14
    local xblockStart = 19
    local xfadeStart  = 24

    local formsX = startX + gapX * 3
    local formsStep = math.floor(gapX * 1.34)

    local labelW = math.floor(gapX * 1.5)
    local labelGap = math.floor(gapX * 0.2)

    local xPhaseLabelX = 0
    local xGroupsLabelX = 0

    -- ROW 0 : ON/OFF + MAtricks
    local topY = startY + gapY + vSpaceTop

    c('Assign Sequence ' .. sequenceNum .. ' At Layout ' .. layoutNum .. ' /nu')
    local elems = layout_pool[layoutNum]:Children()
    local seqEl = elems[#elems]
    applyLayoutProps(seqEl, formsX, topY, size, size)
    if seqEl then seqEl:Set('action', 14) end

    c('Assign MAtricks ' .. matricksNum .. ' At Layout ' .. layoutNum .. ' /nu')
    elems = layout_pool[layoutNum]:Children()
    applyLayoutProps(elems[#elems], formsX + formsStep, topY, size, size)

    -- LINE 1 : FORMS + Phase + Groups
    local cx = formsX
    local cy = startY

    for i=0,3 do
        c('Assign Macro ' .. ctrl[formsStart+i] .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        applyLayoutProps(elems[#elems], cx, cy, size, size)
        cx = cx + formsStep
    end

    cx = cx + hSpaceSection
    xPhaseLabelX = cx
    createLabel(cx, cy, labelW, size, "Phase >", 18)
    cx = cx + labelW + labelGap

    for i=0,4 do
        c('Assign Macro ' .. ctrl[phaseStart+i] .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        applyLayoutProps(elems[#elems], cx, cy, size, size)
        cx = cx + gapX
    end

    cx = cx + hSpaceSection
    xGroupsLabelX = cx
    createLabel(cx, cy, labelW, size, "Groups >", 18)
    cx = cx + labelW + labelGap

    for i=0,4 do
        c('Assign Macro ' .. ctrl[xgroupStart+i] .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        applyLayoutProps(elems[#elems], cx, cy, size, size)
        cx = cx + gapX
    end

    -- LINE 2 : shuffle + direction + Blocks + Fade
    cx = formsX
    cy = startY - gapY

    for i=0,1 do
        c('Assign Macro ' .. ctrl[orderStart+i] .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        applyLayoutProps(elems[#elems], cx, cy, size, size)
        cx = cx + gapX
    end

    cx = cx + gapX

    for i=0,1 do
        c('Assign Macro ' .. ctrl[mirrorStart+i] .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        applyLayoutProps(elems[#elems], cx, cy, size, size)
        cx = cx + gapX
    end

    cx = xPhaseLabelX
    createLabel(cx, cy, labelW, size, "Blocks >", 18)
    cx = cx + labelW + labelGap

    for i=0,4 do
        c('Assign Macro ' .. ctrl[xblockStart+i] .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        applyLayoutProps(elems[#elems], cx, cy, size, size)
        cx = cx + gapX
    end

    cx = xGroupsLabelX
    createLabel(cx, cy, labelW, size, "Fade >", 18)
    cx = cx + labelW + labelGap

    for i=0,4 do
        c('Assign Macro ' .. ctrl[xfadeStart+i] .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        applyLayoutProps(elems[#elems], cx, cy, size, size)
        cx = cx + gapX
    end

    -- GROUP macros : horizontal sur 2 lignes max
    local gx = formsX
    local gyTop = (startY - gapY * 2) - vSpaceAfterRow2
    local gyBottom = gyTop - gapY

    local totalGroups = #groups
    local perRow = math.ceil(totalGroups / 2)

    local m = groupMacroFirst
    local gi = 1

    local x = gx
    local y = gyTop
    for i=1,perRow do
        if m > groupMacroLast then break end
        c('Assign Macro ' .. m .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        local gnum = groups[gi]
        local gname = (groups_pool[gnum] and groups_pool[gnum].name) or ('Group ' .. gnum)
        applyLayoutProps(elems[#elems], x, y, size, size, gname, 16)
        x = x + gapX
        m = m + 1
        gi = gi + 1
    end

    x = gx
    y = gyBottom
    while m <= groupMacroLast do
        c('Assign Macro ' .. m .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        local gnum = groups[gi]
        local gname = (groups_pool[gnum] and groups_pool[gnum].name) or ('Group ' .. gnum)
        applyLayoutProps(elems[#elems], x, y, size, size, gname, 16)
        x = x + gapX
        m = m + 1
        gi = gi + 1
    end

    -- Color macros (espacement réduit)
    local colorStartX = formsX
    local yColorTop = gyBottom - gapY
    local yColorBottom = yColorTop - gapY

    for i=1,presetsCount do
        local macroNum = colorMacroFirst + (i-1)
        local px = colorStartX + ((i-1)*colorGapX)
        c('Assign Macro ' .. macroNum .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        applyLayoutProps(elems[#elems], px, yColorTop, size, size)
    end

    for i=1,presetsCount do
        local macroNum = colorMacroFirst + presetsCount + (i-1)
        local px = colorStartX + ((i-1)*colorGapX)
        c('Assign Macro ' .. macroNum .. ' At Layout ' .. layoutNum .. ' /nu')
        elems = layout_pool[layoutNum]:Children()
        applyLayoutProps(elems[#elems], px, yColorBottom, size, size)
    end

    local presetX = colorStartX + (presetsCount * colorGapX) + 20
    local presetW = 150
    local presetH = 150
    local presetY = yColorBottom + (gapY/2) - (presetH/2) + (size/2)

    c('Assign Preset 4.' .. colorFXPresetNum .. ' At Layout ' .. layoutNum .. ' /nu')
    elems = layout_pool[layoutNum]:Children()
    local el = elems[#elems]
    if el then
        el:Set('posx', 65536 + presetX)
        el:Set('posy', presetY)
        el:Set('POSITIONW', presetW)
        el:Set('POSITIONH', presetH)
        el:Set('visibilityobjectname', false)
        el:Set('visibilitybar', false)
        el:Set('visibilityindicatorbar', true)
        el:Set('visibilityborder', false)
    end
end

-- ------------------------------------------------------------
-- MAIN
-- ------------------------------------------------------------
function Main()
    e("=== Color FX Builder - Démarrage ===")
    local DP = tonumber(DataPool().no)

    local groups = getGroups(DP)
    if not groups or #groups == 0 then
        e("Aucun groupe sélectionné. Annulation.")
        return
    end

    local presets = getColorPresets(DP)
    if not presets or #presets == 0 then
        e("Aucun preset sélectionné. Annulation.")
        return
    end

    local layoutNum = getLayoutNumber(DP)
    if not layoutNum then
        e("Annulation - Layout non créé")
        return
    end
    createLayout(layoutNum)

    local firstColorAp, lastColorAp = createColorAppearances(presets, DP)

    local lowfxPresetNum, highfxPresetNum = createLowHighPresets(presets, DP)
    if not lowfxPresetNum or not highfxPresetNum then
        Confirm("Erreur", "Il faut au moins 2 presets pour créer LOWFX/HIGHFX")
        return
    end

    local colorFXPresetNum = createColorFXPreset(groups, lowfxPresetNum, highfxPresetNum, DP)

    local sequenceNum = createSequence(groups, colorFXPresetNum, DP)
    local matricksNum, matricksName = createMatricks(sequenceNum, DP)

    local formPresetFirst, formNames = createFormPresets(DP)
    local controlApFirst, controlApLast = createControlAppearances(DP)

    configureSequenceAsSwitch(sequenceNum, controlApFirst, DP)

    local firstMacroAuto = getFirstFreeMacro(DP)
    local groupMacroFirst, groupMacroLast, nextMacro =
        createGroupMacros(groups, sequenceNum, firstMacroAuto, controlApFirst, DP)

    local controlMacroFirst, controlMacroLast =
        createControlMacros(matricksName, sequenceNum, controlApFirst, formNames, nextMacro, DP)

    local colorMacroFirst = getMacroStartNumber()
    if not colorMacroFirst then
        e("Annulation - Macros couleurs non créées")
        return
    end
    local colorMacroFirstCreated, colorMacroLast =
        createColorMacros(presets, colorMacroFirst, firstColorAp, lowfxPresetNum, highfxPresetNum, DP)

    populateLayout(
        layoutNum,
        sequenceNum, matricksNum,
        groupMacroFirst, groupMacroLast,
        controlMacroFirst, controlMacroLast,
        colorMacroFirstCreated, #presets, colorFXPresetNum,
        groups, DP
    )

    MessageBox({
        title = pluginName,
        message = "OK.\n\n- FIX xphase_invert (Cmd quotes)\n",
        commands = {{value=1,name="OK"}}
    })
end

return Main
