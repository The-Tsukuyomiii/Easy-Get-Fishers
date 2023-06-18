--[[
* MIT License
* 
* Copyright (c) 2023 Tsukuyomiii [https://github.com/The-Tsukuyomiii], Thorny 
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
]]--

addon.name      = 'EasyGetFishers';
addon.author    = 'Tsukuyomiii, Thorny';
addon.version   = '1.0.1';
addon.desc      = 'Easy way for GMs to !goto current fishers.';
addon.link	= '[https://github.com/The-Tsukuyomiii/Easy-Get-Fishers]';

require('common');
local imgui = require('imgui');
local trackTimeout = 0;
local results = T{};
local zoneData = T{};
local interface = {
    IsOpen = { false },
    SelectedIndex = 0,
};

ashita.events.register('command', 'HandleCommand', function (e)
    if (e.command == '!getfishers') then
        trackTimeout = os.clock() + 3;
        results = T{};
        if (interface.IsOpen[1] == true) then
            interface.IsOpen[1] = false;
        end
    end
end);

ashita.events.register('text_in', 'HandleText', function (e)
    local zoneMatch, zoneEnd = string.find(e.message, 'Zone: ');
    local nameMatch, nameEnd = string.find(e.message, '| Player Name: ');
    local jobMatch, jobEnd = string.find(e.message, '| Job Level: ');
    local skillMatch, skillEnd = string.find(e.message, '| Skill: ');

    if zoneMatch and nameMatch and jobMatch and skillMatch then
        if (os.clock() < trackTimeout) then
            local result = T{
                Zone = string.sub(e.message, zoneEnd + 1, nameMatch - 2),
                Name =  string.sub(e.message, nameEnd + 1, jobMatch - 2),
                Level = tonumber(string.sub(e.message, jobEnd + 1, skillMatch - 2)),
                Skill = tonumber(string.sub(e.message, skillEnd + 1)),
            };
            results:append(result);
            trackTimeout = os.clock() + 3;
        end
    end
end);

local function RenderInterface()
    if (imgui.Begin('Current Fishers', interface.IsOpen, ImGuiWindowFlags_AlwaysAutoResize)) then
        if imgui.BeginCombo('##ZoneList_ComboBox', zoneData[interface.SelectedZone].Display, ImGuiComboFlags_None) then
            for index,entry in ipairs(zoneData) do
                local isSelected = (interface.SelectedZone == index);
                if imgui.Selectable(entry.Display, isSelected) then
                    if (not isSelected) then
                        interface.SelectedZone = index;
                        interface.SelectedIndex = 0;
                    end
                end
            end
            imgui.EndCombo();
        end

        imgui.BeginGroup();
        imgui.BeginChild('leftpane', { 500, 180 }, true);
        local entries = zoneData[interface.SelectedZone].Entries;
        for i = 1,#entries do
            local entry = entries[i];
            local outputString = string.format('%-20s Lv:%-3u Skill:%-2u', entry.Name, entry.Level, entry.Skill);
            if (imgui.Selectable(outputString, interface.SelectedIndex == i)) then
                interface.SelectedIndex = i;
            end

            if (imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0)) then
                local cmd = string.format('/unity !goto %s', entry.Name);
                AshitaCore:GetChatManager():QueueCommand(1, cmd);
            end
        end
        imgui.EndChild();
        imgui.End();
    end
end


ashita.events.register('d3d_present', 'HandleRender', function ()
    if (trackTimeout ~= 0) and (os.clock() > trackTimeout) then
        trackTimeout = 0;

        if (#results == 0) then
            print('No results found.');
            return;
        end

        local resultsByZone = T{};
        for _,result in ipairs(results) do
            local zone = resultsByZone[result.Zone];
            if zone == nil then
                resultsByZone[result.Zone] = {
                Name = result.Zone,
                Count = 1,
                Entries = T { result },
                };
            else
                zone.Count = zone.Count + 1;
                zone.Entries:append(result);
            end
        end

        zoneData = T{};
        for _,zone in pairs(resultsByZone) do
            zone.Display = string.format('%s[%u]', zone.Name, zone.Count);
            zoneData:append(zone);
        end
        
        table.sort(zoneData, function(a,b)
            return a.Count > b.Count;
        end);

        for _,zone in ipairs(zoneData) do
            table.sort(zone.Entries, function(a,b)
                if (a.Level ~= b.Level) then
                    return (a.Level < b.Level);
                end
                if (a.Skill ~= b.Skill) then
                    return (a.Skill < b.Skill);
                end
                return (a.Name < b.Name);
            end);
        end

        interface.SelectedZone = 1;
        interface.IsOpen[1] = true;
    end

    if (interface.IsOpen[1] == true) then
        RenderInterface();
    end
end);
