local function round(number, steps)
    steps = steps or 1
    return math.floor(number * steps + 0.5) / steps
end

if event.type == "program" or event.type == "on" then
    digiline_send("timer1", "5")
    digiline_send("timer1", "loop_on")
    digiline_send("timer2", "1")
    digiline_send("timer2", "loop_on")

    digiline_send("disp1", "System\nBooted...\n\nWaiting\nCharge..")
    digiline_send("disp2", "...")
    digiline_send("disp3", " \n ")
    digiline_send("disp4", " \n \nLoading...\n \n \n ")
    digiline_send("disp5", "> ...\n \n \n ")

    digiline_send("ram1", {
        command = "write",
        address = 0,
        data = "1"
    })
end

if event.type == "digiline" and event.channel == "timer1" and event.msg == "done" then
    digiline_send("ship_scout", {
        command = "dest"
    })
    digiline_send("ship_scout", {
        command = "status"
    })
    digiline_send("ship_engine_r", {
        command = "status"
    })
    digiline_send("ship_engine_l", {
        command = "status"
    })
    digiline_send("ship_engine_r", {
        command = "ready"
    })
    digiline_send("ship_engine_l", {
        command = "ready"
    })
    digiline_send("ship_engine_core", {
        command = "is_ready"
    })
    digiline_send("ship_engine_core", {
        command = "status"
    })
    digiline_send("port_engine", "get")
    digiline_send("starboard_engine", "get")
end

if event.type == "digiline" and event.channel == "timer2" and event.msg == "done" then
    --digiline_send("disp2", "tick")

    digiline_send("ram1", {
        command = "read",
        address = 0
    })
end

if event.type == "digiline" then

    if event.channel == "port_engine" then
        digiline_send("engine_disp1", "Engine Power")
        digiline_send("engine_disp1", " ")
        digiline_send("engine_disp1", "Supply: ")
        digiline_send("engine_disp1", "+" .. event.msg.supply .. "")
        digiline_send("engine_disp1", "Demand: ")
        digiline_send("engine_disp1", "-" .. event.msg.demand .. "")
    end
    if event.channel == "starboard_engine" then
        digiline_send("engine_disp2", "Engine Power")
        digiline_send("engine_disp2", " ")
        digiline_send("engine_disp2", "Supply: ")
        digiline_send("engine_disp2", "+" .. event.msg.supply .. "")
        digiline_send("engine_disp2", "Demand: ")
        digiline_send("engine_disp2", "-" .. event.msg.demand .. "")
    end

    if event.channel == "ram1" then
        digiline_send("ram1", {
            command = "write",
            address = 0,
            data = tostring(tonumber(event.msg) + 1)
        })
        local message = "" -- event.msg
        -- digiline_send("disp2", "" .. message)
        if tonumber(event.msg) > 3 then 
            local time = os.datetable()
            digiline_send("disp2", time.hour .. ":" .. time.min .. ":" .. time.sec)
        end
    end

    if event.channel == "ship_scout" and event.msg.command == "dest" then
        local dest_dir = event.msg.dest_dir
        if dest_dir and dest_dir > 0 then
            digiline_send("ship_engine_core", {
                command = "ready"
            })
            digiline_send("disp2", "Navigation\nReady!")
        end
    end
    if event.channel == "ship_scout" and event.msg.command == "status" then
        local ready = event.msg.ready
        if ready and ready > 0 then
            digiline_send("disp1", "Engines\nCharged!")
        else
            digiline_send("disp1", "Engines\nCharging..")
            digiline_send("disp2", "Pending...")
        end
    end
    if event.channel == "ship_engine_core" and event.msg.command == "is_ready" then
        -- digiline_send("disp2", "Pepare to enter\nhyperspace...")
        -- digiline_send("disp1", "Jump Ready!")
        digiline_send("disp2", "Hyperdrive\nNavigation\nReady!")
    end
    if event.channel == "ship_engine_core" and event.msg.command == "status" then
        local message = "Hyperdrive Nav\n"
        if event.msg.enable then
            message = message .. "STATUS: " .. 'ON\n'
        else
            message = message .. "STATUS: " .. 'OFF\n'
        end
        if event.msg.charge > 0 then
            message = message .. "CHRG: " .. tostring(round((event.msg.charge / event.msg.charge_max) * 100, 100)) ..
                          "%"
        else
            message = message .. "CHRG: 0%"
        end
        digiline_send("disp1", message)

    end
    if event.channel == "ship_engine_r" and event.msg.command == "status" then
        digiline_send("disp4", "> Engine 1")
        if event.msg.enable then
            digiline_send("disp4", "STAT: " .. 'ON')
            digiline_send("ship_engine_core", {
                command = "status_c",
                enable = true,
                channel = "ship_engine_r"
            })
        else
            digiline_send("disp4", "STAT: " .. 'OFF')
            digiline_send("ship_engine_core", {
                command = "status_c",
                enable = false,
                channel = "ship_engine_r"
            })
        end
        if event.msg.charge > 0 then
            digiline_send("disp4",
                "CHRG: " .. tostring(round((event.msg.charge / event.msg.charge_max) * 100, 100)) .. "%")
        else
            digiline_send("disp4", "CHRG: 0%")
        end

        mem.eng1_charge = event.msg.charge
        mem.eng1_charge_m = event.msg.charge_max

        -- local chrg_r = event.msg.charge
        -- digiline_send("ram1", {command = "write", address = "0", data = chrg_r})

    end
    if event.channel == "ship_engine_l" and event.msg.command == "status" then
        digiline_send("disp4", "> Engine 2")
        if event.msg.enable then
            digiline_send("disp4", "STAT: " .. 'ON')
            digiline_send("ship_engine_core", {
                command = "status_c",
                enable = true,
                channel = "ship_engine_l"
            })
        else
            digiline_send("disp4", "STAT: " .. 'OFF')
            digiline_send("ship_engine_core", {
                command = "status_c",
                enable = false,
                channel = "ship_engine_l"
            })
        end
        if event.msg.charge > 0 then
            digiline_send("disp4",
                "CHRG: " .. tostring(round((event.msg.charge / event.msg.charge_max) * 100, 100)) .. "%")
        else
            digiline_send("disp4", "CHRG: 0%")
        end

        mem.eng2_charge = event.msg.charge
        mem.eng2_charge_m = event.msg.charge_max

        -- local chrg_l = event.msg.charge
        -- digiline_send("ram1", {command = "write", address = "1", data = chrg_l})
    end

    if event.channel == "ship_engine_r" and event.msg.command == "ready" then
        digiline_send("disp3", "" .. event.msg.ready)
    end
    if event.channel == "ship_engine_l" and event.msg.command == "ready" then
        digiline_send("disp3", "" .. event.msg.ready)
    end

    if event.channel == "ram1" and event.msg.command == "read" then

    end
end
