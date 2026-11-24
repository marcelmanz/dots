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

hl.layout.register("columns", {
    recalculate = function(ctx)
        stack(ctx.targets, 1, ctx.area, false)
    end,
})

hl.layout.register("rows", {
    recalculate = function(ctx)
        stack(ctx.targets, 1, ctx.area, true)
    end,
})

hl.layout.register("grid", {
    recalculate = function(ctx)
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
    end,
})

hl.layout.register("focus", {
    recalculate = function(ctx)
        local n = #ctx.targets
        if n == 0 then return end
        local a = ctx.area
        if n == 1 then
            ctx.targets[1]:place(a)
            return
        end
        local mainWidth = a.w * 0.7
        ctx.targets[1]:place(box(a.x, a.y, mainWidth, a.h))
        stack(ctx.targets, 2, box(a.x + mainWidth, a.y, a.w - mainWidth, a.h), true)
    end,
})
