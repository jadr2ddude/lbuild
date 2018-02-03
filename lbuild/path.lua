--work in progress

local path = {}

function path:stripext(p)
    return string.gsub(p, "%.[^/]+$", "")
end

function path:getext(p)
    return string.match(p, "%.[^/]+$")
end

function path:filename(p)
    return string.match(p, "[^/]+$")
end

function path:basename(p)
    return path:stripext(path:filename(p))
end

function path:dirname(p)
    if string.match(p, "/") then
        local res = string.gsub(p, "/[^/]+$", "")
        return res
    end
end

return path
