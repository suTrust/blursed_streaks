dofile("data/scripts/lib/mod_settings.lua") -- see this file for documentation on some of the features.

-- This file can't access other files from this or other mods in all circumstances.
-- Settings will be automatically saved.
-- Settings don't have access unsafe lua APIs.

-- Enable or disable logging
local enable_logging = false

-- Define debug_log based on the logging setting
local debug_log = enable_logging and print or function() end

-- Example usage of debug_log
debug_log("This is a debug message")

-- Use ModSettingGet() in the game to query settings.
-- For some settings (for example those that affect world generation) you might want to retain the current value until a certain point, even
-- if the player has changed the setting while playing.
-- To make it easy to define settings like that, each setting has a "scope" (e.g. MOD_SETTING_SCOPE_NEW_GAME) that will define when the changes
-- will actually become visible via ModSettingGet(). In the case of MOD_SETTING_SCOPE_NEW_GAME the value at the start of the run will be visible
-- until the player starts a new game.
-- ModSettingSetNextValue() will set the buffered value, that will later become visible via ModSettingGet(), unless the setting scope is MOD_SETTING_SCOPE_RUNTIME.

debug_log("Blursed Streaks: Loading /blursed_streaks/settings.lua ********************")

function mod_setting_bool_custom( mod_id, gui, in_main_menu, im_id, setting )
	local value = ModSettingGetNextValue( mod_setting_get_id(mod_id,setting) )
	local text = setting.ui_name .. " - " .. GameTextGet( value and "$option_on" or "$option_off" )

	if GuiButton( gui, im_id, mod_setting_group_x_offset, 0, text ) then
		ModSettingSetNextValue( mod_setting_get_id(mod_id,setting), not value, false )
	end

	mod_setting_tooltip( mod_id, gui, in_main_menu, setting )
end

function mod_setting_change_callback( mod_id, gui, in_main_menu, setting, old_value, new_value  )
	print( tostring(new_value) )
end

-- Define mod ID and settings
local mod_id = "blursed_streaks"
mod_settings_version = 1 -- This is a magic global that can be used to migrate settings to new mod versions. call mod_settings_get_version() before mod_settings_update() to get the old value.

mod_settings = 
{
	{
		id = "_",
		ui_name = "Grab the 'Blursed' Perk to change your starting health based on current streak.",
		not_setting = true,
	},
	{
		category_id = "Statistics",
		ui_name = "Stats",
		ui_description = "Recorded Game Stats",
		foldable = true,
		_folded = false, -- this field will be automatically added to each gategory table to store the current folding state
		settings = {
			{
				id = "win_streak_count",
				ui_name = "Win Streak",
				ui_description = "Number of Consecutive Victories",
				value_default = "0",
				text_max_length = 2,
				allowed_characters = "0123456789",
				--not_setting = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "loss_streak_count",
				ui_name = "Loss Streak",
				ui_description = "Number of Consecutive Losses",
				value_default = "0",
				text_max_length = 3,
				allowed_characters = "0123456789",
				--not_setting = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "total_win_count",
				ui_name = "Win Count",
				ui_description = "Number of times you successfully completed The Work.",
				value_default = "0",
				text_max_length = 5,
				allowed_characters = "0123456789",
				-- not_setting = true,
				hidden = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "total_loss_count",
				ui_name = "Defeat Count",
				ui_description = "Number of times you died without completing the work.",
				value_default = "1",
				text_max_length = 5,
				allowed_characters = "0123456789",
				-- not_setting = true,
				hidden = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
		},
	},
	{
		category_id = "Configuration Options",
		ui_name = "Blurse Options",
		ui_description = "Configure the Blurse",
		foldable = true,
		_folded = true, -- this field will be automatically added to each gategory table to store the current folding state
		settings = {
			{
				id = "_",
				ui_name = "Completing The Work always counts as a victory.",
				not_setting = true,
			},
			{
				id = "sampo_win",
				ui_name = "Alternate Victory Condition: Just have the Sampo",
				ui_description = "Collect the Sampo, have it when you die. Good Enough.",
				value_default = "0",
				text_max_length = 1,
				allowed_characters = "01",
				-- not_setting = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "win_increment",
				ui_name = "Win Streak Incrementer",
				ui_description = "How is health changed for each consecutive win? (default -1)",
				value_default = "-1",
				text_max_length = 2,
				allowed_characters = "-+0123456789",
				-- not_setting = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "loss_increment",
				ui_name = "Loss Streak Incrementer",
				ui_description = "How is health changed for each consecutive loss? (default +1)",
				value_default = "+1",
				text_max_length = 2,
				allowed_characters = "-+0123456789",
				-- not_setting = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
		},
	},
}

-- This function is called to ensure the correct setting values are visible to the game via ModSettingGet(). your mod's settings don't work if you don't have a function like this defined in settings.lua.
-- This function is called:
--		- when entering the mod settings menu (init_scope will be MOD_SETTINGS_SCOPE_ONLY_SET_DEFAULT)
-- 		- before mod initialization when starting a new game (init_scope will be MOD_SETTING_SCOPE_NEW_GAME)
--		- when entering the game after a restart (init_scope will be MOD_SETTING_SCOPE_RESTART)
--		- at the end of an update when mod settings have been changed via ModSettingsSetNextValue() and the game is unpaused (init_scope will be MOD_SETTINGS_SCOPE_RUNTIME)
function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id ) -- This can be used to migrate some settings between mod versions.
	mod_settings_update( mod_id, mod_settings, init_scope )
end

-- This function should return the number of visible setting UI elements.
-- Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
-- If your mod changes the displayed settings dynamically, you might need to implement custom logic.
-- The value will be used to determine whether or not to display various UI elements that link to mod settings.
-- At the moment it is fine to simply return 0 or 1 in a custom implementation, but we don't guarantee that will be the case in the future.
-- This function is called every frame when in the settings menu.
function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

-- This function is called to display the settings UI for this mod. Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end