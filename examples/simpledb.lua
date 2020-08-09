local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register
local db = {}

local command = {}



function command.GET(key)
	return db[key]
end

function command.SET(key, value)
	local last = db[key]
	db[key] = value
	return last
end



skynet.start(function()

	--dispatch(type, func) 为 type 类型的消息设定一个处理函数
	skynet.dispatch("lua", function(session, address, cmd, ...)
		cmd = cmd:upper()
		if cmd == "PING" then
			assert(session == 0)
			local str = (...)
			if #str > 20 then
				str = str:sub(1,20) .. "...(" .. #str .. ")"
			end
			--skynet.address 
			--1 number %08x输出
			--2 address 字符串输出
			skynet.error(string.format("%s ping %s", skynet.address(address), str))
			return
		end
		local f = command[cmd]

		--function skynet.ret(msg, sz)
			--msg = msg or ""
			--return coroutine_yield("RETURN", msg, sz)
		--end

		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)

	--注册名字
	skynet.register "SIMPLEDB"
end)
