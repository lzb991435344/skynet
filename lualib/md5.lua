----------------------------------------------------------------------------
-- Modify version from https://github.com/keplerproject/md5
----------------------------------------------------------------------------

local core = require "md5.core"

----------------------------------------------------------------------------
-- @param k String with original message.
-- @return String with the md5 hash value converted to hexadecimal digits

function core.sumhexa (k)
	k = core.sum(k)
	--[[
	string.gsub(mainString,findString,replaceString,num) 在字符串中替换。

	mainString 为要操作的字符串， findString 为被替换的字符，replaceString 要替换的字符，num 替换次数（可以忽略，则全部替换），如：
> string.gsub("aaaa","a","z",3);
zzza    3

	--]]
	return (string.gsub(k, ".", function (c)
		   return string.format("%02x", string.byte(c))
		 end))
end

local function get_ipad(c)
	return string.char(c:byte() ~ 0x36)
end

local function get_opad(c)
	return string.char(c:byte() ~ 0x5c)
end

function core.hmacmd5(data,key)
	if #key>64 then
		key=core.sum(key)
		key=key:sub(1,16)
	end
	local ipad_s=key:gsub(".", get_ipad)..string.rep("6",64-#key)
	local opad_s=key:gsub(".", get_opad)..string.rep("\\",64-#key)
	local istr=core.sum(ipad_s..data)
	local ostr=core.sumhexa(opad_s..istr)
	return ostr
end

return core
