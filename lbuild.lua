#!/bin/luajit

local ruletable = require("lbuild.ruletable")
local runner = require("lbuild.runner")

local f = assert(io.open("build.lua", "rb"))
loadstring([[
local runner = require("lbuild.runner")
local ruletable = require("lbuild.ruletable")
local add = function(...)
    ruletable:add(...)
end
local addcmd = function(...)
    ruletable:addcmd(...)
end
]] .. f:read("*all"))()

local targs = {...}

local n = #targs

for _, r in ipairs(targs) do
    ruletable:run(r):prom(function()
        print("Done building " .. r)
        n = n - 1
        if n == 0 then
            os.exit()
        end
    end)
end

if n == 0 then
    print("Nothing to do")
end

while true do runner:wait() end
