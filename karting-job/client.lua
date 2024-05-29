local QBCore = exports['qb-core']:GetCoreObject()
local Time = 0
local TicketAtivo = false
local car = nil

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ClearAreaOfVehicles(-623.19, -2126.88, 5.99, 1000, false, false, false, false, false)
        RemoveVehiclesFromGeneratorsInArea(-623.19 - 90.0, -2126.88 - 90.0, 5.99 - 90.0, -623.19 + 90.0, -2126.88 + 90.0, 5.99 + 90.0)
    end
end)

Citizen.CreateThread(function()
    local hash = GetHashKey("hc_driver")
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(1)
    end
    KartingPed = CreatePed(2, hash, Config.Locations['Ped'], false, false)
    SetPedFleeAttributes(KartingPed, 0, 0)
    SetPedDiesWhenInjured(KartingPed, false)
    TaskStartScenarioInPlace(KartingPed, "missheistdockssetup1clipboard@base", 0, true)
    SetPedKeepTask(KartingPed, true)
    SetBlockingOfNonTemporaryEvents(KartingPed, true)
    SetEntityInvincible(KartingPed, true)
    FreezeEntityPosition(KartingPed, true)

    exports['qb-target']:AddBoxZone("KartingPed", Config.Locations['PedTarget'], 1, 1, {
        name="KartingPed",
        heading=0,
        debugpoly = false,
    }, {
        options = {
            {
                event = "kartingGoGo:client:MenuAluger",
                icon = "fas fa-car",
                label = "Hello, do u want race?",
            }
        },
        distance = 2.5
    })

    local blip = AddBlipForCoord(Config.Locations['PedTarget'])
    SetBlipSprite(blip, 38)
    SetBlipDisplay(blip, 2)
    SetBlipScale(blip, 0.9)
    SetBlipColour(blip, 37)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString('Karting')
    EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent('kartingGoGo:client:MenuAluger', function()
    if TicketAtivo == true then
        exports['qb-menu']:openMenu({
            {
                header = Config.Exter.MenuHeader,
                isMenuHeader = true,
            },
            {
                header = Config.Exter.CloseMenu,
                event = "qb-menu:closeMenu",
                icon = "fas fa-times-circle",
            },
            {
                header = Config.Exter.StopTicket,
                txt = "",
                icon = "fas fa-ticket",
                event = "kartingGoGo:client:Ticket",
                params = {
                    event = "kartingGoGo:client:Ticket",
                    args = 5
                },
            },
        })
    else
        exports['qb-menu']:openMenu({
            {
                header = Config.Exter.MenuHeader,
                isMenuHeader = true,
            },
            {
                header = Config.Exter.CloseMenu,
                event = "qb-menu:closeMenu",
                icon = "fas fa-times-circle",
            },
            {
                header = Config.Exter.Ticket1,
                txt = Config.Exter.Duration .. Config.Tickets[1].time .. Config.Exter.Minutes .. "<br>" .. Config.Exter.Price .. Config.Tickets[1].price .. "$",
                icon = "fas fa-ticket",
                event = "kartingGoGo:client:Ticket1",
                params = {
                    event = "kartingGoGo:client:Ticket",
                    args = 1
                },
            },
            {
                header = Config.Exter.Ticket2,
                txt = Config.Exter.Duration .. Config.Tickets[2].time .. Config.Exter.Minutes .. "<br>" .. Config.Exter.Price .. Config.Tickets[2].price .. "$",
                icon = "fas fa-ticket",
                event = "kartingGoGo:client:Ticket",
                params = {
                    event = "kartingGoGo:client:Ticket",
                    args = 2
                },
            },
            {
                header = Config.Exter.Ticket3,
                txt = Config.Exter.Duration .. Config.Tickets[3].time .. Config.Exter.Minutes .. "<br>" .. Config.Exter.Price .. Config.Tickets[3].price .. "$",
                icon = "fas fa-ticket",
                params = {
                    event = "kartingGoGo:client:Ticket",
                    args = 3
                },
            },
            {
                header = Config.Exter.Ticket4,
                txt = Config.Exter.Duration .. Config.Tickets[4].time .. Config.Exter.Minutes .. "<br>" .. Config.Exter.Price .. Config.Tickets[4].price .. "$",
                icon = "fas fa-ticket",
                event = "kartingGoGo:client:Ticket",
                params = {
                    event = "kartingGoGo:client:Ticket",
                    args = 4
                },
            },
        })
    end
end)

local function drawTxt(text, font, x, y, scale, r, g, b, a)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextOutline()
    SetTextCentre(1)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

local function StopRace(notify)
    DeleteVehicle(car)
    TicketAtivo = false
    if not notify then return end
    QBCore.Functions.Notify(Config.Exter[(notify == 1 and "Finished" or "TicketCancelled")], 'primary', 7500)
end

local function startTimer()
    local gameTimer = GetGameTimer()
    Citizen.CreateThread(function()
        while TicketAtivo do
            Citizen.Wait(1)
            if GetGameTimer() < gameTimer + 1000 * Time then
                local secondsLeft = GetGameTimer() - gameTimer
                drawTxt(Config.Exter.TimeRemaning .. math.ceil(Time - secondsLeft / 1000) .. Config.Exter.Seconds, 4, 0.5, 0.93, 0.50, 255, 255, 255, 180)
            else
                StopRace(1)
                break
            end
        end
    end)
end

local function SpawnKart()
    TicketAtivo = true
    car = Config.CarSpawn
    local coords = Config.Locations['KartSpawn']

    QBCore.Functions.SpawnVehicle(car, function(veh)
        car = veh
        SetVehicleNumberPlateText(veh, "KART"..tostring(math.random(1000, 9999)))
        exports['LegacyFuel']:SetFuel(veh, 100.0)
        TriggerEvent("vehiclekeys:client:SetOwner", GetVehicleNumberPlateText(veh))
        SetVehicleEngineOn(veh, true, true)
        startTimer()
    end, coords, true)
end

RegisterNetEvent('kartingGoGo:client:Ticket', function(arg)
    if arg >= 1 and arg <= 4 and not TicketAtivo then
        QBCore.Functions.TriggerCallback("kartingGoGo:server:BuyTicket", function(has)
            if not has then QBCore.Functions.Notify(Config['Exter']['NoMoney'], "error"); return end
            Time = Config['Tickets'][arg].time * 60
            SpawnKart()
        end, arg)
    elseif arg == 5 and TicketAtivo then
        StopRace(2)
    else
        QBCore.Functions.Notify(Config.Exter.ActiveTicket, 'error', 7500)
    end
end)
Citizen.CreateThread(function()
        if TicketAtivo then
            StopRace()
            QBCore.Functions.Notify(Config.Exter.DeletedVehicle, 'primary', 7500)
        end
    end)
