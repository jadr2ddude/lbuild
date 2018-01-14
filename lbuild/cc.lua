--util for compiling c/c++
--work in progress

local runner = require("lbuild.runner")
local path = require("lbuild.path")
--local os lib
local os = os

--the library table
local cc = {}

--find cc to use
cc.CC = (os.getenv("CC") or ""):gmatch("^[ \n]+")
--find cxx to use
cc.CXX = (os.getenv("CXX") or ""):gmatch("^[ \n]+")
--load CFLAGS
cc.CFLAGS = (os.getenv("CFLAGS") or ""):gmatch("^[ \n]+")
--load CXXFLAGS
cc.CXXFLAGS = (os.getenv("CXXFLAGS") or ""):gmatch("^[ \n]+")

--compiling a file with the -c option
--file, output file, extra args
function cc:ccc(file, outf, ...)
    if outf == nil then
        outf = path:stripext(file) .. ".o"
    end
    return runner:run(self.CC, "-c", table:unpack(self.CFLAGS), ..., "-o", outf)
end
function cc:cxxc(file, outf, ...)
    if outf == nil then
        outf = path:stripext(file) .. ".o"
    end
    return runner:run(self.CXX, "-c", table:unpack(self.CXXFLAGS), ..., "-o", outf)
end
--link objects together (mid-stage)
--syntax: output path, extra args (as a table), list of input objects (vararg)
function cc:partialld(outf, args, ...)
    local inputs = {...}
    return runner:run(self.CC, "-c", table:unpack(self.CFLAGS), ..., "-o", outf)
end
--link a finished output
--inputs: input file (multiple inputs possible as table), options table, output
--options:
    --type: "executable", "shared" (default: executable)
    --static: true, false (default: false)
    --extraargs: string array (default: {})
function cc:ld(input, output, options)
    --select default options if missing
    options = options or {}
    options.type = options.type or "executable"
    options.static = options.static or false
    options.extraargs = options.extraargs or {}
    if options.type == "shared" then
        output = output or path:stripext(file) .. ".so"
    else
        output = output or path:stripext(file) .. ".o"
    end
    --check validity
    if options.type ~= "executable" and options.type ~= "shared" then
        error("bad cc type")
    end
    --check types
    if type(static) ~= "boolean" then
        error("static is not boolean")
    end
    if type(extraargs) ~= "table" then
        error("extraargs is not table")
    end
    --generate args
    local args = {}
    if options.type == "shared" then
        args[#args + 1] = "-shared"
    end
    if options.static then
        args[#args + 1] = "-static"
    end
    --run thing
    return runner:run(self.CC, table:unpack(args), table:unpack(self.CFLAGS), table:unpack(options.extraargs), ..., "-o", output)
end

return cc
