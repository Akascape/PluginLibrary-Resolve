--[[
Script to change title bar color, 
made by Akash Bora (Akascape)
Version-1, Licensed as CC-BY-SA
28-9-2024
]]--

local os_name = os.getenv("OS")
if os_name:lower():find("windows") == nil then
    print("Not a Windows Environment!")
    return
end

local ffi = require("ffi")
local dwmapi = ffi.load("dwmapi")
local user32 = ffi.load("user32")

ffi.cdef[[
    typedef int BOOL;
    typedef unsigned long DWORD;
    typedef void* HWND;
    typedef int HRESULT;
    typedef long LPARAM;
    typedef const char* LPCSTR;

    BOOL EnumWindows(int (*lpEnumFunc)(HWND, LPARAM), LPARAM lParam);
    int GetWindowTextA(HWND hWnd, LPCSTR lpString, int nMaxCount);
    DWORD GetWindowThreadProcessId(HWND hWnd, DWORD* lpdwProcessId);

    HWND FindWindowA(const char* lpClassName, const char* lpWindowName);
    HRESULT DwmSetWindowAttribute(HWND hwnd, DWORD dwAttribute, const void* pvAttribute, DWORD cbAttribute);
]]

local function change_header_color(hwnd, color, mode)

    local color_value = ffi.new("DWORD[1]", tonumber(color, 16))
    local DWMWA_ATTRIBUTE = mode

    local result = dwmapi.DwmSetWindowAttribute(hwnd, DWMWA_ATTRIBUTE, color_value, ffi.sizeof(color_value))
end

local function findWindowStartingWith(prefix)
    local foundHwnd = nil
    local buffer = ffi.new("char[?]", 256)

    local function enumFunc(hwnd, lParam)
        local length = user32.GetWindowTextA(hwnd, buffer, 256)
        local title = ffi.string(buffer, length)
        if title:sub(1, #prefix) == prefix then
            foundHwnd = hwnd
            return false 
        end
        return true 
    end

    user32.EnumWindows(enumFunc, 0)
    return foundHwnd
end

local hwnd = findWindowStartingWith("DaVinci Resolve")

-- Build the UI and Widgets 
local ui = fu.UIManager
local disp = bmd.UIDispatcher(ui)

win = disp:AddWindow(
	{
		ID = "btb",
		WindowTitle = "Custom Title Bar",
		Geometry = { 100,100,400,200 },
		Composition = comp,
		Spacing = 10,
		ui:VGroup
		{
			ID = "root",
            MaximumSize = {390, 190},
			MinimumSize = {300, 190},
            ui:HGroup
			{
				weight = 0,
				ui:HGap(0, 0.01),
				ui:Label{ ID = "lb1", Text = "Choose Color for Title Bar", MinimumSize = {200,20}, StyleSheet = "font-size: 16px; color:white;"},
				ui:VGap(1),
			},
            ui:HGroup
            {
                ui:ComboBox{ID = 'MyCombo', Text = 'Combo Menu', MaximumSize = {300, 20}, Events = {CurrentIndexChanged= true}},
                
            },
            ui:HGroup
            {
                ui:ColorPicker{ ID = "Color", Color = { R = 0.0, G = 0.0, B = 0.0}, MaximumSize = {300, 100},},
            },
            ui:HGroup
            {
                weight = 0,
                ui:HGap(1),
                ui:Button{ID = 'b1', Text = 'SET', MaximumSize = {290, 20},},
            },
            ui:HGroup
            {
                weight = 0,
                ui:HGap(1),
                ui:HGap(0, 0.27),
                ui:Label{ ID = "lb2", Text = "Made by Akascape | V1"},
            }
        }
        
    }
)

itm = win:GetItems()
itm.MyCombo:AddItem('Mica-Dark')
itm.MyCombo:AddItem('Dark')
itm.MyCombo:AddItem('Normal')
itm.MyCombo:AddItem('Custom Color')

function win.On.btb.Close(ev)
	disp:ExitLoop()
end
local red = 0
local green = 0
local blue = 0

function win.On.MyCombo.CurrentIndexChanged(ev)
    local index = itm.MyCombo.CurrentIndex
    if index==0 then
        itm.Color.Color = { R = 0, G = 0, B = 0}
        itm.Color.Enabled = false
    elseif index==1 then
        itm.Color.Color = { R = 0, G = 0, B = 0}
        itm.Color.Enabled = false
    elseif index==2 then
        itm.Color.Color = { R = 1, G = 1, B = 1}
        itm.Color.Enabled = false
    elseif index==3 then
        itm.Color.Color = { R = red, G = green, B = blue}
        itm.Color.Enabled = true
    end
end

function rgbToHexString(red, green, blue)
    -- Helper function to convert a single color value to a two-character hex string
    local function toHex(value)
        if value == 1 then
            return "FF"
        else
            return string.format("%02d", math.floor(value * 100))
        end
    end
    local blueHex = toHex(blue)
    local greenHex = toHex(green)
    local redHex = toHex(red)

    -- Concatenate in "BBGGRR" format
    return blueHex .. greenHex .. redHex
end

function win.On.b1.Clicked(ev)
    local index = itm.MyCombo.CurrentIndex
    change_header_color(hwnd, "000000", 20)
    change_header_color(hwnd, "000000", 19)
    change_header_color(hwnd, "000000", 1029)
    if index==1 then
        change_header_color(hwnd, "000000", 35)
    elseif index==0 then
        change_header_color(hwnd, "FFFFFF", 20)
        change_header_color(hwnd, "FFFFFF", 19)
        change_header_color(hwnd, "FFFFFF", 1029)
    elseif index==2 then
        change_header_color(hwnd, "FFFFFF", 35)
    elseif index==3 then
        red = itm.Color.Color.R
        green = itm.Color.Color.G
        blue = itm.Color.Color.B
        change_header_color(hwnd, rgbToHexString(red, green, blue), 35)
    end
end

win:Show()
disp:RunLoop()
win:Hide()