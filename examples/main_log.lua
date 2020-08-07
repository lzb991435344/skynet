local skynet = require "skynet"
local harbor = require "skynet.harbor"
require "skynet.manager"	-- import skynet.monitor

local function monitor_master()
	--(1)harbor.link(id) 用来监控一个 slave 是否断开。如果 harbor id 对应的 
	--slave 正常，这个 api 将阻塞。当 slave 断开时，会立刻返回。

	
    --(2)harbor.linkmaster() 用来在 slave 上监控和 master 的连接是否正常。这个 
    --api 多用于异常时的安全退出（因为当 slave 和 master 断开后，没有手段可以恢复）。

	harbor.linkmaster()
	print("master is down")
	skynet.exit()
end

skynet.start(function()
	print("Log server start")

	--用于监视服务，看它是否关闭
	skynet.monitor "simplemonitor"

	--启动全局的log服务
	local log = skynet.newservice("globallog")

	--fork(func, ...) 启动一个新的任务去执行函数 func
	skynet.fork(monitor_master)
end)

