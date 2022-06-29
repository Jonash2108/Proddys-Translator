local ScriptName = "Proddy's Translator"

if ProddysTranslator then
	menu.notify("Script already loaded", ScriptName, 10, 0xFF0000FF)
	return
end

if not menu.is_trusted_mode_enabled(eTrustedFlags.LUA_TRUST_HTTP) then
	menu.notify("Script requires HTTP trusted flag", ScriptName, 10, 0xFF0000FF)
	return
end

ProddysTranslator = true

local Languages = {
	{ Name = "Afrikaans", Key = "af" },
	{ Name = "Albanian", Key = "sq" },
	{ Name = "Arabic", Key = "ar" },
	{ Name = "Azerbaijani", Key = "az" },
	{ Name = "Basque", Key = "eu" },
	{ Name = "Belarusian", Key = "be" },
	{ Name = "Bengali", Key = "bn" },
	{ Name = "Bulgarian", Key = "bg" },
	{ Name = "Catalan", Key = "ca" },
	{ Name = "Chinese Simplified", Key = "zh-CN" },
	{ Name = "Chinese Traditional", Key = "zh-TW" },
	{ Name = "Croatian", Key = "hr" },
	{ Name = "Czech", Key = "cs" },
	{ Name = "Danish", Key = "da" },
	{ Name = "Dutch", Key = "nl" },
	{ Name = "English", Key = "en" },
	{ Name = "Esperanto", Key = "eo" },
	{ Name = "Estonian", Key = "et" },
	{ Name = "Filipino", Key = "tl" },
	{ Name = "Finnish", Key = "fi" },
	{ Name = "French", Key = "fr" },
	{ Name = "Galician", Key = "gl" },
	{ Name = "Georgian", Key = "ka" },
	{ Name = "German", Key = "de" },
	{ Name = "Greek", Key = "el" },
	{ Name = "Gujarati", Key = "gu" },
	{ Name = "Haitian Creole", Key = "ht" },
	{ Name = "Hebrew", Key = "iw" },
	{ Name = "Hindi", Key = "hi" },
	{ Name = "Hungarian", Key = "hu" },
	{ Name = "Icelandic", Key = "is" },
	{ Name = "Indonesian", Key = "id" },
	{ Name = "Irish", Key = "ga" },
	{ Name = "Italian", Key = "it" },
	{ Name = "Japanese", Key = "ja" },
	{ Name = "Kannada", Key = "kn" },
	{ Name = "Korean", Key = "ko" },
	{ Name = "Latin", Key = "la" },
	{ Name = "Latvian", Key = "lv" },
	{ Name = "Lithuanian", Key = "lt" },
	{ Name = "Macedonian", Key = "mk" },
	{ Name = "Malay", Key = "ms" },
	{ Name = "Maltese", Key = "mt" },
	{ Name = "Norwegian", Key = "no" },
	{ Name = "Persian", Key = "fa" },
	{ Name = "Polish", Key = "pl" },
	{ Name = "Portuguese", Key = "pt" },
	{ Name = "Romanian", Key = "ro" },
	{ Name = "Russian", Key = "ru" },
	{ Name = "Serbian", Key = "sr" },
	{ Name = "Slovak", Key = "sk" },
	{ Name = "Slovenian", Key = "sl" },
	{ Name = "Spanish", Key = "es" },
	{ Name = "Swahili", Key = "sw" },
	{ Name = "Swedish", Key = "sv" },
	{ Name = "Tamil", Key = "ta" },
	{ Name = "Telugu", Key = "te" },
	{ Name = "Thai", Key = "th" },
	{ Name = "Turkish", Key = "tr" },
	{ Name = "Ukrainian", Key = "uk" },
	{ Name = "Urdu", Key = "ur" },
	{ Name = "Vietnamese", Key = "vi" },
	{ Name = "Welsh", Key = "cy" },
	{ Name = "Yiddish", Key = "yi" },
}

local LangKeys = {}
local LangIndexes = {}
local LangLookupByName = {}
local LangLookupByKey = {}

for i=1,#Languages do
	local Language = Languages[i]
	LangKeys[i] = Language.Name
	LangIndexes[Language.Key] = i
	LangLookupByName[Language.Name] = Language.Key
	LangLookupByKey[Language.Key] = Language.Name
end

table.sort(LangKeys)

local Settings = {}
Settings.EnableTranslation = true
Settings.TargetLang = "en"
Settings.TranslateSelf = true

local Paths = {}
Paths.Root = utils.get_appdata_path("PopstarDevs", "2Take1Menu")
Paths.Cfg = Paths.Root .. "\\cfg"
Paths.LogFile = Paths.Root .. "\\" .. ScriptName .. ".log"
Paths.Scripts = Paths.Root .. "\\scripts"

local function SaveSettings(SettingsFile, SettingsTbl)
	assert(SettingsFile, "Nil passed for SettingsFile to SaveSettings")
	assert(SettingsTbl, "Nil passed for SettingsTbl to SaveSettings")
	local file = io.open(Paths.Cfg .. "\\" .. SettingsFile .. ".cfg", "w")
	local keys = {}
	for k in pairs(SettingsTbl) do
		keys[#keys + 1] = k
	end
	table.sort(keys)
	for i=1,#keys do
		file:write(tostring(keys[i]) .. "=" .. tostring(SettingsTbl[keys[i]]) .. "\n")
	end
	file:close()
end

local function LoadSettings(SettingsFile, SettingsTbl)
	assert(SettingsFile, "Nil passed for SettingsFile to LoadSettings")
	assert(SettingsTbl, "Nil passed for SettingsTbl to LoadSettings")
	SettingsFile = Paths.Cfg .. "\\" .. SettingsFile .. ".cfg"
	if not utils.file_exists(SettingsFile) then
		return false
	end
	for line in io.lines(SettingsFile) do
		local separator = line:find("=", 1, true)
		if separator then
			local key = line:sub(1, separator - 1)
			local value = line:sub(separator + 1)
			local num = tonumber(value)
			if num then
				value = num
			elseif value == "true" then
				value = true
			elseif value == "false" then
				value = false
			end
			num = tonumber(key)
			if num then
				key = num
			end
			SettingsTbl[key] = value
		end
	end
	return true
end

LoadSettings(ScriptName, Settings)

local notif = menu.notify
local function notify(message, title, seconds, colour)
	title = title or ScriptName
	seconds = seconds or 10
	colour = colour or 0xFF0000FF
	notif(message, title, seconds, colour)
	print(string.format("[%s] %s > %s", ScriptName, title, message))
end

local function Translate(text, targetLang)
	local encoded = web.urlencode(text)
	print(encoded)
	if targetLang then
		targetLang = web.urlencode(targetLang)
	else
		targetLang = "en"
	end
	
	local statusCode, body = web.get("https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=" .. targetLang .. "&dt=t&q=" .. encoded)
	
	if statusCode ~= 200 then
		return false, body
	end
	
	local translation, original, sourceLang = body:match("^%[%[%[\"(.-)\",\"(.-)\",.-,.-,.-]],.-,\"(.-)\"")
	
	return true, translation, sourceLang
end

local function TranslateChat(event)
	local pid = event.sender
	if (Settings.TranslateSelf or pid ~= player.player_id()) and player.is_player_valid(pid) then
		local name = player.get_player_name(pid)
		
		local success, translation, sourceLang = Translate(event.body, Settings.TargetLang)
		
		if not success then
			notify("Error translating. Check console.")
			print(translation)
			return
		end
		
		if sourceLang ~= Settings.TargetLang then
			notify(translation, name .. ": Translated from " .. (LangLookupByKey[sourceLang] or sourceLang), nil, 0xFFFFFF00)
		end
	end
end

local ParentId = menu.add_feature(ScriptName, "parent").id

local EnableTranslationFeat = menu.add_feature("Enable Translation", "toggle", ParentId, function(f)
	Settings.EnableTranslation = f.on
	notify("Set EnableTranslation to: " .. tostring(Settings.EnableTranslation), nil, nil, 0xFF00FF00)
	if f.on then
		if f.data then
			return
		end
		
		f.data = event.add_event_listener("chat", TranslateChat)
	else
		if not f.data then
			return
		end
		
		event.remove_event_listener("chat", f.data)
		f.data = nil
	end
end)
EnableTranslationFeat.on = Settings.EnableTranslation

local TargetLangFeat = menu.add_feature("Target Language", "autoaction_value_str", ParentId, function(f)
	Settings.TargetLang = LangLookupByName[LangKeys[f.value + 1]]
	notify("Set TargetLang to: " .. Settings.TargetLang, nil, nil, 0xFF00FF00)
end)
TargetLangFeat:set_str_data(LangKeys)
TargetLangFeat.value = LangIndexes[Settings.TargetLang] - 1

local TranslateSelfFeat = menu.add_feature("Translate Self", "toggle", ParentId, function(f)
	Settings.TranslateSelf = f.on
	notify("Set TranslateSelf to: " .. tostring(Settings.TranslateSelf), nil, nil, 0xFF00FF00)
end)
TranslateSelfFeat.on = Settings.TranslateSelf

menu.add_feature("Save Settings", "action", ParentId, function(f)
	SaveSettings(ScriptName, Settings)
	notify("Settings Saved", nil, nil, 0xFF00FF00)
end)

menu.add_feature("Send Translated Message", "action_value_str", ParentId, function(f)
	local TargetLang = LangLookupByName[LangKeys[f.value + 1]]
	
	local r, s
	repeat
		r, s = input.get("Enter text to translate", "", 255, 0)
		if r == 2 then return HANDLER_POP end
		system.wait(0)
	until r == 0
	
	local success, translation, sourceLang = Translate(s, TargetLang)
		
	if not success then
		notify("Error translating. Check console.")
		print(translation)
		return
	end
	
	network.send_chat_message(translation, false)
end):set_str_data(LangKeys)