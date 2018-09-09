util.AddNetworkString("modern_workshop_network_list")
util.AddNetworkString("modern_workshop_send_id")
util.AddNetworkString("modern_workshop_update_list")

local saved_workshop_list = {}

function file.append_file(filename, contents)
	data = file.Read(filename)
	if ( data ) then
		file.Write(filename, data .. tostring(contents))
	else
		file.Write(filename, tostring(contents))
	end
end

local function check_if_exists(id)
  local m_data = file.Read("modern_workshop_id_list.txt")
  return string.find(m_data, id)
end

local function add_to_workshop_list(id)
  if (!tonumber(id)) then return false end
  if (check_if_exists(id)) then return end
  file.append_file("modern_workshop_id_list.txt", id..";")
  return true
end

local function remove_from_workshop_list(id)
  if (!tonumber(id)) then return false end
  local m_data = file.Read("modern_workshop_id_list.txt")
  m_data = string.Replace( m_data, id..";", "" )
  file.Write("modern_workshop_id_list.txt", m_data)
  return true
end

local function update_local_workshop_list()
  local m_data = file.Read("modern_workshop_id_list.txt")
  if (!m_data) then return end
  saved_workshop_list = string.Explode(";", m_data)
end

local function grab_workshop_table()
  if (!saved_workshop_list) then update_local_workshop_list() end
  return saved_workshop_list
end

local function handle_player(ply)
  local m_saved_tbl = grab_workshop_table()
  if (!m_saved_tbl) then return end
  net.Start("modern_workshop_network_list")
  net.WriteTable(m_saved_tbl)
  net.Send(ply)
end

net.Receive("modern_workshop_send_id", function(len, ply)
  local m_networked_id = net.ReadString()
  if (!tonumber(m_networked_id)) then return end
  if (ply:IsAdmin() || ply:IsSuperAdmin()) then
    if (net.ReadBool()) then add_to_workshop_list(m_networked_id)
    else remove_from_workshop_list(m_networked_id) end
    update_local_workshop_list()
  end
  local m_saved_tbl = grab_workshop_table()
  if (!m_saved_tbl) then return end
  net.Start("modern_workshop_network_list")
  net.WriteTable(m_saved_tbl)
  net.Broadcast()
end)

net.Receive("modern_workshop_update_list", function(len, ply)
  if (ply:IsAdmin() || ply:IsSuperAdmin()) then
    update_local_workshop_list()
  end
end)

update_local_workshop_list()

hook.Add("PlayerInitialSpawn", "modern_workshop_spawn", handle_player)
