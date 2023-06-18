--[[
* MIT License
* 
* Copyright (c) 2023 Tsukuyomiii, Thorny
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

addon.name      = 'Easy Get Fishers';
addon.author    = 'Tsukuyomiii, Thorny';
addon.version   = '1.0';
addon.desc      = 'Easy way for GMs to !goto current fishers.';

require('common');
local imgui = require('imgui');
local trackTimeout = 0;
local results = T{};
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
            results:append(T{
                Zone = string.sub(e.message, zoneEnd + 1, nameMatch - 2);
                Name = string.sub(e.message, nameEnd + 1, jobMatch - 2);
                Level = string.sub(e.message, jobEnd + 1, skillMatch - 2);
                Skill = string.sub(e.message, skillEnd + 1);
            });
            trackTimeout = os.clock() + 3;
        end
    end
end);

local function RenderInterface()
    imgui.SetNextWindowSize({ 800, 220, });
    imgui.SetNextWindowSizeConstraints({ 800, 220, }, { FLT_MAX, FLT_MAX, });
    if (imgui.Begin('Current Fishers', interface.IsOpen, ImGuiWindowFlags_NoResize)) then
        imgui.BeginGroup();
        imgui.BeginChild('leftpane', { 770, 180 }, true);
        for i = 1,#results do
            local result = results[i];
            local outputString = string.format('Name:%s Zone:%s Level:%s Skill:%s', result.Name, result.Zone, result.Level, result.Skill);
            if (imgui.Selectable(outputString, interface.SelectedIndex == i)) then
                interface.SelectedIndex = i;
            end

            if (imgui.IsItemHovered() and imgui.IsMouseDoubleClicked(0)) then
                local cmd = string.format('/unity !goto %s', result.Name);
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
        interface.IsOpen[1] = true;
    end

    if (interface.IsOpen[1] == true) then
        RenderInterface();
    end
end);
