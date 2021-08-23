-- ALittle Generate Lua And Do Not Edit This Line!
do
if _G.G2048 == nil then _G.G2048 = {} end
local G2048 = G2048
local Lua = Lua
local ALittle = ALittle
local ___rawset = rawset
local ___pairs = pairs
local ___ipairs = ipairs

ALittle.RegStruct(-1842382794, "G2048.ItemInfo", {
name = "G2048.ItemInfo", ns_name = "G2048", rl_name = "ItemInfo", hash_code = -1842382794,
name_list = {"item","row","col"},
type_list = {"ALittle.DisplayObject","int","int"},
option_map = {}
})

G2048.g_GConfig = nil
G2048.GCenter = Lua.Class(nil, "G2048.GCenter")

function G2048.GCenter:Ctor()
	___rawset(self, "_mean_total_score", 0)
	___rawset(self, "_mean_total_count", 0)
	___rawset(self, "_loop_group", {})
end

function G2048.GCenter:ClearAnti()
	for k, v in ___pairs(self._loop_group) do
		if v:IsCompleted() == false then
			v:SetCompleted()
		end
	end
	self._loop_group = {}
end

function G2048.GCenter:Setup()
	G2048.g_GConfig = ALittle.CreateConfigSystem(G2048.g_ModuleBasePath .. "/User.cfg")
	ALittle.Math_RandomSeed(ALittle.Time_GetCurTime())
	ALittle.System_SetThreadCount(1)
	self._main_layer = ALittle.DisplayLayout(G2048.g_Control)
	self._main_layer.width_type = 4
	self._main_layer.height_type = 4
	G2048.g_LayerGroup:AddChild(self._main_layer, nil)
	self._dialog_layer = ALittle.DisplayLayout(G2048.g_Control)
	self._dialog_layer.width_type = 4
	self._dialog_layer.height_type = 4
	G2048.g_LayerGroup:AddChild(self._dialog_layer, nil)
	G2048.g_Control:PrepareTexture({"item_2", "item_4", "item_8", "item_16", "item_32", "item_64", "item_128", "item_256", "item_512", "item_1024", "item_2048"}, nil)
	G2048.g_Control:CreateControl("main_scene", self, self._main_layer)
	if deeplearning ~= nil and deeplearning.DeeplearningDqnDnnModel ~= nil then
		local state_num = 16
		local action_num = 4
		self._dqn_model = deeplearning.DeeplearningDqnDnnModel(state_num, action_num, 100, 200)
		self._dqn_model_path = G2048.g_ModuleBasePath .. "/Other/g2048_" .. state_num .. "_" .. action_num .. ".model"
		self._dqn_model:Load(self._dqn_model_path)
		self._dqn_timer = A_LoopSystem:AddTimer(10, Lua.Bind(self.HandleDqnPlay, self), -1, 10)
	end
	self._mean_text.visible = self._dqn_model ~= nil
	self._mean_score_text.visible = self._dqn_model ~= nil
	if self._dqn_model ~= nil then
		self._max_score_text._user_data = 0
	else
		self._max_score_text._user_data = G2048.g_GConfig:GetConfig("max_score", 0)
	end
	self._max_score_text.text = self._max_score_text._user_data
	self:Restart()
end

function G2048.GCenter:ShowMainMenu(content, show_back)
	if self._main_menu == nil then
		self._main_menu = G2048.g_Control:CreateControl("main_menu", self, nil)
		self._dialog_layer:AddChild(self._main_menu, nil)
	end
	self._main_menu.visible = true
	self._menu_content.text = content
	self._menu_back.visible = show_back
end

function G2048.GCenter:Restart()
	if self._main_menu ~= nil then
		self._main_menu.visible = false
	end
	self._score_text.text = "0"
	self._score_text._user_data = 0
	self._data_map = {}
	self._data_map[1] = {}
	self._data_map[2] = {}
	self._data_map[3] = {}
	self._data_map[4] = {}
	self._loop_group = {}
	self._tile_container:RemoveAllChild()
	self:GenerateItem(0)
	self:GenerateItem(0)
	self._item_moved = false
	self._loop_delay = 0
	self._drag_quad:DelayFocus()
end

function G2048.GCenter:GenerateItem(delay_time)
	local list = {}
	local list_count = 0
	local i = 1
	while true do
		if not(i <= 4) then break end
		local j = 1
		while true do
			if not(j <= 4) then break end
			if self._data_map[i][j] == nil then
				local data = {}
				data[1] = i
				data[2] = j
				list_count = list_count + 1
				list[list_count] = data
			end
			j = j+(1)
		end
		i = i+(1)
	end
	if list_count == 0 then
		return false
	end
	local rand1 = ALittle.Math_RandomInt(1, 10)
	local number = 4
	if rand1 < 10 then
		number = 2
	end
	local rand2 = ALittle.Math_RandomInt(1, list_count)
	local row = list[rand2][1]
	local col = list[rand2][2]
	self:BornItem(number, row, col, delay_time, true)
	return true
end

function G2048.GCenter:CalcLeft()
	local i = 1
	while true do
		if not(i <= 4) then break end
		local list = {}
		local list_count = 0
		local j = 1
		while true do
			if not(j <= 4) then break end
			if self._data_map[i][j] ~= nil then
				local info = {}
				info.item = self._data_map[i][j]
				info.row = i
				info.col = j
				list_count = list_count + 1
				list[list_count] = info
			end
			j = j+(1)
		end
		if list_count == 1 then
			self:TransItem(list[1], i, 1)
		elseif list_count == 2 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], i, 1)
			else
				self:TransItem(list[1], i, 1)
				self:TransItem(list[2], i, 2)
			end
		elseif list_count == 3 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], i, 1)
				self:TransItem(list[3], i, 2)
			elseif list[2].item._user_data == list[3].item._user_data then
				self:TransItem(list[1], i, 1)
				self:CombineItems(list[2], list[3], i, 2)
			else
				self:TransItem(list[1], i, 1)
				self:TransItem(list[2], i, 2)
				self:TransItem(list[3], i, 3)
			end
		elseif list_count == 4 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], i, 1)
				if list[3].item._user_data == list[4].item._user_data then
					self:CombineItems(list[3], list[4], i, 2)
				else
					self:TransItem(list[3], i, 2)
					self:TransItem(list[4], i, 3)
				end
			elseif list[2].item._user_data == list[3].item._user_data then
				self:TransItem(list[1], i, 1)
				self:CombineItems(list[2], list[3], i, 2)
				self:TransItem(list[4], i, 3)
			elseif list[3].item._user_data == list[4].item._user_data then
				self:TransItem(list[1], i, 1)
				self:TransItem(list[2], i, 2)
				self:CombineItems(list[3], list[4], i, 3)
			end
		end
		i = i+(1)
	end
end

function G2048.GCenter:CalcRight()
	local i = 1
	while true do
		if not(i <= 4) then break end
		local list = {}
		local list_count = 0
		local j = 4
		while true do
			if not(j >= 1) then break end
			if self._data_map[i][j] ~= nil then
				local info = {}
				info.item = self._data_map[i][j]
				info.row = i
				info.col = j
				list_count = list_count + 1
				list[list_count] = info
			end
			j = j+(-1)
		end
		if list_count == 1 then
			self:TransItem(list[1], i, 5 - 1)
		elseif list_count == 2 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], i, 5 - 1)
			else
				self:TransItem(list[1], i, 5 - 1)
				self:TransItem(list[2], i, 5 - 2)
			end
		elseif list_count == 3 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], i, 5 - 1)
				self:TransItem(list[3], i, 5 - 2)
			elseif list[2].item._user_data == list[3].item._user_data then
				self:TransItem(list[1], i, 5 - 1)
				self:CombineItems(list[2], list[3], i, 5 - 2)
			else
				self:TransItem(list[1], i, 5 - 1)
				self:TransItem(list[2], i, 5 - 2)
				self:TransItem(list[3], i, 5 - 3)
			end
		elseif list_count == 4 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], i, 5 - 1)
				if list[3].item._user_data == list[4].item._user_data then
					self:CombineItems(list[3], list[4], i, 5 - 2)
				else
					self:TransItem(list[3], i, 5 - 2)
					self:TransItem(list[4], i, 5 - 3)
				end
			elseif list[2].item._user_data == list[3].item._user_data then
				self:TransItem(list[1], i, 5 - 1)
				self:CombineItems(list[2], list[3], i, 5 - 2)
				self:TransItem(list[4], i, 5 - 3)
			elseif list[3].item._user_data == list[4].item._user_data then
				self:TransItem(list[1], i, 5 - 1)
				self:TransItem(list[2], i, 5 - 2)
				self:CombineItems(list[3], list[4], i, 5 - 3)
			end
		end
		i = i+(1)
	end
end

function G2048.GCenter:CalcUp()
	local j = 1
	while true do
		if not(j <= 4) then break end
		local list = {}
		local list_count = 0
		local i = 1
		while true do
			if not(i <= 4) then break end
			if self._data_map[i][j] ~= nil then
				local info = {}
				info.item = self._data_map[i][j]
				info.row = i
				info.col = j
				list_count = list_count + 1
				list[list_count] = info
			end
			i = i+(1)
		end
		if list_count == 1 then
			self:TransItem(list[1], 1, j)
		elseif list_count == 2 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], 1, j)
			else
				self:TransItem(list[1], 1, j)
				self:TransItem(list[2], 2, j)
			end
		elseif list_count == 3 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], 1, j)
				self:TransItem(list[3], 2, j)
			elseif list[2].item._user_data == list[3].item._user_data then
				self:TransItem(list[1], 1, j)
				self:CombineItems(list[2], list[3], 2, j)
			else
				self:TransItem(list[1], 1, j)
				self:TransItem(list[2], 2, j)
				self:TransItem(list[3], 3, j)
			end
		elseif list_count == 4 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], 1, j)
				if list[3].item._user_data == list[4].item._user_data then
					self:CombineItems(list[3], list[4], 2, j)
				else
					self:TransItem(list[3], 2, j)
					self:TransItem(list[4], 3, j)
				end
			elseif list[2].item._user_data == list[3].item._user_data then
				self:TransItem(list[1], 1, j)
				self:CombineItems(list[2], list[3], 2, j)
				self:TransItem(list[4], 3, j)
			elseif list[3].item._user_data == list[4].item._user_data then
				self:TransItem(list[1], 1, j)
				self:TransItem(list[2], 2, j)
				self:CombineItems(list[3], list[4], 3, j)
			end
		end
		j = j+(1)
	end
end

function G2048.GCenter:CalcDown()
	local j = 1
	while true do
		if not(j <= 4) then break end
		local list = {}
		local list_count = 0
		local i = 4
		while true do
			if not(i >= 1) then break end
			if self._data_map[i][j] ~= nil then
				local info = {}
				info.item = self._data_map[i][j]
				info.row = i
				info.col = j
				list_count = list_count + 1
				list[list_count] = info
			end
			i = i+(-1)
		end
		if list_count == 1 then
			self:TransItem(list[1], 5 - 1, j)
		elseif list_count == 2 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], 5 - 1, j)
			else
				self:TransItem(list[1], 5 - 1, j)
				self:TransItem(list[2], 5 - 2, j)
			end
		elseif list_count == 3 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], 5 - 1, j)
				self:TransItem(list[3], 5 - 2, j)
			elseif list[2].item._user_data == list[3].item._user_data then
				self:TransItem(list[1], 5 - 1, j)
				self:CombineItems(list[2], list[3], 5 - 2, j)
			else
				self:TransItem(list[1], 5 - 1, j)
				self:TransItem(list[2], 5 - 2, j)
				self:TransItem(list[3], 5 - 3, j)
			end
		elseif list_count == 4 then
			if list[1].item._user_data == list[2].item._user_data then
				self:CombineItems(list[1], list[2], 5 - 1, j)
				if list[3].item._user_data == list[4].item._user_data then
					self:CombineItems(list[3], list[4], 5 - 2, j)
				else
					self:TransItem(list[3], 5 - 2, j)
					self:TransItem(list[4], 5 - 3, j)
				end
			elseif list[2].item._user_data == list[3].item._user_data then
				self:TransItem(list[1], 5 - 1, j)
				self:CombineItems(list[2], list[3], 5 - 2, j)
				self:TransItem(list[4], 5 - 3, j)
			elseif list[3].item._user_data == list[4].item._user_data then
				self:TransItem(list[1], 5 - 1, j)
				self:TransItem(list[2], 5 - 2, j)
				self:CombineItems(list[3], list[4], 5 - 3, j)
			end
		end
		j = j+(1)
	end
end

function G2048.GCenter:BornItem(number, row, col, delay_time, anti)
	local target = self["_tile" .. row .. col]
	local ui_name = "item_" .. number
	local item = G2048.g_Control:CreateControl(ui_name, nil, nil)
	self._data_map[row][col] = item
	item._user_data = number
	self._tile_container:AddChild(item, nil)
	local target_x = target.x
	local target_y = target.y
	local target_width = target.width
	local target_height = target.height
	if anti == true then
		item.width = 0
		item.height = 0
		item.x = target_x + target_width / 2
		item.y = target_y + target_height / 2
		item.visible = false
		local loop = ALittle.LoopAttribute(item, "visible", true, delay_time)
		self._loop_group[loop] = loop
		A_LoopSystem:AddUpdater(loop)
		loop = ALittle.LoopLinear(item, "x", target_x, 100, delay_time, nil)
		self._loop_group[loop] = loop
		A_LoopSystem:AddUpdater(loop)
		loop = ALittle.LoopLinear(item, "y", target_y, 100, delay_time, nil)
		self._loop_group[loop] = loop
		A_LoopSystem:AddUpdater(loop)
		loop = ALittle.LoopLinear(item, "width", target_width, 100, delay_time, nil)
		self._loop_group[loop] = loop
		A_LoopSystem:AddUpdater(loop)
		loop = ALittle.LoopLinear(item, "height", target_height, 100, delay_time, nil)
		self._loop_group[loop] = loop
		A_LoopSystem:AddUpdater(loop)
	else
		item.width = target_width
		item.height = target_height
		item.x = target_x
		item.y = target_y
		item.visible = false
		local loop = ALittle.LoopAttribute(item, "visible", true, delay_time)
		self._loop_group[loop] = loop
		A_LoopSystem:AddUpdater(loop)
	end
end

function G2048.GCenter:TransItem(item_info, to_row, to_col)
	local target = self["_tile" .. to_row .. to_col]
	local target_x = target.x
	local target_y = target.y
	if item_info.col ~= to_col then
		local loop = ALittle.LoopLinear(item_info.item, "x", target_x, 200, 0, nil)
		self._loop_group[loop] = loop
		A_LoopSystem:AddUpdater(loop)
		self._item_moved = true
	end
	if item_info.row ~= to_row then
		local loop = ALittle.LoopLinear(item_info.item, "y", target_y, 200, 0, nil)
		self._loop_group[loop] = loop
		A_LoopSystem:AddUpdater(loop)
		self._item_moved = true
	end
	self._data_map[item_info.row][item_info.col] = nil
	self._data_map[to_row][to_col] = item_info.item
	if self._loop_delay < 200 then
		self._loop_delay = 200
	end
end

function G2048.GCenter:CombineItems(item1_info, item2_info, to_row, to_col)
	self:TransAndRemoveItem(item1_info.item, item1_info.row, item1_info.col, to_row, to_col)
	self:TransAndRemoveItem(item2_info.item, item2_info.row, item2_info.col, to_row, to_col)
	self:BornItem(item1_info.item._user_data * 2, to_row, to_col, 200, false)
	self._score_text._user_data = self._score_text._user_data + item1_info.item._user_data * 2
	self._score_text.text = self._score_text._user_data
	self._item_moved = true
	if self._loop_delay < 300 then
		self._loop_delay = 300
	end
end

function G2048.GCenter:TransAndRemoveItem(item, from_row, from_col, to_row, to_col)
	local target = self["_tile" .. to_row .. to_col]
	local target_x = target.x
	local target_y = target.y
	if from_col ~= to_col then
		local loop = ALittle.LoopLinear(item, "x", target_x, 200, 0, nil)
		self._loop_group[loop] = loop
		A_LoopSystem:AddUpdater(loop)
	end
	if from_row ~= to_row then
		local loop = ALittle.LoopLinear(item, "y", target_y, 200, 0, nil)
		self._loop_group[loop] = loop
		A_LoopSystem:AddUpdater(loop)
	end
	local loop = ALittle.LoopTimer(Lua.Bind(self.EraseItem, self, item), 200)
	self._loop_group[loop] = loop
	A_LoopSystem:AddUpdater(loop)
	self._data_map[from_row][from_col] = nil
end

function G2048.GCenter:EraseItem(item)
	self._tile_container:RemoveChild(item)
end

function G2048.GCenter:HandleKeyDown(event)
	self:ClearAnti()
	self._item_moved = false
	self._loop_delay = 0
	if event.sym == 1073741904 then
		self:CalcLeft()
	elseif event.sym == 1073741903 then
		self:CalcRight()
	elseif event.sym == 1073741906 then
		self:CalcUp()
	elseif event.sym == 1073741905 then
		self:CalcDown()
	end
	if self:CheckGameWin() ~= nil then
		return
	end
	if self._item_moved == false then
		return
	end
	self:GenerateItem(self._loop_delay)
	if self:CheckGameWin() ~= nil then
		return
	end
end

function G2048.GCenter:CalcState()
	local state = {}
	local index = 1
	local i = 1
	while true do
		if not(i <= 4) then break end
		local j = 1
		while true do
			if not(j <= 4) then break end
			local item = self._data_map[i][j]
			local value = 0
			if item ~= nil then
				value = item._user_data
			end
			state[index] = (math.log(value + 1) / math.log(2)) / 16
			index = index + (1)
			j = j+(1)
		end
		i = i+(1)
	end
	return state
end

function G2048.GCenter:CalcValueMap()
	local value_map = {}
	local i = 1
	while true do
		if not(i <= 4) then break end
		local map = {}
		value_map[i] = map
		local j = 1
		while true do
			if not(j <= 4) then break end
			local item = self._data_map[i][j]
			if item == nil then
				map[j] = 0
			else
				map[j] = item._user_data
			end
			j = j+(1)
		end
		i = i+(1)
	end
	return value_map
end

function G2048.GCenter:CalcSmooth(value_map)
	local score = 0.0
	local i = 1
	while true do
		if not(i < 4) then break end
		local j = 1
		while true do
			if not(j < 4) then break end
			local item = value_map[i][j]
			if item ~= 0 then
				local col = j + 1
				while true do
					if not(col <= 4) then break end
					local right_item = value_map[i][col]
					if right_item ~= 0 then
						if item == right_item then
							score = score + (item)
						end
						break
					end
					col = col+(1)
				end
				local row = i + 1
				while true do
					if not(row <= 4) then break end
					local bottom_item = value_map[row][j]
					if bottom_item ~= 0 then
						if item == bottom_item then
							score = score + (item)
						end
						break
					end
					row = row+(1)
				end
			end
			j = j+(1)
		end
		i = i+(1)
	end
	return score
end

function G2048.GCenter:CalcMonotonous(value_map)
	local score = 0.0
	local i = 1
	while true do
		if not(i <= 4) then break end
		local j = 1
		while true do
			if not(j <= 4) then break end
			local value = value_map[i][j]
			score = score + (value * (i + j))
			j = j+(1)
		end
		i = i+(1)
	end
	return score
end

function G2048.GCenter:CalcMean(value_map)
	local score = 0.0
	local count = 0
	local i = 1
	while true do
		if not(i <= 4) then break end
		local j = 1
		while true do
			if not(j <= 4) then break end
			local value = value_map[i][j]
			score = score + (value)
			if value > 0 then
				count = count + (1)
			end
			j = j+(1)
		end
		i = i+(1)
	end
	return (math.log(score + 1) / math.log(2)) / count
end

function G2048.GCenter:CalcEmpty()
	local score = 0.0
	local i = 1
	while true do
		if not(i <= 4) then break end
		local j = 1
		while true do
			if not(j <= 4) then break end
			local item = self._data_map[i][j]
			if item == nil or item._user_data == 0 then
				score = score + (((5 - i) + (5 - j)) * ((5 - i) + (5 - j)))
			end
			j = j+(1)
		end
		i = i+(1)
	end
	return score
end

function G2048.GCenter:CalcReward(old_value_map, new_value_map, die, old_score, new_score)
	local changed = false
	local i = 1
	while true do
		if not(i <= 4) then break end
		local j = 1
		while true do
			if not(j <= 4) then break end
			if old_value_map[i][j] ~= new_value_map[i][j] then
				changed = true
				break
			end
			j = j+(1)
		end
		i = i+(1)
	end
	local score = 1
	if not die then
		if changed then
			score = score + (1)
		end
		score = score + (self:CalcSmooth(new_value_map))
		score = score + (new_score)
	end
	if score <= 0 then
		score = 1
	end
	return (math.log(score) / math.log(2)) / 16
end

function G2048.GCenter:HandleDragBegin(event)
	self._drag_total_x = 0
	self._drag_total_y = 0
end

function G2048.GCenter:HandleDrag(event)
	self._drag_total_x = self._drag_total_x + event.delta_x
	self._drag_total_y = self._drag_total_y + event.delta_y
end

function G2048.GCenter:HandleDqnPlay()
	local state = self:CalcState()
	local action = 0
	if ALittle.Math_RandomInt(1, 1000) < 1000 then
		action = self._dqn_model:ChooseAction(state)
	else
		action = ALittle.Math_RandomInt(0, 3)
	end
	self:ClearAnti()
	self._item_moved = false
	self._loop_delay = 0
	local old_value_map = self:CalcValueMap()
	local old_score = self._score_text._user_data
	if action == 0 then
		self:CalcDown()
	elseif action == 1 then
		self:CalcRight()
	elseif action == 2 then
		self:CalcLeft()
	elseif action == 3 then
		self:CalcUp()
	end
	if self._item_moved == false then
		local new_value_map = self:CalcValueMap()
		local win = self:CheckGameWin()
		local new_score = self._score_text._user_data
		local reward = self:CalcReward(old_value_map, new_value_map, win == false, old_score, new_score)
		local next_state = self:CalcState()
		self._dqn_model:SaveTransition(state, action, reward, next_state)
		local i = 0
		while true do
			if not(i <= 3) then break end
			action = i
			if action == 0 then
				self:CalcDown()
			elseif action == 1 then
				self:CalcRight()
			elseif action == 2 then
				self:CalcLeft()
			elseif action == 3 then
				self:CalcUp()
			end
			if self._item_moved then
				break
			end
			i = i+(1)
		end
	end
	local new_value_map = self:CalcValueMap()
	local win = self:CheckGameWin()
	local new_score = self._score_text._user_data
	local reward = self:CalcReward(old_value_map, new_value_map, win == false, old_score, new_score)
	local next_state = self:CalcState()
	self._dqn_model:SaveTransition(state, action, reward, next_state)
	local i = 1
	while true do
		if not(i <= 1) then break end
		self._dqn_model:LearnLastTransition(50)
		i = i+(1)
	end
	if self:CheckGameWin() ~= nil then
		return
	end
	if self._item_moved == false then
		return
	end
	self:GenerateItem(self._loop_delay)
	if self:CheckGameWin() ~= nil then
		return
	end
end

function G2048.GCenter:HandleDragEnd(event)
	self:ClearAnti()
	self._item_moved = false
	self._loop_delay = 0
	if ALittle.Math_Abs(self._drag_total_x) > ALittle.Math_Abs(self._drag_total_y) then
		if self._drag_total_x < 0 then
			self:CalcLeft()
		else
			self:CalcRight()
		end
	else
		if self._drag_total_y < 0 then
			self:CalcUp()
		else
			self:CalcDown()
		end
	end
	if self:CheckGameWin() ~= nil then
		return
	end
	if self._item_moved == false then
		return
	end
	self:GenerateItem(self._loop_delay)
	if self:CheckGameWin() ~= nil then
		return
	end
end

function G2048.GCenter:CheckGameWin()
	local i = 1
	while true do
		if not(i <= 4) then break end
		local j = 1
		while true do
			if not(j <= 4) then break end
			local item = self._data_map[i][j]
			if item ~= nil and item._user_data == 2048 then
				self:ShowMainMenu("Victory", false)
				self._mean_total_score = self._mean_total_score + (self._score_text._user_data)
				self._mean_total_count = self._mean_total_count + (1)
				self._mean_score_text.text = self._mean_total_score / self._mean_total_count
				if self._max_score_text._user_data < self._score_text._user_data then
					self._max_score_text._user_data = self._score_text._user_data
					self._max_score_text.text = self._max_score_text._user_data
					G2048.g_GConfig:SetConfig("max_score", self._max_score_text._user_data, nil)
				end
				if self._dqn_model ~= nil then
					self._dqn_model:Save(self._dqn_model_path)
					if self._dqn_timer ~= nil then
						A_LoopSystem:RemoveTimer(self._dqn_timer)
						self._dqn_timer = nil
					end
				end
				return true
			end
			j = j+(1)
		end
		i = i+(1)
	end
	local i = 1
	while true do
		if not(i <= 4) then break end
		local j = 1
		while true do
			if not(j <= 4) then break end
			local item = self._data_map[i][j]
			if item == nil then
				return nil
			end
			if j > 1 and (self._data_map[i][j - 1] == nil or self._data_map[i][j - 1]._user_data == item._user_data) then
				return nil
			end
			if j < 4 and (self._data_map[i][j + 1] == nil or self._data_map[i][j + 1]._user_data == item._user_data) then
				return nil
			end
			if i > 1 and (self._data_map[i - 1][j] == nil or self._data_map[i - 1][j]._user_data == item._user_data) then
				return nil
			end
			if i < 4 and (self._data_map[i + 1][j] == nil or self._data_map[i + 1][j]._user_data == item._user_data) then
				return nil
			end
			j = j+(1)
		end
		i = i+(1)
	end
	self._mean_total_score = self._mean_total_score + (self._score_text._user_data)
	self._mean_total_count = self._mean_total_count + (1)
	self._mean_score_text.text = self._mean_total_score / self._mean_total_count
	self:ShowMainMenu("GameOver", false)
	if self._max_score_text._user_data < self._score_text._user_data then
		self._max_score_text._user_data = self._score_text._user_data
		self._max_score_text.text = self._max_score_text._user_data
		G2048.g_GConfig:SetConfig("max_score", self._max_score_text._user_data, nil)
	end
	if self._dqn_model ~= nil then
		self._dqn_model:Save(self._dqn_model_path)
		self:Restart()
	end
	return false
end

function G2048.GCenter:HandleRestartClick(event)
	self:Restart()
end

function G2048.GCenter:HandleBackClick(event)
	self._main_menu.visible = false
end

function G2048.GCenter:HandleMenuClick(event)
	self:ShowMainMenu("", true)
end

function G2048.GCenter:Shutdown()
	if self._dqn_model ~= nil then
		self._dqn_model:Save(self._dqn_model_path)
		self._dqn_model = nil
	end
	if self._dqn_timer ~= nil then
		A_LoopSystem:RemoveTimer(self._dqn_timer)
		self._dqn_timer = nil
	end
end

G2048.g_GCenter = G2048.GCenter()
end