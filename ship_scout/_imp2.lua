local function round(number, steps)
    steps = steps or 1
    return math.floor(number * steps + 0.5) / steps
end

if event.type == "program" or event.type == "on" then
    digiline_send("timer1", "5")
    digiline_send("timer1", "loop_on")
    digiline_send("timer2", "1")
    digiline_send("timer2", "loop_on")

    digiline_send("hud1", " ")
    digiline_send("hud2", " ")
    digiline_send("hud1", "Starship Booting...")
    digiline_send("hud2", "Booting...")
    digiline_send("hud1", "...")
    digiline_send("hud2", "...")

    digiline_send("disp_r1", "System\nBooting...\n\nWaiting\nData..")
    digiline_send("disp_r2", "... ")
    digiline_send("disp_r3", "... ")
    digiline_send("disp_ll", "Loading... ")
    digiline_send("disp_l2", "> ... ")
    digiline_send("disp_l3", "> ... ")

    digiline_send("ram1", {
        command = "write",
        address = 0,
        data = "1"
    })
end

if event.type == "digiline" and event.channel == "timer1" and event.msg == "done" then
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

    digiline_send("ship_gravity_drive", {
        command = "status"
    })
end

if event.type == "digiline" and event.channel == "timer2" and event.msg == "done" then
    -- digiline_send("disp2", "tick")

    digiline_send("ram1", {
        command = "read",
        address = 0
    })
end

if event.type == "digiline" then

    -- RAM ticker..
    if event.channel == "ram1" then
        digiline_send("ram1", {
            command = "write",
            address = 0,
            data = tostring(tonumber(event.msg) + 1)
        })
        local message = "" -- event.msg
        -- Clocks display
        if tonumber(event.msg) > 3 then
            local time = os.datetable()
            digiline_send("disp_l1", time.hour .. ":" .. time.min .. ":" .. time.sec)
        end
        if tonumber(event.msg) > 3 then
            local time = os.datetable()
            digiline_send("disp_bed_1", time.hour .. ":" .. time.min .. ":" .. time.sec)
        end
    end

    -- Nav something...
    if event.channel == "ship_scout" and event.msg.command == "dest" then
        local dest_dir = event.msg.dest_dir
        if dest_dir and dest_dir > 0 then
            digiline_send("ship_engine_core", {
                command = "ready"
            })
            digiline_send("disp2", "Navigation\nReady!")
        end
    end
    -- Engines status
    if event.channel == "ship_scout" and event.msg.command == "status_ack" then
        local ready = event.msg.ready
        if ready and ready > 0 then
            digiline_send("disp_r1", "Engines\nCharged!")
        else
            digiline_send("disp_r1", "Engines\nCharging..")
            digiline_send("disp_r3", "Pending...")
        end
    end

    -- Engine 1
    if event.channel == "ship_engine_r" and event.msg.command == "status_ack" then
        local mes = "> Engine 1"
        if event.msg.charge > 0 then
            mes = mes .. "\nCHRG: " .. tostring(round((event.msg.charge / event.msg.charge_max) * 100, 10)) .. "%"
            digiline_send("disp_r2", mes)
        else
            mes = mes .. "\nCHRG: 0%"
            digiline_send("disp_r2", mes)
        end
        if event.msg.enable then
            digiline_send("disp_r2", "STAT: " .. 'ON')
            digiline_send("ship_engine_core", {
                command = "status_c",
                enable = true,
                channel = "ship_engine_r"
            })
        else
            digiline_send("disp_r2", "STAT: " .. 'OFF')
            digiline_send("ship_engine_core", {
                command = "status_c",
                enable = false,
                channel = "ship_engine_r"
            })
        end

        mem.eng1_charge = event.msg.charge
        mem.eng1_charge_m = event.msg.charge_max

        -- local chrg_r = event.msg.charge
        -- digiline_send("ram1", {command = "write", address = "0", data = chrg_r})

    end
    -- Engine 2
    if event.channel == "ship_engine_l" and event.msg.command == "status_ack" then
        -- digiline_send("disp_r2", "> Engine 2")
        local mes = "> Engine 2"
        if event.msg.charge > 0 then
            mes = mes .. "\nCHRG: " .. tostring(round((event.msg.charge / event.msg.charge_max) * 100, 10)) .. "%"
            digiline_send("disp_r2", mes)
        else
            mes = mes .. "\nCHRG: 0%"
            digiline_send("disp_r2", mes)
        end
        if event.msg.enable then
            digiline_send("disp_r2", "STAT: " .. 'ON')
            digiline_send("ship_engine_core", {
                command = "status_c",
                enable = true,
                channel = "ship_engine_l"
            })
        else
            digiline_send("disp_r2", "STAT: " .. 'OFF')
            digiline_send("ship_engine_core", {
                command = "status_c",
                enable = false,
                channel = "ship_engine_l"
            })
        end

        mem.eng2_charge = event.msg.charge
        mem.eng2_charge_m = event.msg.charge_max

        -- local chrg_l = event.msg.charge
        -- digiline_send("ram1", {command = "write", address = "1", data = chrg_l})
    end

    if event.channel == "ship_engine_r" and event.msg.command == "ready_ack" then
        digiline_send("disp_l2", "" .. event.msg.ready)
    end
    if event.channel == "ship_engine_l" and event.msg.command == "ready_ack" then
        digiline_send("disp_l2", "" .. event.msg.ready)
    end

end
