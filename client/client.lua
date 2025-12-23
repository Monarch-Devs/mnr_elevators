local elevators = lib.load('config.config')

local playerZone = 0

local function createElevator(name, label, floors)
    local menu = {}

    for floorIndex, floor in ipairs(floors) do
        for zoneIndex, zone in pairs(floor.zones) do
            lib.zones.box({
                coords = vec3(zone.coords.x, zone.coords.y, zone.coords.z),
                size = zone.size,
                rotation = zone.coords.w,
                onEnter = function()
                    playerZone = zoneIndex

                    lib.showTextUI(locale('textui_elevator'), { position = 'left-center', icon = 'fa-solid fa-building' })
                end,
                onExit = function()
                    playerZone = 0

                    lib.hideTextUI()
                end,
                inside = function()
                    if IsControlJustReleased(0, 38) then
                        lib.showContext(('mnr_elevators:menu:%s'):format(name))
                    end
                end,
                debug = floor.debug or false,
            })
        end

        menu[#menu + 1] = {
            title = floor.title,
            description = floor.description,
            icon = floor.locked and 'fas fa-lock' or 'fas fa-lock-open',
            iconColor = floor.locked and '#FF0000' or '#008000',
            onSelect = function()
                local hasAccess = lib.callback.await('mnr_elevators:server:HasAccess', false, name, floorIndex)
                if floor.locked and not hasAccess then
                    client.Notify(locale('access_denied'), 'error')
                    return
                end

                if playerZone == 0 then return end

                DoScreenFadeOut(1000)
                Wait(2000)

                local zone = floor.zones[playerZone]
                if not zone then
                    local availableIndex = next(floor.zones)
                    if availableIndex then
                        zone = floor.zones[availableIndex]
                    else
                        DoScreenFadeIn(1000)
                        return
                    end
                end

                SetEntityCoords(cache.ped, zone.coords.x, zone.coords.y, zone.coords.z, false, false, false, false)
                SetEntityHeading(cache.ped, zone.coords.w)

                Wait(2000)
                DoScreenFadeIn(1000)

                client.Notify(locale('reached_floor'), 'success')
            end,
        }
    end

    lib.registerContext({ id = ('mnr_elevators:menu:%s'):format(name), title = label, options = menu })
end

for name, data in pairs(elevators) do
    createElevator(name, data.label, data.floors)
end