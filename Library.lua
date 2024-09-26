--[[
Akascape Plugin Library

Description: A library/store application of Akascape's plugins for Davinci Resolve
(Code licensed as MIT)

Made by Akash Bora (Akascape)
App Version: 1.0.0
]]--


local ffi = require 'ffi'
local curl = require 'lj2curl'
local ezreq = require 'lj2curl.CRLEasyRequest'
local json = require("dkjson")
local fu =  app:GetResolve():Fusion(); composition = fu.CurrentComp;
local root_folder = app:MapPath("Scripts:/Comp/Akascape/")
local icon_folder = "Scripts:/Comp/Akascape/icons/"

local data = nil
local html_content = ""

-- CONFIG FILE LINKS:
local database_link = "https://raw.githubusercontent.com/Akascape/PluginLibrary-Resolve/refs/heads/main/database.json"
local version_link = "https://raw.githubusercontent.com/Akascape/PluginLibrary-Resolve/refs/heads/main/version.json"
local library_link = "https://raw.githubusercontent.com/Akascape/PluginLibrary-Resolve/refs/heads/main/Library.lua"
local promotion_link = "https://raw.githubusercontent.com/Akascape/PluginLibrary-Resolve/refs/heads/main/promotion.html"

-- Function to retrieve data from links
function GET(url)
    local req = ezreq(url)
    req:setOption(curl.CURLOPT_HTTPGET, 1) -- Use GET method

    local response_body = {}
    
    -- Define a local function to handle the response data
    local function write_callback(chunk, size, nmemb, userdata)
        local len = size * nmemb
        local str = ffi.string(chunk, len)
        table.insert(response_body, str)
        return len
    end
    
    -- Cast the Lua function to a C-style function pointer
    local write_function_ptr = ffi.cast("size_t(*)(char *, size_t, size_t, void *)", write_callback)
    -- Set the callback function to handle response data
    req:setOption(curl.CURLOPT_WRITEFUNCTION, write_function_ptr)
    local ok, err = req:perform()
    if ok then
        local response_data = table.concat(response_body) -- Get the complete response body
    	return response_data
    else
        print("Error retrieving data:", err) 
		return nil
    end
end

-- Shuffle the products for better experience
function shuffle(tbl)
    local size = #tbl
    for i = size, 2, -1 do
		math.randomseed(os.time() + os.clock())
        local rand = math.random(size)
        tbl[i], tbl[rand] = tbl[rand], tbl[i]
    end
end

-- Load data from the json files
function load_data()
	-- Database Content
	local content = io.open(root_folder.."database.json", "r")
	local json_string = content:read("*all")
	content:close()
	data = json.decode(json_string)
	shuffle(data.products)
	-- Promotional Content
	local pfile = io.open(root_folder.."promotion.html", "r")
	if pfile then
		html_content = pfile:read("*all")
		pfile:close()
	end
end

local current_database_version = nil
local current_news_date = nil
local current_app_version = nil

-- load current version of database, news and app
function load_version()
	local v_content = io.open(root_folder.."version.json", "r")
	local json_string = v_content:read("*all")
	v_content:close()
	local version_data = json.decode(json_string)
	-- Storing values in separate variables
    current_database_version = version_data.database_version
    current_news_date = version_data.news_date
    current_app_version = version_data.app_version
end

load_version()

if comp==nil then
	print("Akascape Plugin Library: Please open the app after adding any composition!")
	return
end

-- Scan Macro Plugins
mp1 = MultiPath('Macros:;Templates:')
mp1:Map(comp:GetCompPathMap())
macro_files = mp1:ReadDir("*.setting", true, true) 

-- Scan Fuse Plugins
mp2 = MultiPath('Fuses:;LUTs:')
mp2:Map(comp:GetCompPathMap())
fuse_files = mp2:ReadDir("*.fuse", true, true) 

load_data()

-- Build the UI and Widgets 
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

win = disp:AddWindow(
	{
		ID = "AkascapeLib",
		WindowTitle = "Akascape Plugin Library",
		Geometry = { 100,100,400,400 },
		Composition = comp,
		WindowOpacity = 0.97,
		Spacing = 10,

		ui:VGroup
		{
			ID = "root",
			MaximumSize = {390, 390},
			MinimumSize = {300, 390},
			ui:HGroup
			{
				Weight = 0,
				ui:LineEdit{ ID = "search_box", PlaceholderText = "Search...", StyleSheet = "padding-left: 10px; text-align: left;background-color:#1e1f22;border-radius: 10px; color:#bdc3c7 ",
							Flat = true, Weight = 1.5, MinimumSize = {250, 24} },
				ui:Button { ID = "search", IconSize = { 23, 23 }, Icon = ui:Icon { File = icon_folder .. "search.png" },  
							StyleSheet = " border:none;text-align: left; ",Flat = true, MinimumSize = { 30, 30 }, MaximumSize = { 35, 32 } },
				ui:Button { ID = "mail", IconSize = { 23, 23 }, Icon = ui:Icon { File = icon_folder .. "mailbox.png" },  ToolTip = "Mailbox",
							StyleSheet = " border:none;text-align: left; ",Flat = true, MinimumSize = { 30, 30 }, MaximumSize = { 35, 32 } },
				ui:Button { ID = "update", IconSize = { 23, 23 }, Icon = ui:Icon { File = icon_folder .. "update.png" },  ToolTip = "Update",
							StyleSheet = " border:none;text-align: left; ",Flat = true, MinimumSize = { 30, 30 }, MaximumSize = { 35, 32 } },
			},
			ui:HGroup
			{
				Weight =0,
				ui:Label{ID = 'L', Text = string.rep("_",70), StyleSheet = " border:none;"},
			},
			ui:HGroup
			{
				Weight = 0,
				
				ui:Button{ ID = "all", Text = "All", MinimumSize = { 50, 22 }, StyleSheet = "color:#ffffff;", Checkable = true, AutoExclusive = true, Checked = true},
				ui:Button{ ID = "installed", Text = "Installed" , MinimumSize = { 50, 22 }, StyleSheet = "color:#848484;", Checkable = true, AutoExclusive = true,},
				ui:Button{ ID = "notinstalled", Text = "Not Installed" , MinimumSize = { 50, 22 }, StyleSheet = "color:#848484;", Checkable = true, AutoExclusive = true,},
				ui:VGap(2),
			},
			ui:HGroup
			{
				Weight = 0,
				ui:HGap(0, 1.0),
			},
			ui:HGroup
			{
				Weight = 0,
				ui:Button { ID = "p1left",Text="", IconSize = { 50, 50 },
							StyleSheet = " border:none;text-align: left; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 10px; border-bottom-left-radius: 10px; border-top-right-radius: 0; border-bottom-right-radius: 0;font-weight: bold;",
							Flat = true, Weight = 3, MinimumSize = { 50, 50 }},
				ui:Button { ID = "p1right",Text="",
							StyleSheet = " border:none;text-align: center; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 0; border-bottom-left-radius: 0; border-top-right-radius: 10px; border-bottom-right-radius: 10px; font-size: 16px;",
							Flat = true, },
			},
			ui:HGroup
			{
				Weight = 0,
				ui:Button { ID = "p2left",Text="", IconSize = { 50, 50 }, 
							StyleSheet = " border:none;text-align: left; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 10px; border-bottom-left-radius: 10px; border-top-right-radius: 0; border-bottom-right-radius: 0; font-weight: bold;",
							Flat = true, Weight = 3, MinimumSize = { 50, 50 }},
				ui:Button { ID = "p2right",Text="",  
							StyleSheet = " border:none;text-align: center; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 0; border-bottom-left-radius: 0; border-top-right-radius: 10px; border-bottom-right-radius: 10px; font-size: 16px;",
							Flat = true, },
			},
			ui:HGroup
			{
				Weight = 0,
				ui:Button { ID = "p3left",Text="", IconSize = { 50, 50 },   
							StyleSheet = " border:none;text-align: left; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 10px; border-bottom-left-radius: 10px; border-top-right-radius: 0; border-bottom-right-radius: 0;font-weight: bold;",
							Flat = true, Weight = 3, MinimumSize = { 50, 50 }},
				ui:Button { ID = "p3right",Text="",  
							StyleSheet = " border:none;text-align: center; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 0; border-bottom-left-radius: 0; border-top-right-radius: 10px; border-bottom-right-radius: 10px; font-size: 16px;",
							Flat = true, },
			},
			ui:HGroup
			{
				Weight = 0,
				ui:Button { ID = "p4left",Text="", IconSize = { 50, 50 }, 
							StyleSheet = " border:none;text-align: left; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 10px; border-bottom-left-radius: 10px; border-top-right-radius: 0; border-bottom-right-radius: 0;font-weight: bold;",
							Flat = true, Weight = 3, MinimumSize = { 50, 50 }},
				ui:Button { ID = "p4right",Text="",  
							StyleSheet = " border:none;text-align: center; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 0; border-bottom-left-radius: 0; border-top-right-radius: 10px; border-bottom-right-radius: 10px; font-size: 16px;",
							Flat = true, },
			},
			ui:HGroup
			{
				Weight = 0,
				ui:Button { ID = "p5left",Text="", IconSize = { 50, 50 },
							StyleSheet = " border:none;text-align: left; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 10px; border-bottom-left-radius: 10px; border-top-right-radius: 0; border-bottom-right-radius: 0;font-weight: bold;",
							Flat = true, Weight = 3, MinimumSize = { 50, 50 }},
				ui:Button { ID = "p5right",Text="",  
							StyleSheet = " border:none;text-align: center; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 0; border-bottom-left-radius: 0; border-top-right-radius: 10px; border-bottom-right-radius: 10px; font-size: 16px;",
							Flat = true, },
			},
			ui:HGroup
			{
				weight = 0,
				ui:HGap(0, 0.01),
				ui:Label{ ID = "lb1", Text = "News and Offer", Hidden = true, MinimumSize = {200,20}, StyleSheet = "font-size: 16px;"},
				ui:VGap(1),
			},
			ui:HGroup
			{
				ui:TextEdit{ ID = 'HTMLPreview', ReadOnly = true, Hidden = true, Events = {AnchorClicked = true},},
			},
			ui:HGroup
			{
				Weight = 0,
				ui:Button { ID = "previous", Text="◁ Previous", StyleSheet = " border:none;text-align: left; color:#bdc3c7",Flat = true, MaximumSize = { 70, 14 }},
				ui:Button { ID = "next", Text="Next ▷", StyleSheet = " border:none;text-align: left; color:#bdc3c7 ",Flat = true,  MaximumSize = { 70, 15 }},
				ui:HGap(0, 0.4),
				ui:Label{ ID = "about", Text="v"..current_app_version.." | Made by Akascape",Flat = true,  MaximumSize = { 200, 20 }},
			},
		},
	})

itm = win:GetItems()

-- Save data to file
local function file_save(data, filename)
    local file = io.open(filename, "wb")
	file:write(data)
	file:close()
end

-- Function to decode a Base64 encoded string
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local b64 = {}
for i = 1, #b64chars do
    b64[string.sub(b64chars, i, i)] = i - 1
end
function decode(data)
    data = string.gsub(data, '[^'..b64chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b64[x] or 0)
        for i = 6, 1, -1 do r = r .. (f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d%d%d%d%d%d', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (string.sub(x, i, i) == '1' and 2^(8 - i) or 0) end
        return string.char(c)
    end))
end

local currentPage = 1
local itemsPerPage = 5

-- Verify which plugins are installed
function check_installed(name, plug_type)
    if plug_type == "Fuse" then
		for i, val in ipairs(fuse_files) do
            if not val.IsDir and val.Name == name .. ".fuse" then
                return true
            end
        end
        return false
    elseif plug_type == "Macro" then
        for i, val in ipairs(macro_files) do
            if not val.IsDir and val.Name == name .. ".setting" then
                return true
            end
        end
        return false
    end
end

-- Show the products in the page
function show_content(sorted_data, page, search_text)
    local startIndex = (page - 1) * itemsPerPage + 1
    local endIndex = math.min(startIndex + itemsPerPage - 1, #sorted_data.products)
    local count = 0
    local itm = {
        {left = itm.p1left, right = itm.p1right},
        {left = itm.p2left, right = itm.p2right},
        {left = itm.p3left, right = itm.p3right},
        {left = itm.p4left, right = itm.p4right},
        {left = itm.p5left, right = itm.p5right}
    }

    local filtered_products = {}
	-- Filter the searchbox
    if search_text then
        for _, product in ipairs(sorted_data.products) do
            if product.product_name:lower():find(search_text:lower()) then
                table.insert(filtered_products, product)
            end
        end
    else
        filtered_products = sorted_data.products
    end
    
	-- load the product content
    for i = startIndex, endIndex do
        local product = filtered_products[i]
        local currentItem = itm[count + 1]
			
        if product then
			
            if product.product_name then
                currentItem.left.Text = product.product_name
            end
            if product.product_logo then
                img_file = app:MapPath(root_folder.."/temp/"..product.product_name..".png")
                if bmd.fileexists(img_file) == false then
                    file_save(decode(product.product_logo), img_file)
                end
                currentItem.left.Icon = ui:Icon { File = img_file }
            end
            if product.product_price then
				if product.status then
					currentItem.right.Text = "OPEN"
					currentItem.right.StyleSheet = " border:none;text-align: center; background-color:#3d3d47;color:#ffffff;border-top-left-radius: 0; border-bottom-left-radius: 0; border-top-right-radius: 10px; border-bottom-right-radius: 10px; font-size: 16px;"
				else 
					if (product.product_price=="Free") then
						currentItem.right.Text = product.product_price
						currentItem.right.StyleSheet = " border:none;text-align: center; background-color:#3d3d47;color:#54d14f;border-top-left-radius: 0; border-bottom-left-radius: 0; border-top-right-radius: 10px; border-bottom-right-radius: 10px; font-size: 16px;"
					else
						currentItem.right.Text = "$" .. product.product_price
						currentItem.right.StyleSheet = " border:none;text-align: center; background-color:#3d3d47;color:yellow;border-top-left-radius: 0; border-bottom-left-radius: 0; border-top-right-radius: 10px; border-bottom-right-radius: 10px; font-size: 16px;"
					end
				end
            end
            if product.product_link then
				if product.status then
					currentItem.right.ToolTip = ""
				else
					currentItem.right.ToolTip = product.product_link
				end
			end
            count = count + 1
        end
    end
    -- fill empty space
    for i = count + 1, itemsPerPage do
        local currentItem = itm[i]
        currentItem.left.Text = ""
        currentItem.left.Icon = ui:Icon { File = nil }
        currentItem.right.Text = ""
		currentItem.right.ToolTip = ""
    end
end

local currentFilteredData = data

function win.On.next.Clicked(ev)
    if currentPage * itemsPerPage < #currentFilteredData.products then
        currentPage = currentPage + 1
        show_content(currentFilteredData, currentPage, itm.search_box.Text)
    end
end

function win.On.previous.Clicked(ev)
    if currentPage > 1 then
        currentPage = currentPage - 1
        show_content(currentFilteredData, currentPage, itm.search_box.Text)
    end
end

function win.On.search_box.TextChanged(ev)
    show_content(currentFilteredData, 1, itm.search_box.Text)
end

function toggle_product_section(option) 
	itm.p1left.Hidden = option
	itm.p1right.Hidden = option

	itm.p2left.Hidden = option
	itm.p2right.Hidden = option

	itm.p3left.Hidden = option
	itm.p3right.Hidden = option

	itm.p4left.Hidden = option
	itm.p4right.Hidden = option
 
	itm.p5left.Hidden = option
	itm.p5right.Hidden = option

	itm.previous.Hidden = option
	itm.next.Hidden = option
	itm.about.Hidden = option
end

function win.On.mail.Clicked(ev)
	itm.mail.Icon = ui:Icon {File = icon_folder.."mailbox-select.png"}
	itm.search.Icon = ui:Icon {File = icon_folder.."search-off.png"}
    
	itm.all.Hidden = true
	itm.AkascapeLib:RecalcLayout()
	itm.installed.Hidden = true
	itm.AkascapeLib:RecalcLayout()
	itm.notinstalled.Hidden = true
    itm.AkascapeLib:RecalcLayout()

	toggle_product_section(true)
    itm.AkascapeLib:RecalcLayout()

	itm.HTMLPreview.Hidden = false
	itm.lb1.Hidden = false
	itm.HTMLPreview.HTML = html_content

	itm.AkascapeLib:RecalcLayout()
end

function win.On.search.Clicked(ev)
	itm.mail.Icon = ui:Icon {File = icon_folder.."mailbox.png"}
	itm.search.Icon = ui:Icon {File = icon_folder.."search.png"}

	itm.all.Hidden = false
	itm.installed.Hidden = false
	itm.notinstalled.Hidden = false

	itm.AkascapeLib:RecalcLayout()

	toggle_product_section(false)

	itm.HTMLPreview.Hidden = true
	itm.lb1.Hidden = true

	itm.AkascapeLib:RecalcLayout()
end

-- waiting/sleep function
function wait(seconds)
    local start = os.time()
    repeat until os.time() > start + seconds
end

-- check installed or not first
function check_status()
	for _, product in ipairs(data.products) do
		product.status = check_installed(product.product_name, product.product_type)
	end
end

function win.On.update.Clicked(ev)
	itm.mail.Icon = ui:Icon {File = icon_folder.."mailbox.png"}
	itm.search.Icon = ui:Icon {File = icon_folder.."search-off.png"}
	itm.update.Icon = ui:Icon {File = icon_folder.."update-on.png"}

	toggle_product_section(true)
	
	itm.HTMLPreview.Hidden = true
	itm.lb1.Hidden = false
	itm.lb1.Text = "Checking for updates..."
	itm.AkascapeLib:RecalcLayout()

	local check_version_file = GET(version_link)
	wait(0.5)
	if check_version_file~=nil then
		local new_version_data = json.decode(check_version_file)
		local changed = false
        -- Update Database
		if (new_version_data.database_version>current_database_version) then
			itm.lb1.Text = "Updating Database..."
			local new_database = GET(database_link)
			if new_database~=nil then
				file_save(new_database, root_folder.."database.json")
				load_data()
				check_status()
				for _, product in ipairs(data.products) do
					img_file = app:MapPath(root_folder.."/temp/"..product.product_name..".png")
					if bmd.fileexists(img_file) then
						os.remove(img_file)
					end
				end
				win.On.search.Clicked()
				win.On.all.Clicked()
				current_database_version = new_version_data.database_version
				changed = true
			end
		end
        -- Update news and offer
		if (new_version_data.news_date>current_news_date) then
			itm.lb1.Text = "Checking for new offers..."
			local new_promotion = GET(promotion_link)
			if new_promotion~=nil then
				file_save(new_promotion, root_folder.."promotion.html")
				win.On.search.Clicked()
				itm.mail.Icon = ui:Icon {File = icon_folder.."mailbox-new.png"}
				html_content = new_promotion
				itm.HTMLPreview.HTML = html_content
				current_news_date = new_version_data.news_date
				changed = true
			end
		end
        -- Update Library.lua
		if (new_version_data.app_version>current_app_version) then
			itm.lb1.Text = "Updating the app..."
			current_app_version = new_version_data.app_version
			changed = true
			local new_app = GET(library_link)
			if new_app~=nil then
				file_save(new_app, root_folder.."library.lua")
				itm.lb1.Text = "Restart Required!"
				wait(1)
				win.On.AkascapeLib.Close()
			end
		end
		if changed then
			file_save(check_version_file, root_folder.."version.json")
			itm.lb1.Text = "Update Successfull!"
			wait(1)
		else 
			itm.lb1.Text = "No Updates!"
			wait(0.6)
			win.On.search.Clicked()
		end
	else 
		itm.lb1.Text = "Unable to connect :("
		wait(1)
		win.On.search.Clicked()
	end
	itm.lb1.Text = "News and Offer"
	itm.update.Icon = ui:Icon {File = icon_folder.."update.png"}
end

function win.On.all.Clicked(ev)
	itm.installed.StyleSheet = "color:#848484;"
	itm.notinstalled.StyleSheet = "color:#848484;"
	itm.all.StyleSheet = "color:#ffffff;"
	show_content(data, currentPage, itm.search_box.Text)
	currentFilteredData = data
end

function win.On.installed.Clicked(ev)
	itm.installed.StyleSheet = "color:#ffffff;"
	itm.notinstalled.StyleSheet = "color:#848484;"
	itm.all.StyleSheet = "color:#848484;"
	local filtered_data = { products = {} }
    for _, product in ipairs(data.products) do
        if product.status then
            table.insert(filtered_data.products, product)
        end
    end
    show_content(filtered_data, 1, itm.search_box.Text)
	currentFilteredData = filtered_data
end

function win.On.notinstalled.Clicked(ev)
	itm.installed.StyleSheet = "color:#848484;"
	itm.notinstalled.StyleSheet = "color:#ffffff;"
	itm.all.StyleSheet = "color:#848484;"
	local filtered_data = { products = {} }
    for _, product in ipairs(data.products) do
        if product.status == false then
            table.insert(filtered_data.products, product)
        end
    end
    show_content(filtered_data, 1, itm.search_box.Text)
	currentFilteredData = filtered_data
end

-- Spawn the installed plugin node in the fusion composition
function open_node(item, name) 
	if item.Text == "OPEN" then
		for i, val in ipairs(macro_files) do
            if val.Name == name .. ".setting" then
                comp:Paste(bmd.readfile(comp:MapPath(val.FullPath)))
				return
            end
        end
		for i, val in ipairs(fuse_files) do
            if val.Name == name .. ".fuse" then
                comp:AddTool("Fuse."..name, -32768, -32768)
				return
            end
        end
	else
		os.execute('start "" "' .. item.ToolTip .. '"')
	end
end

function win.On.HTMLPreview.AnchorClicked(ev)
	os.execute('start "" "' .. ev.URL .. '"')
end

function win.On.p1right.Clicked(ev) 
	open_node(itm.p1right, itm.p1left.Text)
end

function win.On.p2right.Clicked(ev) 
	open_node(itm.p2right, itm.p2left.Text)
end

function win.On.p3right.Clicked(ev) 
	open_node(itm.p3right, itm.p3left.Text)
end

function win.On.p4right.Clicked(ev) 
	open_node(itm.p4right, itm.p4left.Text)
end

function win.On.p5right.Clicked(ev) 
	open_node(itm.p5right, itm.p5left.Text)
end

check_status()
itm.all.Checked = true

show_content(data, currentPage, itm.search_box.Text)
itm.AkascapeLib:RecalcLayout()

function win.On.AkascapeLib.Close(ev)
	disp:ExitLoop()
end

win:Show()

disp:RunLoop()

win:Hide()
