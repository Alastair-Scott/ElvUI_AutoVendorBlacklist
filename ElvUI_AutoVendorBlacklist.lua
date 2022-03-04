local E, L, V, P, G = unpack(ElvUI); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local AutoVendorBlacklist = E:NewModule('AutoVendorBlacklist', 'AceHook-3.0', 'AceEvent-3.0', 'AceTimer-3.0'); --Create a plugin within ElvUI and adopt AceHook-3.0, AceEvent-3.0 and AceTimer-3.0. We can make use of these later.
local EP = LibStub("LibElvUIPlugin-1.0") --We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local B = E:GetModule('Bags')
local addonName, addonTable = ... --See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2

local GetItemInfoInstant = GetItemInfoInstant

--Default options
P["AutoVendorBlacklist"] = {
	["Enabled"] = true,
	["ItemBlacklist"] = B.ExcludeGrays,
	["DefaultItemBlacklist"] = B.ExcludeGrays,
}

local function Reset()
	E.db.AutoVendorBlacklist.ItemBlacklist = E.db.AutoVendorBlacklist.DefaultItemBlacklist
	AutoVendorBlacklist:Update()
end

local function AddItem(info, value)
	local itemId = GetItemInfoInstant(value)
	if not itemId then return end

	local item = Item:CreateFromItemID(itemId)

	item:ContinueOnItemLoad(function()
		local name = item:GetItemName()
		if not E.db.AutoVendorBlacklist.ItemBlacklist[itemId] then
			E.db.AutoVendorBlacklist.ItemBlacklist[itemId] = name
			--print("Added item to blacklist: "..name.. " ("..itemId..")")
		end

		AutoVendorBlacklist:Update()
	end)
end

local function RemoveItem(itemId)
	if not itemId then return end

	if E.db.AutoVendorBlacklist.ItemBlacklist[itemId] then
		E.db.AutoVendorBlacklist.ItemBlacklist[itemId] = nil
		--print("Removed item from blacklist: ".. itemId)
	end

	AutoVendorBlacklist:Update()
end

--Function we can call when a setting changes.
function AutoVendorBlacklist:Update()
	local enabled = E.db.AutoVendorBlacklist.Enabled
	
		AutoVendorBlacklist:InsertOptions()

		if enabled then
			B.ExcludeGrays = E.db.AutoVendorBlacklist.ItemBlacklist
		else
			B.ExcludeGrays = E.db.AutoVendorBlacklist.DefaultItemBlacklist
		end
end

--This function inserts our GUI table into the ElvUI Config. You can read about AceConfig here: http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
function AutoVendorBlacklist:InsertOptions()
	E.Options.args.AutoVendorBlacklist = {
		order = 100,
		type = "group",
		name = "AutoVendorBlacklist",
		args = {
			Enabled = {
				order = 100,
				type = "toggle",
				name = "Enable",
				get = function(info)
					return E.db.AutoVendorBlacklist.Enabled
				end,
				set = function(info, value)
					E.db.AutoVendorBlacklist.Enabled = value
					AutoVendorBlacklist:Update() --We changed a setting, call our Update function
				end,
			},
			Header = {
				order = 200,
				type = "header",
				name = "",
			},
			AddItem = {
				order = 300,
				type = "input",
				name = "Add Item",
				get = function(info)
					return ""
				end,
				set = AddItem,
			},
			ItemBlacklist = {
				order = 400,
				type = "group",
				name = "Blacklist",
				guiInline = true,
				args = {
				},
			},
			Reset = {
				order = 500,
				type = "execute",
				name = "Reset",
				confirm = function(info)
					return "Are you sure you wish to reset your blacklist?"
				end,
				func = Reset,
			},
		},
	}
	local i = 0
	for k, v in pairs(E.db.AutoVendorBlacklist.ItemBlacklist) do
		i = i + 1
		E.Options.args.AutoVendorBlacklist.args.ItemBlacklist.args["BlackListedItem"..k] = {
			order = i,
			type = "execute",
			name = v .. " ("..k..")",
			width = 2,
			confirm = function(info)
				return "Are you sure you wish to remove " .. v .. " from your blacklist?"
			end,
			func = function() RemoveItem(k) end,
		}
	end
end

function AutoVendorBlacklist:Initialize()
	--Register plugin so options are properly inserted when config is loaded
	EP:RegisterPlugin(addonName, AutoVendorBlacklist.InsertOptions)
	AutoVendorBlacklist:Update()
end

E:RegisterModule(AutoVendorBlacklist:GetName()) --Register the module with ElvUI. ElvUI will now call AutoVendorBlacklist:Initialize() when ElvUI is ready to load our plugin.