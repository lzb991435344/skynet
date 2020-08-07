local skynet = require "skynet"

local CMD = {}
local SOCKET = {}
local gate
local agent = {}



function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)

	--新建agent服务并启动
	agent[fd] = skynet.newservice("agent")

	--gate管理socket,gate服务启动后立即开启监听
	--可以通过 lua 协议向它发送一个 open 指令，附带一个启动参数表

	--向skynet框架发送一条消息
	--调用agent里的CMD.start(conf)
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
end



local function close_agent(fd)
	local a = agent[fd]
	--设置该socket为空
	agent[fd] = nil

	--不为空
	if a then
		--发消息 kick
		skynet.call(gate, "lua", "kick", fd)

		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end


--关闭agent服务
function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end


function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end


function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

--有消息来到
function SOCKET.data(fd, msg)
end




function CMD.start(conf)
	--gate服务开始监听，发open指令，带参数表
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end





skynet.start(function()

	--通过SOCKET[]来调用函数
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			--返回给来源服务
			--返回给请求者，单向的消息则session为0
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("gate")
end)
