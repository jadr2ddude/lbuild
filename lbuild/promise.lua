local p = {}

p.__index = p

function p:prom(success, fail)
    if fail == nil then
        fail = error
    end
    self.f(success, fail)
end

local function promise(func)
    return setmetatable({f = func}, p)
end

return promise
