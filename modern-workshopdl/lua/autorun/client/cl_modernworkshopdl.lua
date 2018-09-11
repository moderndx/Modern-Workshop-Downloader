local m_workshop_dl_list = {}
local m_downloaded_list = {}
local m_current_download_info = {}
local m_request_launch = false

local function strip_website(m_link)
  if (!m_link) then return false end
  if (tonumber(m_link)) then return m_link end
  m_link = string.Replace(m_link, "http://", "")
  m_link = string.Replace(m_link, "https://", "")
  m_link = string.Replace(m_link, "www.", "")
  m_link = string.Replace(m_link, "steamcommunity.com", "")
  m_link = string.Replace(m_link, "/sharedfiles/filedetails/?id=", "")
  m_link = string.Replace(m_link, "&searchtext=", "")
  m_link = string.Replace(m_link, "https://steamcommunity.com/workshop/filedetails/?id=", "")
  return m_link
end

local function check_if_file_exists(m_workshop_fileid)
  return file.Exists("cache/workshop/"..m_workshop_fileid..".cache", "GAME")
end

local function handle_workshop_item(m_workshop_tbl, m_workshop_index)
  local file_id = 0
  if (m_workshop_tbl[m_workshop_index] && tonumber(m_workshop_tbl[m_workshop_index])) then
    if (!table.HasValue(m_downloaded_list, m_workshop_tbl[m_workshop_index])) then
      steamworks.FileInfo( m_workshop_tbl[m_workshop_index], function( m_result )
        if (!m_result || !istable(m_result)) then return end
        m_current_download_info = m_result
        local m_exists = check_if_file_exists(m_result.fileid)
        if(!m_exists) then notification.AddProgress( "m_file_download"..m_result.fileid, "Downloading "..m_result.title) end
        file_id = m_result.fileid
        steamworks.Download( m_result.fileid, true, function( m_name )
          local succ, err = pcall( function() game.MountGMA( m_name ) end)
          table.insert(m_downloaded_list, m_workshop_tbl[m_workshop_index])
        end)
      end)
    end
  end
  m_workshop_index = m_workshop_index + 1
  timer.Simple(1.5, function() notification.Kill( "m_file_download"..file_id ) file_id = 0 if (!m_workshop_tbl[m_workshop_index] || !tonumber(m_workshop_tbl[m_workshop_index])) then return end handle_workshop_item(m_workshop_tbl, m_workshop_index) end)
end

local function handle_workshop_table(m_workshop_tbl)
  for k, v in pairs(m_workshop_tbl) do
    if (!v || !tonumber(v)) then continue end
    if (table.HasValue(m_downloaded_list, v)) then continue end
    steamworks.FileInfo( v, function( m_result )
      if (!m_result || !istable(m_result)) then return end
      m_current_download_info = m_result
      notification.AddProgress( "m_file_download"..m_result.fileid, "Downloading "..m_result.title)
      steamworks.Download( m_result.fileid, true, function( m_name )
        local succ, err = pcall( function() game.MountGMA( m_name ) end)
        notification.Kill( "m_file_download"..m_result.fileid )
        --if succ then notification.AddLegacy( m_result.title.." finished downloading", NOTIFY_GENERIC, 2 ) else notification.AddLegacy( "Couldn't mount "..v, NOTIFY_GENERIC, 2 ) end
        table.insert(m_downloaded_list, v)
      end)
    end)
  end
  m_current_download_info = {}
end

net.Receive("modern_workshop_network_list", function()
  local m_list_tbl = net.ReadTable()
  if (!m_list_tbl) then return end
  m_workshop_dl_list = m_list_tbl
  timer.Simple(2, function() handle_workshop_item(m_workshop_dl_list, 0) end)
end)

local function open_workshop_menu()
  local Frame = vgui.Create( "DFrame" )
  Frame:SetTitle( "Workshop Admin Panel" )
  Frame:SetSize( 300, 200 )
  Frame:Center()
  Frame:MakePopup()
  Frame.Paint = function( self, w, h )
  	draw.RoundedBox( 0, 0, 0, w, h, Color( 25, 25, 25, 150 ) )
  end

  local TextEntry = vgui.Create( "DTextEntry", Frame )
  TextEntry:SetPos( 50, 120 )
  TextEntry:SetSize( 200, 30 )
  TextEntry:SetText( "Workshop ID" )

  local AppList = vgui.Create( "DListView", Frame )
  AppList:Dock( TOP )
  AppList:SetMultiSelect( false )
  AppList:SetPos(50, 100)
  AppList:SetSize(200, 80)
  AppList:AddColumn( "Name" )
  AppList:AddColumn( "ID" )
  AppList:Clear()
  AppList.OnRowSelected = function( lst, index, pnl )
    TextEntry:SetValue(pnl:GetColumnText( 2 ))
  end

  for k, v in pairs(m_workshop_dl_list) do
    if (!v || !tonumber(v)) then continue end
    steamworks.FileInfo( v, function( m_result )
      if (!m_result) then AppList:AddLine( "unknown", v ) return end
      AppList:AddLine( m_result.title, v )
    end)
  end

  local Button = vgui.Create( "DButton", Frame )
  Button:SetText( "Add" )
  Button:SetTextColor( Color( 255, 255, 255 ) )
  Button:SetPos( 45, 75 + 80 )
  Button:SetSize( 100, 30 )
  Button.Paint = function( self, w, h )
  	draw.RoundedBox( 0, 0, 0, w, h, Color( 41, 128, 185, 250 ) )
  end

  Button.DoClick = function()
    local m_sim = strip_website(TextEntry:GetValue())
    if (!m_sim || !tonumber(m_sim)) then return end
    steamworks.FileInfo( m_sim, function( m_result )
      if (!m_result) then return end

      net.Start("modern_workshop_send_id")
      net.WriteString(m_sim)
      net.WriteBool(true)
      net.SendToServer()

      for k, line in pairs( AppList:GetLines() ) do
        if (line:GetValue( 2 ) == m_sim) then
          notification.AddLegacy( "That addon already exists", NOTIFY_ERROR, 2 )
          return
        end
      end

      AppList:AddLine( m_result.title, m_sim )
    end)
  end

  local Button = vgui.Create( "DButton", Frame )
  Button:SetText( "Remove" )
  Button:SetTextColor( Color( 255, 255, 255 ) )
  Button:SetPos( 155, 75 + 80 )
  Button:SetSize( 100, 30 )
  Button.Paint = function( self, w, h )
    draw.RoundedBox( 0, 0, 0, w, h, Color( 41, 128, 185, 250 ) )
  end
  Button.DoClick = function()
    net.Start("modern_workshop_send_id")
    net.WriteString(strip_website(TextEntry:GetValue()))
    net.WriteBool(false)
    net.SendToServer()

    local m_sim = strip_website(TextEntry:GetValue())
    if (!m_sim || !tonumber(m_sim)) then return end
    for k, line in pairs( AppList:GetLines() ) do
      if (line:GetValue( 2 ) == m_sim) then
        AppList:RemoveLine(k)
      end
    end
  end
end

local function loaded_check()
  timer.Simple(5, function()
    net.Start("modern_loaded_in_request")
    net.SendToServer()
  end)
  hook.Remove("HUDPaint", "modern_load_check")
end

concommand.Add( "open_workshop_admin", function(ply)
  if (ply:IsAdmin() || ply:IsSuperAdmin()) then
    open_workshop_menu()
  end
end)

hook.Add("HUDPaint", "modern_load_check", loaded_check)
