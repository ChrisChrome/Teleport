zones = {}
aliases = {}
tpq = {}
ui_id = 0
function onCreate(is_world_create)
	ui_id = server.getMapID()
	zones = server.getZones("type=teleport")
	for i,e in ipairs(zones) do
		local x,y,z = matrix.position(e.transform)
		server.addMapLabel(-1, ui_id, 11, e.name, x, z)
		for ti=2,#e.tags,1 do
			aliases[e.tags[ti]] = i
		end
	end
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
	for i,e in ipairs(zones) do
		local x,y,z = matrix.position(e.transform)
		server.addMapLabel(peer_id, ui_id, 11, e.name, x, z)
	end
end

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, command, ...)
	local args = {...}
	command = string.lower(command)
	if (command == "?tp") then
		if args[1] == nil then
			server.announce("[TP]", "Destination required", user_peer_id)
			return
		end
		local dest = aliases[args[1]]
		if dest == nil then
			server.announce("[TP]", "Invalid destination", user_peer_id)
			return
		end
		
		server.setPlayerPos(user_peer_id, zones[dest].transform)
		tpq[user_peer_id] = {time=server.getTimeMillisec(), dest=zones[dest].transform}
	elseif (command == "?tpp" and is_admin) then
		if not args[1] then
			server.announce("[TP]", "Invalid destination", user_peer_id)
			return
		end
		if (args[2]) then -- We're gonna do a to/from
			_,exists1 = server.getPlayerCharacterID(args[1])
			_,exists2 = server.getPlayerCharacterID(args[2])
			if not (exists1 and exists2) then
				server.announce("[TP]", "Invalid destination", user_peer_id)
				return
			end
			to = server.getPlayerPos(tonumber(args[2]))
			server.setPlayerPos(tonumber(args[1]), to)
			server.announce("[TP]", "Trying to send " .. tostring(server.getPlayerName(args[1])) .. " to " .. server.getPlayerName(args[2]) .. "!", user_peer_id)
		else
			_,exists1 = server.getPlayerCharacterID(args[1])
			if not exists1 then
				server.announce("[TP]", "Invalid destination", user_peer_id)
				return
			end
			to = server.getPlayerPos(tonumber(args[1]))
			server.setPlayerPos(user_peer_id, to)
			server.announce("[TP]", "Tring to send you to " .. tostring(server.getPlayerName(args[1])) .. "!", user_peer_id)
		end
	end	
end


function onTick(ticks)
	ctime = server.getTimeMillisec()
	for pid, obj in pairs(tpq) do
		if ctime - obj.time >= 100 then
			server.setPlayerPos(pid, obj.dest)
			tpq[pid] = nil
		end
	end
end