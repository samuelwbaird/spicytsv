-- internal/local functions used during parsing ---------------------------------------------

-- infer the value type from the cell string if it appears
-- to be a boolean or number
local function convert_value(value)
	if value:lower() == 'true' then
		return true
	elseif value:lower() == 'false' then
		return false
	elseif tonumber(value) then
		return tonumber(value)
	else
		return value
	end
end

-- first correctly parse the TSV data into rows and cells respecting quoted cells
-- optionally convert value types in non-quoted cells
local function parse_tsv(data, convert_values_types)
	local rows = {}
	local current_row = nil
	local current_value = nil
	local in_quote = false

	for i = 1, #data do
		local char = data:sub(i, i)

		if in_quote then
			if char == in_quote and (i == #data or data:sub(i + 1, i + 1) == '\t') then
				in_quote = false
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
				if convert_values_types then
					current_row[#current_row + 1] = convert_value(table.concat(current_value))
				else
					current_row[#current_row + 1] = table.concat(current_value)
				end
			end
			current_row = nil
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
					in_quote = char
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
		if convert_values_types then
			current_row[#current_row + 1] = convert_value(table.concat(current_value))
		else
			current_row[#current_row + 1] = table.concat(current_value)
		end
	end

	return rows
end

-- return a whitespace cleaned version of the row, retaining the cells
local function clean(row)
	local out = {}
	for i, c in ipairs(row) do
		out[i] = c:match('^%s*(.-)%s*$')
	end
	return out
end

-- check if a row is completely free of content
local function is_blank_row(row)
	for _, field in ipairs(clean(row)) do
		if field ~= '' then
			return false
		end
	end
	return true
end

-- comment rows begin with a # character
local function is_comment_row(row)
	return row[1] and row[1]:sub(1, 1) == '#'
end

-- named sections begin with a single cell in angle brackets, eg. <section_name>
local function get_section_name(row)
	return table.concat(row, ' '):match('^<(.+)>')
end

local function is_section_row(row)
	return get_section_name(row) ~= nil
end

-- parse heading information from a row
-- field names enclosed in square brackets are list fields
-- field names enclosed in curly brackets are object fields
-- fields enclosed in [{}] are lists of subobjects
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

-- check if a row is providing additional information to a list of a preceeding row
local function is_sub_row(row, headings)
	if is_blank_row(row) then
		return false
	end
	for i, c in ipairs(row) do
		-- if the column is not a list column, and it has content, then this is not a subrow
		if not (headings[i] and headings[i].list) then
			if c:match('^%s*(.-)%s*$') ~= '' then
				return false
			end
		end
	end
	return true
end

-- add either the primary row information, or additional sub rows to a defined object in the data
local function add_row_to_object(row, object, headings, object_row)
	for fieldIndex, field in ipairs(headings) do
		if field.list or field.object then
			local sub = object[field.property]
			if not sub then
				sub = {}
				object[field.property] = sub
			end
			local value = row[fieldIndex]
			if value and value ~= '' then
				if field.list and field.object then
					sub[object_row] = sub[object_row] or {}
					sub[object_row][field.sub_property] = value
				elseif field.object then
					sub[field.sub_property] = value
				elseif field.list then
					sub[#sub + 1] = value
				end
			end
		else
			if object_row == 1 then
				object[field.property] = row[fieldIndex]
			end
		end
	end
end

-- parse a string of the complete content into an object tree or list
-- applying all the rules of the format
local function parse(data, convert_values_types)
	local rows = parse_tsv(data, convert_values_types)

	local output = {}
	local headings = nil
	local current_collection = output
	local current_object = nil
	local object_row = 0

	for r, row in ipairs(rows) do
		if is_comment_row(row) then
			-- ignore completely
		elseif is_blank_row(row) then
			current_object = nil
		elseif is_section_row(row) then
			-- start a new section under this name
			if #output > 0 then
				error('cannot mix named and unnamed sections')
			end
			current_collection = {}
			output[get_section_name(row)] = current_collection
			current_object = nil
			headings = nil
			object_row = 0
		elseif not headings then
			headings = parse_headings(clean(row))
		elseif is_sub_row(row, headings) then
			if not current_object then
				error('orphan sub row at row ' .. r)
			end
			-- add the sub row data
			object_row = object_row + 1
			add_row_to_object(row, current_object, headings, object_row)
		else
			-- start a new object
			current_object = {}
			current_collection[#current_collection + 1] = current_object
			object_row = 1
			add_row_to_object(row, current_object, headings, object_row)
		end
	end

	return output
end

-- return the public available functions
return {
	parse_tsv = parse_tsv,
	parse = parse,
}
