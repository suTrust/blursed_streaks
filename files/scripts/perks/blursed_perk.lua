dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/perks/perk_list.lua")
dofile("mods/blursed_streaks/settings.lua")

-- Define the new perk
table.insert(perk_list,
    {
    id = "BLURSED_STREAKS", -- Unique ID for the perk
    ui_name = "Blursed Health Mod", -- Name that appears in the UI
    ui_description = "$blursed_streaks_description", -- Description that appears in the UI
    ui_icon = "mods/blursed_streaks/files/ui_gfx/perk_icons/blursed_streak.png", -- Path to the perk icon
    perk_icon = "mods/blursed_streaks/files/items_gfx/perks/blursed_streak.png", -- Path to the perk icon in the world
    stackable = STACKABLE_NO, -- Whether the perk can be stacked
    usable_by_enemies = false, -- Whether enemies can use this perk
    not_in_default_perk_pool = true, -- Set to true to not include it in the default perk pool
    -- Function that applies the perk effect
    func = function(entity_perk_item, entity_who_picked, item_name)
        -- Read the mod settings for win and loss streaks
        local win_increment = tonumber(ModSettingGet("blursed_streaks.win_increment") or "0")
        local win_streak_count = tonumber(ModSettingGet("blursed_streaks.win_streak_count") or "0")
        local loss_increment = tonumber(ModSettingGet("blursed_streaks.loss_increment") or "0")
        local loss_streak_count = tonumber(ModSettingGet("blursed_streaks.loss_streak_count") or "0")

        -- Calculate the new max health
        local health_change = (win_increment * win_streak_count) + (loss_increment * loss_streak_count)
        GamePrint("Blursed Streaks: Spawning Blursed Helth Perk: " ..tostring(health_change))
        --health_change = (health_change / 25)
        local raw_health_diff = .04 * health_change

        -- Apply the new max health
        local damagemodels = EntityGetComponent(entity_who_picked, "DamageModelComponent")
        if (damagemodels ~= nil) then
            for i, damagemodel in ipairs(damagemodels) do
                local max_hp = ComponentGetValue2(damagemodel, "max_hp")
                print("Blursed Streaks: Perk Get! Raw Health was:" .. max_hp)
                max_hp = max_hp + raw_health_diff
                print("Blursed Streaks: Perk Get! Raw Health is now:" .. max_hp)
                -- Sanity Check to make sure health stays positive
                if (max_hp <= 0.05) then
                    max_hp = 0.05
                end
                -- Apply Change to Max HP
                ComponentSetValue2(damagemodel, "max_hp", max_hp)
                -- Reset current health to max health
                ComponentSetValue2(damagemodel, "hp", max_hp)

            end
        end
    end,
    }
)