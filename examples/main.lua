local skynet = require "skynet"
local sprotoloader = require "sprotoloader"

local max_client = 64


--服务的入口，加载lua服务的时候先运行这里的代码
--调用skynet.h中的skynet_callback设置回调函数
skynet.start(function()
	skynet.error("Server start")

	--uniqueservice(name, ...) 启动一个唯一服务，如果服务该服务
	--已经启动，则返回已启动的服务地址。
	skynet.uniqueservice("protoloader")


	--/lualib/skynet.lua 中判断是以守护进程的方式进行
	if not skynet.getenv "daemon" then

		--用于启动一个lua写的服务，省略名字
		--调用了skynet.call()（用于给skynet框架发送消息，等待框架调度）,然后skynet.call()调用luaclib-src/lua_skynet.c
		--里面的send()，最终调用Skynet的框架skynet_send()压入队列

		--用于输出
		local console = skynet.newservice("console")
	end

	--用于debug输出
	skynet.newservice("debug_console",8000)

	--用于管理Key–Value数据
	skynet.newservice("simpledb")

	--启动watchdog.lua服务
	--watchdog用于监视socket端口，等待数据
	local watchdog = skynet.newservice("watchdog")

	--给框架发送一条消息，
	skynet.call(watchdog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})

	--打印消息
	skynet.error("Watchdog listen on", 8888)

	--移除服务
	skynet.exit()
end)
