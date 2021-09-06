local ESX, isMenuActive, serverUpdating = nil, false, false
local title, desc = Config.messages["shop_main_title"], Config.messages["shop_main_desc"]

local function customGroupDigits(value)
	local left,num,right = string.match(value,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1' .. "."):reverse())..right
end

local function showbox(TextEntry, ExampleText, MaxStringLenght, isValueInt)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    local blockinput = true
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
        Wait(0)
    end
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        if isValueInt then
            local isNumber = tonumber(result)
            if isNumber and tonumber(result) > 0 then
                return result
            else
                return nil
            end
        end

        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end

local function openMenu(itemsInfos)
    if isMenuActive then return end
    local selectedCat, selectedItem, selectedAmmount
    FreezeEntityPosition(PlayerPedId(), true)
    isMenuActive = true

    RMenu.Add("shops", "shops_main", RageUI.CreateMenu(title, desc, nil, nil, "pablo", "black"))
    RMenu:Get("shops", "shops_main").Closed = function()
        isMenuActive = false
        FreezeEntityPosition(PlayerPedId(), false)
    end

    RMenu.Add("shops", "shops_confirm", RageUI.CreateSubMenu(RMenu:Get("shops", "shops_main"), title, desc, nil, nil, "pablo", "black"))
    RMenu:Get("shops", "shops_confirm").Closed = function()
    end

    RageUI.Visible(RMenu:Get("shops", "shops_main"), true)

    Citizen.CreateThread(function()
        while isMenuActive do
            RageUI.IsVisible(RMenu:Get("shops", "shops_main"), true, true, true, function()
                RageUI.Separator(Config.welcome)
                for category, items in pairs(itemsInfos) do
                    RageUI.Separator("~s~↓ ~b~"..category.." ~s~(~y~"..#items.."~s~) ~s~↓")
                    for itemId, item in pairs(items) do
                        RageUI.ButtonWithStyle(item.label, Config.messages["buy_desc"]:format(item.label), {RightLabel = "~g~"..customGroupDigits(item.price).."$~s~ →→"}, not serverUpdating, function(_,_,s)
                            if s then
                                local qty = tonumber(showbox(Config.messages["contextbox_qty"], "", 16, true))
                                if qty ~= nil and qty > 0 and qty <= tonumber(item.max) then
                                    selectedCat = category
                                    selectedItem = itemId
                                    selectedAmmount = qty
                                elseif qty == nil then
                                    ESX.ShowNotification(Config.messages["select_qty_invalid"])
                                elseif qty > tonumber(item.max) then
                                    ESX.ShowNotification(Config.messages["selected_qty_exceeded"]:format(item.max, item.label))
                                else
                                    ESX.ShowNotification(Config.messages["select_qty_invalid"])
                                end
                            end
                        end, RMenu:Get("shops", "shops_confirm"))
                    end
                end
            end, function()
            end)

            RageUI.IsVisible(RMenu:Get("shops", "shops_confirm"), true, true, true, function()
                if selectedCat == nil or selectedItem == nil or selectedAmmount == nil then
                    RageUI.GoBack()
                else
                    RageUI.Separator(Config.welcome)
                    RageUI.Separator(Config.messages["pay_confirm"]:format(selectedAmmount, itemsInfos[selectedCat][selectedItem].label))
                    RageUI.Separator(Config.messages["pay_ammount"]:format(customGroupDigits(itemsInfos[selectedCat][selectedItem].price*selectedAmmount)))
                    RageUI.ButtonWithStyle(Config.messages["pay_cash"], nil, {RightLabel = "→→"}, not serverUpdating, function(_,_,s)
                        if s then
                            serverUpdating = true
                            TriggerServerEvent("shops:pay", {selectedCat, selectedItem}, selectedAmmount, false)
                        end
                    end)
                    RageUI.ButtonWithStyle(Config.messages["pay_bank"], nil, {RightLabel = "→→"}, not serverUpdating, function(_,_,s)
                        if s then
                            serverUpdating = true
                            TriggerServerEvent("shops:pay", {selectedCat, selectedItem}, selectedAmmount, true)
                        end
                    end)
                end
            end, function()
            end)
            
            Wait(0)
        end
    end)
end

Citizen.CreateThread(function()
    TriggerEvent(Config.esxGetter, function(obj)
        ESX = obj
    end)
    for k,v in pairs(Config.shops) do
        local blip = AddBlipForCoord(v.pos)
		SetBlipSprite(blip, 59)
        SetBlipColour(blip, 47)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentString("Magasin")
		EndTextCommandSetBlipName(blip)
    end
    while true do
        local interval = 250
        local playerPos = GetEntityCoords(PlayerPedId())
        for k,v in pairs(Config.shops) do
            local pos = v.pos
            local dst = #(pos-playerPos)
            if dst <= 30.0 and not isMenuActive and not serverUpdating then
                interval = 0
                DrawMarker(22, pos, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 252, 186, 3, 255, 55555, false, true, 2, false, false, false, false)
                if dst <= 1.0 then
                    ESX.ShowHelpNotification(Config.messages["zone_interactWithShop"])
                    if IsControlJustPressed(0, 51) then
                        serverUpdating = true
                        TriggerServerEvent("shops:openMenu", k)
                    end
                end
            end 
        end
        Wait(interval)
    end
end)

RegisterNetEvent("shops:openMenu")
AddEventHandler("shops:openMenu", function(itemsInfos)
    serverUpdating = false
    openMenu(itemsInfos)
end)

RegisterNetEvent("shops:receiveCb")
AddEventHandler("shops:receiveCb", function(message)
    serverUpdating = false
    if message then ESX.ShowNotification(message) end
end)