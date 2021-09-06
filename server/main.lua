local ESX, items = nil, {}

local function getItemLabel(item)
    return ESX.GetItemLabel(item:lower())
end

local function doesItemExists(item)
    return getItemLabel(item:lower()) ~= nil
end

local function updateShopData(cb)
    items = {}
    MySQL.Async.fetchAll("SELECT * FROM shop_categories JOIN shop_items ON shop_items.category_name = shop_categories.category_name", {}, function(result)
        for k,v in pairs(result) do
            if not items[v.category_label] then items[v.category_label] = {} end
            if doesItemExists(v.item_name) then
                table.insert(items[v.category_label], {name = v.item_name, max = v.item_max, label = getItemLabel(v.item_name), price = v.item_price})
            end
        end
        if cb ~= nil then cb() end
    end)
end

TriggerEvent(Config.esxGetter, function(obj)
    ESX = obj
    updateShopData()
end)


RegisterNetEvent("shops:openMenu")
AddEventHandler("shops:openMenu", function(shopId)
    local _src = source
    TriggerClientEvent("shops:openMenu", _src, items)
end)

RegisterNetEvent("shops:pay")
AddEventHandler("shops:pay", function(indexes, ammount, payWithBank)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    
    local item = items[indexes[1]][indexes[2]]
    local price = (item.price*ammount)
    if not item then
        TriggerClientEvent("shops:receiveCb", _src, Config.messages["pay_error_occured"])
        return
    end
    local playerMoney = payWithBank and xPlayer.getAccount(Config.bankAccountName).money or xPlayer.getMoney()
    if playerMoney < price then
        TriggerClientEvent("shops:receiveCb", _src, Config.messages["pay_error_no_enough"])
        return
    end
    if payWithBank then
        xPlayer.removeAccountMoney(Config.bankAccountName, price)
    else
        xPlayer.removeMoney(price)
    end
    xPlayer.addInventoryItem(item.name, ammount)
    TriggerClientEvent("shops:receiveCb", _src, Config.messages["pay_success"])
end)

RegisterCommand("shop_refresh", function(_src, args)
    if _src ~= 0 then return end
    updateShopData(function()
        print(Config.messages["console_shop_refreshed"])
    end)
end, false)
