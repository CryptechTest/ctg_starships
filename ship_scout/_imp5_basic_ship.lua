local function round(number, steps)
    steps = steps or 1
    return math.floor(number * steps + 0.5) / steps
end

if event.type == "program" or event.type == "on" then
    digiline_send("timer1", "2")
    digiline_send("timer1", "loop_on")
    digiline_send("timer2", "1")
    digiline_send("timer2", "loop_on")

    digiline_send("hud_mid", "Starship Booting...\nLoading...")
    digiline_send("hud_l", "\n...")
    digiline_send("hud_r", "\n...")

    -- mem.eng_enabled = true
    mem.eng1_rdy = false
    mem.eng2_rdy = false

    mem.mese1 = 0
    mem.mese2 = 0

    mem.mese_tck = 0;

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

if event.type == "digiline" and event.channel == "btn2" and event.msg == "cpu_reset" then
    -- local c = { command = "cpu_reset", channel = "btn2" }

    digiline_send("timer1", "5")
    digiline_send("timer1", "loop_on")
    digiline_send("timer2", "1")
    digiline_send("timer2", "loop_on")

    digiline_send("hud_mid", "Starship Booting...\nLoading...")
    digiline_send("hud_l", "\n...")
    digiline_send("hud_r", "\n...")

    digiline_send("ram1", {
        command = "write",
        address = 0,
        data = "1"
    })
end

if event.type == "digiline" and event.channel == "eng_toggle" and event.msg == "toggle" then
    -- local c = { command = "enabled", channel = "btn2" }
    if not mem.eng_enabled then
        mem.eng_enabled = true
        digiline_send("ship_engine_l", {
            command = "enable"
        })
        digiline_send("ship_engine_r", {
            command = "enable"
        })
    else
        mem.eng_enabled = false
        digiline_send("ship_engine_l", {
            command = "disable"
        })
        digiline_send("ship_engine_r", {
            command = "disable"
        })
    end
end

if event.type == "digiline" and event.channel == "timer2" and event.msg == "done" then
    -- digiline_send("disp2", "tick")
    digiline_send("ram1", {
        command = "read",
        address = 0
    })

    mem.mese_tck = mem.mese_tck + 1
    if mem.mese_tck < 13 then
        return
    end
    mem.mese_tck = 0

    if port.d == false then
        if mem.mese1 > mem.mese2 then
            port.d = true
            return
        elseif mem.mese2 > mem.mese1 then
            port.d = true
            return
        end
    end

    port.d = false
end

if event.type == "digiline" then
    if event.channel == "ship_engine" and event.msg == "request_mese" then
        port.d = true
    end

    if event.channel == "det1" and event.msg == "request_mese" then
        mem.mese1 = mem.mese1 + 1
    end
    if event.channel == "det2" and event.msg == "request_mese" then
        mem.mese2 = mem.mese2 + 1
    end
end

if event.type == "digiline" then

    local msg_hud_m = ""
    local msg_hud_l = ""
    local msg_hud_r = ""

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
            msg_hud_m = msg_hud_m .. time.hour .. ":" .. time.min .. ":" .. time.sec
        end

        local rdy_mes = ""
        if mem.eng_enabled and mem.eng1_rdy and mem.eng2_rdy then
            rdy_mes = "Ready for Jump!"
        elseif mem.eng1_rdy and mem.eng2_rdy then
            rdy_mes = "Engines Offline!\nJump Ready!"
        else
            rdy_mes = "Charging Engines!"
        end
        msg_hud_m = msg_hud_m .. "\n \n" .. rdy_mes
        digiline_send("hud_mid", msg_hud_m)

        if mem.tick == nil then
            mem.tick = 1
        elseif mem.tick <= 0 then
            mem.tick = 7
        end
        mem.tick = mem.tick - 1
        return
    end

    -- Engine 1
    if event.channel == "ship_engine_r" and event.msg.command == "status_ack" then
        local mes = "> Engine 1"
        if event.msg.charge > 0 then
            mes = mes .. "\nCHRG: " .. tostring(round((event.msg.charge / event.msg.charge_max) * 100, 10)) .. "%\n"
            msg_hud_r = msg_hud_r .. mes
        else
            mes = mes .. "\nCHRG: 0%"
            msg_hud_r = msg_hud_r .. mes
        end
        if event.msg.enable == 1 then
            msg_hud_r = msg_hud_r .. "\nSTAT: " .. 'ON'
        else
            msg_hud_r = msg_hud_r .. "\nSTAT: " .. 'OFF'
        end

        digiline_send("eng_starboard", mes .. "\n" .. msg_hud_r .. "\n\n")
        digiline_send("hud_r", msg_hud_r)

        mem.eng1_charge = event.msg.charge
        mem.eng1_charge_m = event.msg.charge_max
        if mem.eng1_charge > mem.eng1_charge_m then
            mem.eng1_rdy = true
        else
            mem.eng1_rdy = false
        end
        return
    end
    -- Engine 2
    if event.channel == "ship_engine_l" and event.msg.command == "status_ack" then
        local mes = "> Engine 2"
        if event.msg.charge > 0 then
            mes = mes .. "\nCHRG: " .. tostring(round((event.msg.charge / event.msg.charge_max) * 100, 10)) .. "%\n"
            msg_hud_l = msg_hud_l .. mes
        else
            mes = mes .. "\nCHRG: 0%"
            msg_hud_l = msg_hud_l .. mes
        end
        if event.msg.enable == 1 then
            msg_hud_l = msg_hud_l .. "\nSTAT: " .. 'ON'
        else
            msg_hud_l = msg_hud_l .. "\nSTAT: " .. 'OFF'
        end

        digiline_send("eng_port", mes .. "\n" .. msg_hud_l .. "\n\n")
        digiline_send("hud_l", msg_hud_l)

        mem.eng2_charge = event.msg.charge
        mem.eng2_charge_m = event.msg.charge_max
        if mem.eng2_charge > mem.eng2_charge_m then
            mem.eng2_rdy = true
        else
            mem.eng2_rdy = false
        end
        return
    end

    if event.channel == "ship_engine_r" and event.msg.command == "ready_ack" then
        if mem.eng_enabled then
            msg_hud_r = "\n" .. event.msg.ready
            mem.eng1_rdy = true
        else
            msg_hud_r = "\n" .. "ENG 1 OFFLINE"
        end
        if mem.tick <= 1 then
            digiline_send("hud_r", msg_hud_r)
        end
        return
    end
    if event.channel == "ship_engine_l" and event.msg.command == "ready_ack" then
        if mem.eng_enabled then
            msg_hud_l = "\n" .. event.msg.ready
        else
            msg_hud_l = "\n" .. "ENG 2 OFFLINE"
        end
        if mem.tick <= 1 then
            digiline_send("hud_l", msg_hud_l)
        end
        return
    end
end
