local path = require("lbuild.path")
local promise = require("lbuild.promise")
local runner = require("lbuild.runner")
local ffi = require("ffi")

ffi.cdef[[
int lbuild_util_isNewer(const char *a, const char *b);
char *strerror(int errnum);
bool exists(const char path[]);
]]

local lbuild_util = ffi.load("liblbuild_util.so")

local ruletbl = {}
local ruletable = ruletbl
ruletable.gen = {}
ruletable.rules = {}

--add a rule
--rule: table
    --rule.deps: a list or a function which returns a promise to a list
    --rule.run: a function which returns a promise
function ruletbl:add(rule)
    self.rules[rule.name] = rule
end

--add a rule which executes a command
--name is the name of the rule
--deps are the dependencies of the command
--cmd is the command to run
    --can be a table (argv) or a string
    --if a string, is translated to sh -c cmd
function ruletbl:addcmd(name, deps, cmd)
    local rule = {name = name}
    function rule:deps()
        return deps
    end
    if type(cmd) == "string" then
        cmd = {"sh", "-c", cmd}
    end
    function rule:run()
        return runner:run(unpack(cmd))
    end
    self:add(rule)
end

--add a rule generator
--genfunc is a func which takes one argument (a name) and returns a rule
--if the name does not match the generator pattern, genfunc should return nil
--unmatched names will be passed to the next generator
function ruletbl:addgenerator(genfunc)
    self.gen[#self.gen + 1] = genfunc
end

--returns whether file a is newer than b
function ruletbl:cmptime(a, b)
    local res = lbuild_util.lbuild_util_isNewer(a, b)
    if res ~= 0 then
        return true
    else
        return false
    end
end

--run a dependency (as a promise)
--value of promise is a boolean indicating whether the dep is newer or not
function ruletbl:rundep(r, dep)
    local rt = self
    return promise(function(success, failure)
        rt:run(dep):prom(function()
            success(rt:cmptime(dep, r))
        end, failure)
    end)
end

--run a rule (returns a promise)
function ruletbl:run(name)
    local rt = self
    --get rule
    local rule = self.rules[name]
    if rule == nil then --rule not found - try to generate it
        local n = #self.gen
        while rule == nil and n ~= 0 do
            rule = self.gen[n](name)
            n = n - 1
        end
        if rule == nil then --it wasn't found and could not be generated
            error("Rule " .. name .. " does not exist")
        end
        --add new rule to lookup table
        self.rules[name] = rule
    end
    return promise(function(success)
        if rule.state ~= nil then
            --if rule is already running (or done) dont start it again
            if rule.state == "done" then
                success()
            else
                rule.cb[#rule.cb + 1] = success
            end
        else                    --otherwise start it
            --get dependencies
            rule.state = "deplookup"
            rule.cb = {success}
            local depcb = function(deps)
                rule.state = "deps"
                rule.deplst = deps
                local runcb = function()
                    rule.state = "done"
                    for _, cb in ipairs(rule.cb) do
                        cb()
                    end
                end
                local n = #deps + 1
                local ischng = false
                local startcb = function(chng)
                    if not chng then
                        runcb()
                    else
                        rule:run():prom(runcb)
                    end
                end
                local depfcb = function(chng)
                    n = n - 1
                    ischng = ischng or chng
                    if n == 0 then
                        startcb(ischng)
                    end
                end
                for _, dep in ipairs(deps) do
                    local a = dep
                    rt:run(dep):prom(function()
                        local isnew = rt:cmptime(a, name)
                        depfcb(isnew)
                    end)
                end
                depfcb(#deps == 0)
            end
            local dps = rule:deps()
            if dps == nil then
                depcb({})
            elseif dps.prom ~= nil then
                dps:prom(depcb)
            else
                depcb(dps)
            end
        end
    end)
end

--add generator for rules for files that already exist
ruletable:addgenerator(function(name)
    if lbuild_util.exists(name) then
        local rule = {}
        function rule:deps()
            return nil
        end
        function rule:run()
            return promise(function(s, f)
                s()
            end)
        end
        return rule
    end
    return nil
end)

return ruletable
