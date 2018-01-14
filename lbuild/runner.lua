local ffi = require("ffi")
local lbuild_util = ffi.load("liblbuild_util.so")
local promise = require("lbuild.promise")

ffi.cdef[[
typedef int32_t pid_t;
pid_t lbuild_util_fexec(const char *argv[]);
unsigned int sleep(unsigned int seconds);
struct wpid_result {
    pid_t pid;
    int exitcode;
};
struct wpid_result wpid();
]]

local runner = {
    pt = {},
    queue = {},
    n = 0,
    maxn = 1,
}

local function ex(r, op)
    --print command
    print(table.concat(op.argv, " "))
    --run thing
    local argv = ffi.new("const char*[?]", #op.argv + 1, op.argv)
    argv[#op.argv] = nil
    local pid = lbuild_util.lbuild_util_fexec(argv)
    --handle fork failure
    if pid == -1 then
        op.fail("failed to fork: " .. ffi.errno())
        return
    end
    --update info
    op.pid = pid
    --add to lookup table
    r.pt[pid] = op
    r.n = r.n + 1
    return pid
end

--waitpid wrapper
local function wpid()
    local res = lbuild_util.wpid()
    return res.pid, res.exitcode
end

function runner:run(...)
    local argv = {...}
    local q = self.queue
    return promise(function(success, failure)
        if #argv == 0 then
            failure("No command")
            return
        end
        --create op
        local op = {
            argv = argv,
            finish = success,
            fail = failure,
        }
        -- not actually a queue - just stick it anywhere
        q[#q + 1] = op
    end)
end

function runner:upd()
    while self.n < self.maxn and #self.queue > 0 do
        ex(self, self.queue[#self.queue])
        self.queue[#self.queue] = nil
    end
end

function runner:wait()
    self:upd()
    if self.n > 0 then
        local pid, code = wpid()
        local op = self.pt[pid]
        if code == 0 then
            op.finish()
        else
            op.fail(code)
        end
        self.pt[pid] = nil
        op.pid = nil
    else
        error("Nothing running")
    end
end

function runner:setmaxn(n)
    self.maxn = n
    self:upd()
end

return runner
