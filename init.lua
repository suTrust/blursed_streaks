-- init.lua
dofile("mods/blursed_streaks/settings.lua")
dofile("mods/blursed_streaks/files/scripts/perks/blursed_perk.lua")

-- Enable or disable logging
local enable_logging = false

-- Define debug_log based on the logging setting
local debug_log = enable_logging and print or function() end

local content = ModTextFileGetContent("data/translations/common.csv")
ModTextFileSetContent("data/translations/common.csv", (content .. [[
BLURSED_STREAKS,Blursed Streaks,,,,,,,,,,,,,
]]):gsub("\r\n","\n"):gsub("\n\n","\n"))

debug_log("#####################################################")
debug_log("Blursed Streaks: Loading /blursed_streaks/init.lua")
debug_log("#####################################################")

--debug_log("Blursed Streaks: Appending New Perk to ")
ModLuaFileAppend("data/scripts/perks/perk_list.lua", "mods/blursed_streaks/files/scripts/perks/blursed_perk.lua")

--GLOBAL_PLAYER_ENTITY = nil  --global entity is needed to access game-state data used in development
--GLOBAL_PAUSE_FLAG = 0   --global value to help make sure debug messages are printed only once
GLOBAL_NEW_GAME_FLAG = "old_game"

function OnModPreInit()
        -- Load existing translations
        local translations = ModTextFileGetContent("data/translations/common.csv")
        if translations ~= nil then
            translations = translations:gsub("\r", "")  -- Remove carriage returns
            
            -- Append mod translations
            local mod_translations = ModTextFileGetContent("mods/blursed_streaks/files/translations/blursed_streaks.csv") or ""
            translations = translations .. "\n" .. mod_translations
            translations = translations:gsub("\n\n+", "\n")  -- Replace double newlines with a single newline
            
            -- Set the updated translations back
            ModTextFileSetContent("data/translations/common.csv", translations)
        end
end

function has_perk(perk_id)
    return GameHasFlagRun("PERK_PICKED_" .. perk_id)
  end

function OnModInit()
    debug_log("Blursed Streaks: OnModInit() ********************")
    local settings = {
        "total_win_count",
        "total_loss_count",
        "win_streak_count",
        "loss_streak_count",
        "win_increment",
        "loss_increment",
        "sambo_win"
    }
    for _, setting in ipairs(settings) do
        if ModSettingGet("blursed_streaks." .. setting) == nil then
            ModSettingSet("blursed_streaks." .. setting, "0")
            ModSettingSetNextValue("blursed_streaks." .. setting, "0", false)
        end
        local setting_value = ModSettingGet("blursed_streaks." .. tostring(setting))
        if setting_value ~= nil then
            debug_log("Blursed Streaks: Mod Init Setting Name: " .. tostring(setting))
            debug_log("Blursed Streaks: Setting Value: " .. tostring(setting_value))
        else
            debug_log("Blursed Streaks: Mod Init Setting Name: " .. tostring(setting))
            debug_log("Blursed Streaks: Setting Value: nil")
        end
    end
    
    if SessionNumbersGetValue("is_biome_map_initialized") == "0" then
        debug_log("Blursed Streaks: New Game Detected.")
        GLOBAL_NEW_GAME_FLAG = "new_game"
    else
        debug_log("Blursed Streaks: Game in progress.")
    end
end

function OnPlayerSpawned(player_entity)
    debug_log("Blursed Streaks: OnPlayerSpawned() ********************")

    if EntityHasTag(player_entity, "player_unit") then
        --GLOBAL_PLAYER_ENTITY = player_entity
        debug_log("Blursed Streaks: Global Player entity initialized: " .. tostring(global_player_entity))
    end

    -- Assess whether this is the start of a new game

    -- Check if this is the first load
    if (GLOBAL_NEW_GAME_FLAG == "new_game") then
        -- Set the flag to indicate that the game has been initialized
        -- Get settings values
        local win_streak_count = tonumber(ModSettingGet("blursed_streaks.win_streak_count")) or 0
        debug_log("Stored Win Streak Count= " .. tostring(win_streak_count))
        GamePrint("Blursed Streaks: Win Streak Count= " .. tostring(win_streak_count))

        local loss_streak_count = tonumber(ModSettingGet("blursed_streaks.loss_streak_count")) or 0
        debug_log("Stored Loss Streak Count= " .. tostring(loss_streak_count))
        GamePrint("Blursed Streaks: Loss Streak Count= " .. tostring(loss_streak_count))

        debug_log("Blursed Streak: $$$$$$$$$$$$$$$$$$$$$$$$")
        debug_log("Blursed Streak: Dropping Blursed Perk...")
        -- Verify player is not already BLURSED... (error happens on game crash recovery)
        if has_perk("BLURSED_STREAKS") then
            GamePrint("Blursed Streak: Blursed Perk Already Present...")
            debug_log("Blursed Streak: $$$$$$$$$$$$$$$$$$$$$$$$")
        else
            -- Spawn Blursed Perk
            DropBlursedPerk(player_entity)
            GamePrint("Blursed Streak: Blursed Perk Dropped...")
            debug_log("Blursed Streak: $$$$$$$$$$$$$$$$$$$$$$$$")    
        end
        GLOBAL_NEW_GAME_FLAG = "old_game"
    else
        GamePrint("Blursed Streak: Game Run in progress. Will Not Spawn Perk...")
        -- Validate whether player entity has Blursed Perk
        if not has_perk("BLURSED_STREAKS") then
            GamePrint("Blursed Streak: Player is not currently Blursed...")
            debug_log("Blursed Streak: $$$$$$$$$$$$$$$$$$$$$$$$")
        end
    end
    debug_log("Blursed Streaks: Exiting OnPlayerSpawned()...")
end

function IsGameCompleteFlag()
    debug_log("Blursed Streak: Assessing Victory Conditions via Game Flags...")
    if GameHasFlagRun("ending_game_completed") == true then
        debug_log("Blursed Streaks: The Work is complete. 'ending_game_completed' flag found: ")
        return true
    else
        debug_log("Blursed Streaks: The Work is NOT complete. 'ending_game_completed' flag NOT found")
    end
    return false
end

-- Function to get the player's inventory
function GetPlayerInventory(player_entity)
    if not EntityGetIsAlive(player_entity) then
        print("Player entity is not alive.")
        return nil
    end

    local inventory_quick = EntityGetFirstComponent(player_entity, "Inventory2Component", "inventory_quick")
    if inventory_quick then
        local items = ComponentGetValue2(inventory_quick, "mItems")
        return items
    end

    local inventory_full = EntityGetFirstComponent(player_entity, "Inventory2Component", "inventory_full")
    if inventory_full then
        local items = ComponentGetValue2(inventory_full, "mItems")
        return items
    end

    return nil
end

function EntityHasSpecificTag(entity_id, tag)
    local tags = EntityGetTags(entity_id)
    if tags then
        for entity_tag in string.gmatch(tags, '([^,]+)') do
            if entity_tag == tag then
                return true
            end
        end
    end
    return false
end

function IsPlayerHoldingSampo(player_entity)
    debug_log("Blursed Streaks: Checking Player inventory for Sampo...")
    if not player_entity or player_entity == 0 then
        debug_log("Blursed Streaks: Invalid player entity.")
        return false
    end

    local inventory = GetPlayerInventory(player_entity)
    if inventory then
        for _, item in ipairs(inventory) do
            if EntityHasSpecificTag(item, "item_sampo") then
                debug_log("Blursed Streaks: Sampo Found!")
                return true
            end
        end
    end
    return false
end

function PrintGameState(player_entity)
    debug_log("#####################################################")
    debug_log("Blursed Streaks: PrintGameState(): ")
    debug_log("#####################################################")

    -- Load Stored Values
    local win_streak_count = ModSettingGet("blursed_streaks.win_streak_count") or "0"
    local loss_streak_count = ModSettingGet("blursed_streaks.loss_streak_count") or "0"
    local total_win_count = ModSettingGet("blursed_streaks.total_win_count") or "0"
    local total_loss_count = ModSettingGet("blursed_streaks.total_loss_count") or "0"
    local win_increment = ModSettingGet("blursed_streaks.win_increment") or "0"
    local loss_increment = ModSettingGet("blursed_streaks.loss_increment") or "0"
    local sampo_win = ModSettingGet("blursed_streaks.sampo_win") or "0"

    -- Debug prints for raw values
    debug_log("Raw win_streak_count: " .. tostring(win_streak_count))
    debug_log("Raw loss_streak_count: " .. tostring(loss_streak_count))
    debug_log("Raw total_win_count: " .. tostring(total_win_count))
    debug_log("Raw total_loss_count: " .. tostring(total_loss_count))
    debug_log("Raw win_increment: " .. tostring(win_increment))
    debug_log("Raw loss_increment: " .. tostring(loss_increment))
    debug_log("Raw sampo_win: " .. tostring(sampo_win))

    -- Ensure values are valid numbers
    win_streak_count = tonumber(win_streak_count) or 0
    loss_streak_count = tonumber(loss_streak_count) or 0
    total_win_count = tonumber(total_win_count) or 0
    total_loss_count = tonumber(total_loss_count) or 0
    win_increment = tonumber(win_increment) or 0
    loss_increment = tonumber(loss_increment) or 0
    sampo_win = tonumber(sampo_win) or 0

    -- Debug prints after conversion
    debug_log("Converted win_streak_count: " .. tostring(win_streak_count))
    debug_log("Converted loss_streak_count: " .. tostring(loss_streak_count))
    debug_log("Converted total_win_count: " .. tostring(total_win_count))
    debug_log("Converted total_loss_count: " .. tostring(total_loss_count))
    debug_log("Converted win_increment: " .. tostring(win_increment))
    debug_log("Converted loss_increment: " .. tostring(loss_increment))
    debug_log("Converted sampo_win: " .. tostring(sampo_win))

    debug_log("Blursed Streaks: Total Victory Count = " .. tostring(total_win_count))
    debug_log("Blursed Streaks: Total Loss Count = " .. tostring(total_loss_count))
    debug_log("----------")
    debug_log("Blursed Streaks: Win Streak Count = " .. tostring(win_streak_count))
    debug_log("Blursed Streaks: Win Streak Incrementer= " .. tostring(win_increment))
    debug_log("Blursed Streaks: Win Streak Health Delta: " .. tostring(win_increment * win_streak_count))
    debug_log("----------")
    debug_log("Blursed Streaks: Loss Streak Count = " .. tostring(loss_streak_count))
    debug_log("Blursed Streaks: Loss Streak Incrementer= " .. tostring(loss_increment))
    debug_log("Blursed Streaks: Loss Streak Health Delta: " .. tostring(loss_increment * loss_streak_count))
    debug_log("----------")

    debug_log("Blursed_streaks: Checking Game Flags for Victory Conditions... ")    
    if (IsGameCompleteFlag()) then
        debug_log("Blursed Streaks: 'ending_game_completed' Flag is 'true'... ")
    end

    debug_log("Blursed Streaks: Checking Alternate Victory Condition: " .. sampo_win)
    if (IsPlayerHoldingSampo(player_entity)) then
        debug_log("Blursed Streaks: Player IS Holding Sampo... ")
    else
        debug_log("Blursed Streaks: Player IS NOT Holding Sampo... ")
    end
    debug_log("Blursed Streaks: Game State report complete. Count Values not updated until Player Death.")
end

-- Hook into pause action to run DEBUG print statement...
function OnPausePreUpdate()
    -- Print Game Status Once...
    if GLOBAL_PAUSE_FLAG == 0 then
        debug_log("Blursed Streaks: OnPausePreUpdate...")
        PrintGameState(GLOBAL_PLAYER_ENTITY)
        GLOBAL_PAUSE_FLAG = 1
    end
end

-- Hook into UnPause action to reset print flags...
function OnPausedChanged()
    -- Reset Print On Pause flag
    GLOBAL_PAUSE_FLAG = 0
end

-- Function to spawn the perk near the player

function SpawnPerkNearPlayer(player_entity)
    dofile_once("data/scripts/perks/perk.lua")
    debug_log("Blursed Streaks: Spawning Perk...")
    local x, y = EntityGetTransform(player_entity)
    if perk_spawn then
        local perk = perk_spawn(x, y-25, "BLURSED_STREAKS")
    else
        debug_log("Blursed Streaks: perk_spawn function not available.")
    end
end

function DropBlursedPerk(player_entity)
    if player_entity then
        SpawnPerkNearPlayer(player_entity)
    else
        debug_log("Blursed Streaks: No player entity found, cannot spawn perk.")
    end
end

-- Used for assessing Victory Conditions based on Game Flags
function AssessVictoryFlags(victory_flag)
    debug_log("Victory Gold: Assessing Victory Conditions via Game Flags...")
    if (GameHasFlagRun( "ending_game_completed") == true ) then
        debug_log("Blursed Streaks: Victory. 'ending_game_completed' flag found")
        --GamePrint("Victory Gold: The Work is complete. 'ending_game_completed' flag found")
        victory_flag = 1
        return victory_flag
    end
    return victory_flag
end

-- used for assessing Victory Conditions based on the condition of the Final Boss
function AssessVictorySampo(player_entity, victory_flag, sampo_win)
    debug_log("Blursed Streaks: Assessing Sampo Get Optional Victory Conditon...")
    if (IsPlayerHoldingSampo(player_entity)) then
        debug_log("Blursed Streaks: Victory. Sampo is Get.")
        victory_flag = 1
        return victory_flag
    end
    return victory_flag
end

--Hook into Player Death, check for noteworthy conditions
function OnPlayerDied(player_entity)
    debug_log ("Blursed Streaks: OnPlayerDied() ********************")
    local victory_flag = 0
    local defeat_flag = 0
    local total_win_count = tonumber(ModSettingGet("blursed_streaks.total_win_count")) or 0
    local total_loss_count = tonumber(ModSettingGet("blursed_streaks.total_loss_count")) or 0
    local win_streak_count = tonumber(ModSettingGet("blursed_streaks.win_streak_count")) or 0
    local loss_streak_count = tonumber(ModSettingGet("blursed_streaks.loss_streak_count")) or 0

    -- Optional Victory Coonditions
    local sampo_win = tonumber(ModSettingGet("blursed_streaks.sampo_win")) or 0

    local victory_text = "Victory Conditions Unsatisfied"

    -- Checking Boss Status for Optional Kolmii Victory Condition
    victory_flag = AssessVictorySampo(player_entity, victory_flag, sampo_win)
    if AssessVictorySampo(player_entity, victory_flag, sampo_win) then
        victory_text = "Sampo is Get. This totally counts."
    end

    --Checking Game Flags for Victory Conditions
    victory_flag = AssessVictoryFlags(victory_flag)
    if AssessVictoryFlags(victory_flag) then
        victory_text = "Endgame Conditional Flag is set."
    end

    -- Checking for player Death
    if (IsPlayerDead(player_entity)) then
        if (victory_flag==0) then
            defeat_flag=1
        end
    end

    if (victory_flag==1) then
        total_win_count = total_win_count + 1
        ModSettingSet("blursed_streaks.total_win_count", tostring(total_win_count))
        ModSettingSetNextValue("blursed_streaks.total_win_count", tostring(total_win_count), false)
        debug_log("Blursed Streaks: The Work has been completed! Total Victory count is now " .. total_win_count)
        loss_streak_count = 0
        debug_log("Blursed Streaks: Loss Streak Zeroed:" .. loss_streak_count)
        ModSettingSet("blursed_streaks.loss_streak_count", tostring(loss_streak_count))
        ModSettingSetNextValue("blursed_streaks.loss_streak_count", tostring(loss_streak_count), false)
        win_streak_count = win_streak_count + 1
        debug_log("Blursed Streaks: Win Streak Incremented:" .. win_streak_count)
        ModSettingSet("blursed_streaks.win_streak_count", tostring(win_streak_count))
        ModSettingSetNextValue("blursed_streaks.win_streak_count", tostring(win_streak_count), false)
        debug_log("Blursed Streaks: Victory! Total Victory count is now " .. total_win_count)
        GamePrint("Victory Condition: ".. victory_text)
        GamePrint("Win Streak is now: " .. win_streak_count)
    elseif (defeat_flag==1) then
        total_loss_count = total_loss_count + 1
        ModSettingSet("blursed_streaks.total_loss_count", tostring(total_loss_count))
        ModSettingSetNextValue("blursed_streaks.total_loss_count", tostring(total_loss_count), false)
        debug_log("Blursed Streaks: The Work is incomplete. Defeat count is now " ..total_loss_count)
        win_streak_count = 0
        debug_log("Blursed Streaks: Win Streak Zeroed:" .. win_streak_count)
        ModSettingSet("blursed_streaks.win_streak_count", tostring(win_streak_count))
        ModSettingSetNextValue("blursed_streaks.win_streak_count", tostring(win_streak_count), false)
        loss_streak_count = loss_streak_count + 1
        debug_log("Blursed Streaks: Loss Streak Incremented:" .. loss_streak_count)
        ModSettingSet("blursed_streaks.loss_streak_count", tostring(loss_streak_count))
        ModSettingSetNextValue("blursed_streaks.loss_streak_count", tostring(loss_streak_count), false)
        debug_log("Blursed Streaks: Defeat! Total Defeat count is now " .. total_loss_count)
        GamePrint("Blursed Streaks: Death is inevitable: ".. victory_text)
        GamePrint("Loss Streak is now: " .. loss_streak_count)
    else
        debug_log("Blursed Streaks: No Victory or Defeat conditions met.")
        GamePrint("Blursed Streaks: Victory Condition: ".. victory_text)
    end
end

-- Function to check if the player is dead
function IsPlayerDead(player_entity)
    --local player_entity = EntityGetWithTag("player_unit")[1]
    if not player_entity then return false end

    local damage_models = EntityGetComponent(player_entity, "DamageModelComponent")
    if damage_models then
        for _, damage_model in ipairs(damage_models) do
            local current_health = ComponentGetValue2(damage_model, "hp")
            if current_health <= 0 then
                return true
            end
        end
    end
    return false
end