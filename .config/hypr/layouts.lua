-- Custom tiled layouts, selected per workspace as "lua:<name>" (see ~/scripts/hyprland/layout-selector).

local function box(x, y, w, h)
    return { x = x, y = y, w = w, h = h }
end

local function stack(targets, from, area, vertical)
    local count = #targets - from + 1
    for i = from, #targets do
        local k = i - from
        if vertical then
            targets[i]:place(box(area.x, area.y + area.h * k / count, area.w, area.h / count))
        else
            targets[i]:place(box(area.x + area.w * k / count, area.y, area.w / count, area.h))
        end
    end
end

-- Per workspace key: layout, previous, ratio and window order. Saved so choices survive reloads.
local statePath = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/hypr-layouts.lua"
local state = {}
local lastActive = {}
local luaLayouts = {}

local function serialize(value)
    if type(value) == "table" then
        local parts = {}
        for k, v in pairs(value) do
            parts[#parts + 1] = "[" .. serialize(k) .. "] = " .. serialize(v)
        end
        return "{ " .. table.concat(parts, ", ") .. " }"
    elseif type(value) == "string" then
        return string.format("%q", value)
    end
    return tostring(value)
end

local function save()
    local file = io.open(statePath, "w")
    if not file then return end
    file:write("return " .. serialize(state) .. "\n")
    file:close()
end

local function load()
    local chunk = loadfile(statePath)
    if not chunk then return end
    local ok, saved = pcall(chunk)
    if ok and type(saved) == "table" then state = saved end
end

load()

local function entry(key)
    state[key] = state[key] or {}
    return state[key]
end

local function workspaceKey(workspace)
    return workspace.id > 0 and tostring(workspace.id) or workspace.name
end

local function workspaceId(ctx)
    for _, t in ipairs(ctx.targets) do
        if t.window and t.window.workspace then return workspaceKey(t.window.workspace) end
    end
end

local function ratio(ctx, default)
    local key = workspaceId(ctx)
    local delta = key and state[key] and state[key].ratio or 0
    return math.max(0.2, math.min(0.85, default + delta))
end

local function activeIndex(ctx)
    local id = workspaceId(ctx)
    local active = hl.get_active_window()
    if active and active.workspace and workspaceKey(active.workspace) == id then lastActive[id] = active.address end
    for i, t in ipairs(ctx.targets) do
        if t.window and t.window.address == lastActive[id] then return i end
    end
    return 1
end

local function orderedTargets(ctx)
    local key = workspaceId(ctx)
    if not key then return ctx.targets end
    local s = entry(key)
    local present, seen, order = {}, {}, {}
    for _, t in ipairs(ctx.targets) do
        if t.window then present[t.window.address] = true end
    end
    for _, address in ipairs(s.order or {}) do
        if not seen[address] and (present[address] or hl.get_window("address:" .. address)) then
            order[#order + 1] = address
            seen[address] = true
        end
    end
    for _, t in ipairs(ctx.targets) do
        if t.window and not seen[t.window.address] then
            order[#order + 1] = t.window.address
            seen[t.window.address] = true
        end
    end
    if table.concat(order, " ") ~= table.concat(s.order or {}, " ") then
        s.order = order
        save()
    end
    local rank = {}
    for i, address in ipairs(order) do rank[address] = i end
    local targets = { table.unpack(ctx.targets) }
    table.sort(targets, function(a, b)
        return (a.window and rank[a.window.address] or math.huge) < (b.window and rank[b.window.address] or math.huge)
    end)
    return targets
end

local function withOrder(ctx)
    local targets = orderedTargets(ctx)
    return setmetatable({ targets = targets }, { __index = function(_, k) return ctx[k] end })
end

local function layoutMsg(ctx, msg)
    if msg == "refresh" then return true end
    local key = workspaceId(ctx)
    if not key then return false end
    local s = entry(key)
    local step = tonumber(msg:match("^ratio%s+([+-]?[%d.]+)$") or "")
    if step then
        s.ratio = math.max(-0.5, math.min(0.5, (s.ratio or 0) + step))
        save()
        return true
    end
    local active = hl.get_active_window()
    local order = s.order or {}
    local index
    for i, address in ipairs(order) do
        if active and address == active.address then index = i end
    end
    if not index then return false end
    local target = msg == "promote" and 1 or msg == "swap next" and index + 1 or msg == "swap prev" and index - 1 or nil
    if not target or target < 1 or target > #order or target == index then return false end
    if msg == "promote" then
        table.insert(order, 1, table.remove(order, index))
    else
        order[index], order[target] = order[target], order[index]
    end
    save()
    return true
end

local function register(name, recalculate)
    luaLayouts[name] = true
    hl.layout.register(name, {
        recalculate = function(ctx) recalculate(withOrder(ctx)) end,
        layout_msg = function(ctx, msg) return layoutMsg(withOrder(ctx), msg) end,
    })
end

-- Lua layouts only see focus on recalculation, so accordion needs a nudge on every focus change.
hl.on("window.active", function()
    local workspace = hl.get_active_workspace()
    if workspace and (workspace.tiled_layout or ""):sub(1, 4) == "lua:" then
        hl.dispatch(hl.dsp.layout("refresh"))
    end
end)

register("columns", function(ctx)
    stack(ctx.targets, 1, ctx.area, false)
end)

register("rows", function(ctx)
    stack(ctx.targets, 1, ctx.area, true)
end)

register("grid", function(ctx)
    local n = #ctx.targets
    if n == 0 then return end
    local a = ctx.area
    local cols = math.ceil(math.sqrt(n))
    local rows = math.ceil(n / cols)
    local i = 1
    for r = 0, rows - 1 do
        local inRow = math.min(cols, n - i + 1)
        local rowArea = box(a.x, a.y + a.h * r / rows, a.w, a.h / rows)
        local rowTargets = { table.unpack(ctx.targets, i, i + inRow - 1) }
        stack(rowTargets, 1, rowArea, false)
        i = i + inRow
    end
end)

register("focus", function(ctx)
    local n = #ctx.targets
    if n == 0 then return end
    local a = ctx.area
    if n == 1 then
        ctx.targets[1]:place(a)
        return
    end
    local mainWidth = a.w * ratio(ctx, 0.7)
    ctx.targets[1]:place(box(a.x, a.y, mainWidth, a.h))
    stack(ctx.targets, 2, box(a.x + mainWidth, a.y, a.w - mainWidth, a.h), true)
end)

register("centered", function(ctx)
    local n = #ctx.targets
    if n == 0 then return end
    local a = ctx.area
    local mainWidth = a.w * ratio(ctx, 0.6)
    local sideWidth = (a.w - mainWidth) / 2
    ctx.targets[1]:place(box(a.x + sideWidth, a.y, mainWidth, a.h))
    local right, left = {}, {}
    for i = 2, n do
        table.insert(i % 2 == 0 and right or left, ctx.targets[i])
    end
    stack(right, 1, box(a.x + sideWidth + mainWidth, a.y, sideWidth, a.h), true)
    stack(left, 1, box(a.x, a.y, sideWidth, a.h), true)
end)

register("spiral", function(ctx)
    local n = #ctx.targets
    local a = ctx.area
    local x, y, w, h = a.x, a.y, a.w, a.h
    for i, t in ipairs(ctx.targets) do
        if i == n then
            t:place(box(x, y, w, h))
            break
        end
        local r = i == 1 and ratio(ctx, 0.5) or 0.5
        local side = (i - 1) % 4
        if side == 0 then
            t:place(box(x, y, w * r, h))
            x, w = x + w * r, w * (1 - r)
        elseif side == 1 then
            t:place(box(x, y, w, h * r))
            y, h = y + h * r, h * (1 - r)
        elseif side == 2 then
            t:place(box(x + w * (1 - r), y, w * r, h))
            w = w * (1 - r)
        else
            t:place(box(x, y + h * (1 - r), w, h * r))
            h = h * (1 - r)
        end
    end
end)

register("dual", function(ctx)
    local n = #ctx.targets
    local a = ctx.area
    if n <= 2 then
        stack(ctx.targets, 1, a, false)
        return
    end
    local mainsWidth = a.w * ratio(ctx, 0.7)
    stack({ ctx.targets[1], ctx.targets[2] }, 1, box(a.x, a.y, mainsWidth, a.h), false)
    stack(ctx.targets, 3, box(a.x + mainsWidth, a.y, a.w - mainsWidth, a.h), true)
end)

register("accordion", function(ctx)
    local n = #ctx.targets
    if n == 0 then return end
    local a = ctx.area
    if n == 1 then
        ctx.targets[1]:place(a)
        return
    end
    local active = activeIndex(ctx)
    local activeWidth = a.w * ratio(ctx, 0.7)
    local restWidth = (a.w - activeWidth) / (n - 1)
    local x = a.x
    for i, t in ipairs(ctx.targets) do
        local w = i == active and activeWidth or restWidth
        t:place(box(x, a.y, w, a.h))
        x = x + w
    end
end)

register("deck", function(ctx)
    local n = #ctx.targets
    if n == 0 then return end
    local a = ctx.area
    if n == 1 then
        ctx.targets[1]:place(a)
        return
    end
    local mainWidth = a.w * ratio(ctx, 0.6)
    ctx.targets[1]:place(box(a.x, a.y, mainWidth, a.h))
    for i = 2, n do
        ctx.targets[i]:place(box(a.x + mainWidth, a.y, a.w - mainWidth, a.h))
    end
end)

local floatTag = "layoutfloat"

local function hasFloatTag(window)
    local tags = window.tags
    if type(tags) == "table" then
        for _, tag in ipairs(tags) do
            if tag == floatTag then return true end
        end
        return false
    end
    return type(tags) == "string" and tags:find(floatTag, 1, true) ~= nil
end

local function floatArea(workspace)
    local m = workspace.monitor
    local w, h = m.width / m.scale, m.height / m.scale
    if m.transform % 2 == 1 then w, h = h, w end
    local r = type(m.reserved) == "table" and m.reserved or {}
    local g = hl.get_config("general.gaps_out")
    if type(g) ~= "table" then g = { top = g or 0, right = g or 0, bottom = g or 0, left = g or 0 } end
    local left = (r.left or r[1] or 0) + g.left
    local top = (r.top or r[2] or 0) + g.top
    local right = (r.right or r[3] or 0) + g.right
    local bottom = (r.bottom or r[4] or 0) + g.bottom
    return box(m.x + left, m.y + top, w - left - right, h - top - bottom)
end

local floatArrangements = {
    cascade = function(a, n)
        local w, h, step = a.w * 0.6, a.h * 0.65, 40
        local fit = math.max(1, math.floor(math.min(a.w - w, a.h - h) / step) + 1)
        local boxes = {}
        for i = 1, n do
            local k = (i - 1) % fit
            boxes[i] = box(a.x + k * step, a.y + k * step, w, h)
        end
        return boxes
    end,
    pip = function(a, n)
        local boxes = { box(a.x, a.y, a.w, a.h) }
        local margin = 20
        local thumbW = a.w * 0.25
        local thumbH = math.min(a.h * 0.25, (a.h - margin) / math.max(1, n - 1) - margin)
        for i = 2, n do
            local k = i - 2
            boxes[i] = box(a.x + a.w - thumbW - margin, a.y + a.h - (k + 1) * (thumbH + margin), thumbW, thumbH)
        end
        return boxes
    end,
    spread = function(a, n)
        local cols = math.ceil(math.sqrt(n))
        local rows = math.ceil(n / cols)
        local cellW, cellH = a.w / cols, a.h / rows
        local boxes = {}
        for i = 1, n do
            local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
            boxes[i] = box(a.x + col * cellW + cellW * 0.075, a.y + row * cellH + cellH * 0.075, cellW * 0.85, cellH * 0.85)
        end
        return boxes
    end,
}

local function layoutFloat(selector, name, activeAddress)
    local workspace = hl.get_workspace(selector)
    local arrange = floatArrangements[name]
    if not workspace or not workspace.monitor or not arrange then return end
    local windows, activeWindow = {}, nil
    for _, window in ipairs(hl.get_workspace_windows(workspace)) do
        if not window.pinned and window.fullscreen == 0 and window.class ~= "alacritty-help" then
            if window.address == activeAddress then
                activeWindow = window
            else
                table.insert(windows, window)
            end
        end
    end
    if activeWindow then table.insert(windows, name == "pip" and 1 or #windows + 1, activeWindow) end
    local boxes = arrange(floatArea(workspace), #windows)
    for i, window in ipairs(windows) do
        local selectorArg = "address:" .. window.address
        if not window.floating then
            hl.dispatch(hl.dsp.window.float({ action = "enable", window = selectorArg }))
            hl.dispatch(hl.dsp.window.tag({ tag = "+" .. floatTag, window = selectorArg }))
        end
        local b = boxes[i]
        hl.dispatch(hl.dsp.window.resize({ x = math.floor(b.w), y = math.floor(b.h), window = selectorArg }))
        hl.dispatch(hl.dsp.window.move({ x = math.floor(b.x), y = math.floor(b.y), window = selectorArg }))
        hl.dispatch(hl.dsp.window.bring_to_top({ window = selectorArg }))
    end
end

local function layoutUnfloat(selector)
    local workspace = hl.get_workspace(selector)
    if not workspace then return end
    for _, window in ipairs(hl.get_workspace_windows(workspace)) do
        if hasFloatTag(window) then
            local selectorArg = "address:" .. window.address
            hl.dispatch(hl.dsp.window.tag({ tag = "-" .. floatTag, window = selectorArg }))
            hl.dispatch(hl.dsp.window.float({ action = "disable", window = selectorArg }))
        end
    end
end

local function nudgeFloating(window, direction)
    local area = floatArea(window.workspace)
    local x, y = window.at.x or window.at[1], window.at.y or window.at[2]
    local w, h = window.size.x or window.size[1], window.size.y or window.size[2]
    local stepX, stepY = area.w * 0.05, area.h * 0.05
    if direction == "l" then
        x = x - stepX
    elseif direction == "r" then
        x = x + stepX
    elseif direction == "u" then
        y = y - stepY
    else
        y = y + stepY
    end
    x = math.max(area.x, math.min(x, area.x + area.w - w))
    y = math.max(area.y, math.min(y, area.y + area.h - h))
    hl.dispatch(hl.dsp.window.move({ x = math.floor(x), y = math.floor(y), window = "address:" .. window.address }))
end

local function resizeFloating(window, stepsX, stepsY)
    local area = floatArea(window.workspace)
    local x, y = window.at.x or window.at[1], window.at.y or window.at[2]
    local w, h = window.size.x or window.size[1], window.size.y or window.size[2]
    local centerX, centerY = x + w / 2, y + h / 2
    w = math.max(area.w * 0.1, math.min(w + stepsX * area.w * 0.05, area.w))
    h = math.max(area.h * 0.1, math.min(h + stepsY * area.h * 0.05, area.h))
    x = math.max(area.x, math.min(centerX - w / 2, area.x + area.w - w))
    y = math.max(area.y, math.min(centerY - h / 2, area.y + area.h - h))
    local selector = "address:" .. window.address
    hl.dispatch(hl.dsp.window.resize({ x = math.floor(w), y = math.floor(h), window = selector }))
    hl.dispatch(hl.dsp.window.move({ x = math.floor(x), y = math.floor(y), window = selector }))
end

local function setRule(selector, name)
    local rule = { workspace = selector, layout = name }
    if name:sub(1, 7) == "master-" then
        rule.layout, rule.layout_opts = "master", { orientation = name:sub(8) }
    elseif luaLayouts[name] then
        rule.layout = "lua:" .. name
    end
    hl.workspace_rule(rule)
end

local function apply(selector, name, activeAddress)
    if name:sub(1, 6) == "float-" then
        layoutFloat(selector, name:sub(7), activeAddress)
        return
    end
    layoutUnfloat(selector)
    local s = entry(selector)
    if s.layout ~= name then s.previous = s.layout end
    s.layout = name
    save()
    local workspace = hl.get_workspace(selector)
    -- master only re-reads layout_opts when the layout name changes, and not within the same tick.
    if name:sub(1, 7) == "master-" and workspace and workspace.tiled_layout == "master" then
        hl.workspace_rule({ workspace = selector, layout = "dwindle" })
        hl.timer(function() setRule(selector, name) end, { timeout = 1, type = "oneshot" })
    else
        setRule(selector, name)
    end
end

local function current(selector)
    return state[selector] and state[selector].layout
end

local function previous(selector)
    return state[selector] and state[selector].previous
end

for key, s in pairs(state) do
    if s.layout then setRule(key, s.layout) end
end

return {
    apply = apply,
    current = current,
    previous = previous,
    workspaceKey = workspaceKey,
    nudgeFloating = nudgeFloating,
    resizeFloating = resizeFloating,
}
