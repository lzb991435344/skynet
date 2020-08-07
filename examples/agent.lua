local skynet = require "skynet"
local netpack = require "skynet.netpack"
local socket = require "skynet.socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"

local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd


--set 和 get
--向skynet上发送消息
function REQUEST:get()
	print("get", self.what)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQUEST:set()
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end




function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end


--watchdog 退出监听
function REQUEST:quit()
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end



local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)

	--有回应消息
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	--往socket fd 上写数据
	socket.write(client_fd, package)
end


--Agent的核心就是注册了协议，并根据协议把数据发送给simpledb服务去处理
skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)

		--处理一条消息
		return host:dispatch(msg, sz)
	end,

	--dispatch 有两种可能的返回


	--request 远程请求
	--1 REQUEST 请求包
	--2 消息类型名
	--3 消息内容，通常是一个table

	--无session则不需要进行回复消息	
	--4 生成回应包的函数（有session）

	--response 回应
	--1 response
	--2 session
	--3 消息内容
	dispatch = function (_, _, type, ...)
		--请求消息
		if type == "REQUEST" then
			--pcall(func, ...) 执行一个函数，捕获可能抛出的异常，
			--并保证在此之前运行由 init 注册的初始化过程。
			local ok, result  = pcall(request, ...)

			--函数返回成功
			if ok then
				--result不为空，直接将字段打包发出
				if result then
					send_package(result)
				end
			else
				skynet.error(result)
			end
		else --回应消息
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}


--watchdog.lua中发过来的conf
--skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog

	--slot1保存c2s的协议组
	--slot2保存s2c的协议组
	--在每个vm中，都可以通过 sprotoloader.load 把协议加载到 vm 中
	--PS：这套 api 并非线程安全。所以必须自行保证在初始化完毕后再做 load 操作。
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"



	--local sender = host:attach(sp)
	--attach 可以构造一个发送函数，用来将对外请求打包编码成可以被 dispatch 正确解码
	--的数据包。

	--sender 函数接受三个参数（name, args, session）。name 是消息的字符
	--串名、args 是一张保存用消息内容的 table ，而 session 是你提供的唯一识别号，用
	--于让对方正确的回应。 当你的协议不规定需要回应时，session 可以不给出。同样，args 
	--也可以为空。



	--sprotoloader.load(2)  指向外发出的消息协议定义。
	send_request = host:attach(sprotoloader.load(2))

	--新建一个服务去做匿名函数执行的任务
	--每隔5s发一条消息
	skynet.fork(function()
		while true do
			send_package(send_request "heartbeat")
			skynet.sleep(500)
		end
	end)

	client_fd = fd

	--gate管理socket,forward 转发消息
	--发消息给skynet,压入队列待调度
	skynet.call(gate, "lua", "forward", fd)
end




function CMD.disconnect()
	-- todo: do something before exit
	--通过skynet.send() 发送消移除服务
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
