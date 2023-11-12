local spicytsv = {}

local function parseTSV(data)
	local rows = {}
	local current_row = nil
	local current_value = nil
	local in_comment = false
	local in_delimeter = false

	for i = 1, #data do
		local char = data:sub(i, i)

		if in_comment then
			if char == '\n' then
				in_comment = false
			end
		elseif in_delimeter then
			if char == in_delimeter and (i == #data or data:sub(i + 1, i + 1) == '\t') then
				in_delimeter = false
				current_row[#current_row + 1] = table.concat(current_value)
				current_value = nil
			else
				current_value[#current_value + 1] = char
			end
		elseif char == '\t' then
			if not current_row then
				current_row = {}
				rows[#rows + 1] = current_row
			end
			current_row[#current_row + 1] = (current_value and table.concat(current_value) or '')
			current_value = nil
		elseif char == '\n'then
			if current_value then
				current_row[#current_row + 1] = table.concat(current_value)
			end
			current_row = nil
		elseif char == '#' and not current_row then
			in_comment = true
		else
			if not current_row then
				current_row = {}
				rows[#rows + 1] = current_row
			end
			if current_value then
				current_value[#current_value + 1] = char
			else
				current_value = {}
				if char == '"' or char == "'" then
					in_delimeter = char
				else
					current_value[1] = char
				end
			end
		end
	end

	-- get the last token
	if current_value then
		if not current_row then
			current_row = {}
			rows[#rows + 1] = current_row
		end
		current_row[#current_row + 1] = table.concat(current_value)
	end

	return rows
end

local function clean(row)
	local out = {}
	for i, c in ipairs(row) do
		out[i] = c:match('^%s*(.-)%s*$')
	end
	return out
end

local function parse_headings(row)
	local out = {}
	for i, c in ipairs(row) do
		local field = {}
		local withinList = c:match('^%[([^]]+)%]$')
		if withinList then
			field.list = true
			c = withinList
		end
		local object = c:match('^%{([^}]+)%}$')
		if object then
			field.object = true
			c = object
			-- split propery and sub property
			c, field.sub_property = object:match('([^%.]+)%.(.+)')
		end
		if c ~= '' then
			field.property = c
			out[#out + 1] = field
		end
	end
	return out
end

local function is_blank_row(row)
	for _, field in ipairs(clean(row)) do
		if field ~= '' then
			return false
		end
	end
	return true
end

local function is_sub_row(row, list_columns)
	if is_blank_row(row) then
		return false
	end
	for i, c in ipairs(row) do
		if not list_columns[i] then
			if c:match('^%s*(.-)%s*$') ~= '' then
				return false
			end
		end
	end
	return true
end

local function group_headings_and_rows(rows)
	local current_headings = nil
	local list_columns = nil
	local items = {}

	local r = 1
	while r <= #rows do
		local row = rows[r]
		if is_blank_row(row) then
			current_headings = nil
			r = r + 1
		elseif current_headings == nil then
			current_headings = parse_headings(clean(row))
			-- track which columns are list columns [field]
			list_columns = {}
			for i, c in ipairs(current_headings) do
				if c.list then
					list_columns[i] = true
				end
			end
			r = r + 1
		else
			-- find out how many rows belong to this item
			local item_rows = { row }
			-- if the following rows are blank in the non-list rows, but not completely blank, then add them
			while r < #rows do
				r = r + 1
				local sub_row = rows[r]
				if is_sub_row(sub_row, list_columns) then
					item_rows[#item_rows + 1] = sub_row
				else
					break
				end
			end
			items[#items + 1] = {
				headings = current_headings,
				rows = item_rows,
			}
		end
	end

	return items
end

local function create_objects(items)
	local out = {}
	for _, item in ipairs(items) do
		local obj = {}
		for fieldIndex, field in ipairs(item.headings) do
			if field.list or field.object then
				obj[field.property] = {}
			else
				obj[field.property] = item.rows[1][fieldIndex]
			end
		end
		
		for i, row in ipairs(item.rows) do				
			for fieldIndex, field in ipairs(item.headings) do
				local value = row[fieldIndex]
				if value and value ~= '' then
					if field.list and field.object then
						local list = obj[field.property]
						list[i - 1] = list[i - 1] or {}
						list[i - 1][field.sub_property] = value
					elseif field.object then
						obj[field.property][field.sub_property] = value
					elseif field.list then
						local list = obj[field.property]
						list[#list + 1] = value
					end
				end
			end
		end
		out[#out + 1] = obj
	end
	return out
end

spicytsv.parse = function (data)
	local rows = parseTSV(data)
	local items = group_headings_and_rows(rows)
	local objects = create_objects(items)
	return objects
end

return spicytsv