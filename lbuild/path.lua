--work in progress

local path = {}

function path:stripext(p)
    return string.gsub(p, "%.[%a%.]+$", "")
end

function path:getext(p)
    return string.match(p, "%.[%a%.]+$")
end

function path:filename(p)
    return string.match(p, "[%a%.%-]+$")
end

function path:basename(p)
    return path:stripext(path:filename(p))
end

function path:dirname(p)
    if string.match(p, "/") then
        return string.gsub(p, "/[%a%.]+$", "")
    end
end

return path
