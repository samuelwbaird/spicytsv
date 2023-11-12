local spicytsv = require('spicytsv')

-- read the file contents into memory
function readfile(filename)
	local input = io.open(filename, 'rb')
	local content = input:read('*a')
	input:close()
	return content
end

function display(data)
	-- display as JSON to show the resulting output format
	local json = require('cjson')
	print(json.encode(data))
end

-- open and display the data from example 1
local data = spicytsv.parse(readfile('example1.tsv'))
print('Example 1, converted to JSON')
display(data)
print('')

-- open and display the data from example 2
local data = spicytsv.parse(readfile('example2.tsv'))
print('Example 2, converted to JSON')
display(data)
print('')
