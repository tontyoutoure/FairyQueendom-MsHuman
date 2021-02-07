-- Localization_Generation
-- Author: LI Kun
-- DateCreated: 2021-2-5 4:53:31 AM
-- This script should be run in WSL lua, and the same directory with the xmls
--------------------------------------------------------------
language_list = {"en_US", "zh_Hans_CN"}
language_file_prefix = "FairyQueendom"
output_file = {}
tags = {}

for i, v in ipairs(language_list) do
	output_file[i] = io.open(language_file_prefix .. "_text_" .. v ..".sql",'w')
	print(output_file[i])
end

os.execute('ls *xml >xmlfile.txt')
local file_list_file = io.open('xmlfile.txt', 'r')

function WriteSql(string, idx)
	for idx, l in ipairs(language_list) do
		output_file[idx]:write('UPDATE LocalizedText SET Text=""\r\n')
		output_file[idx]:write('WHERE langage="' .. language_list[idx] ..'" AND Tag="' .. string .. '"\r\n\r\n')
	end
end


while true do
	local line = file_list_file:read()
	if line == nil then break end
	local xml_file = io.open(line, 'r')
	while true do -- loop over xml files
		local xml_line = xml_file:read()
		if xml_line == nil then break end
		local start =0
		local ending = 0
		while true do
			if not string.find(xml_line, "LOC", start+1) then break end
			start = string.find(xml_line, "LOC", start+1)
			start_op = string.sub(xml_line, start-1, start-1);
			if start_op == ">" then
				ending = string.find(xml_line, "<", start);
			else
				ending = string.find(xml_line, string.sub(xml_line, start-1, start-1), start);
			end
			tag = string.sub(xml_line, start, ending-1)
			if not tags[tag] then
				WriteSql(tag)
				tags[tag] = true
			end
		end
	end
end
file_list_file.close()

for i, v in ipairs(language_list) do
	output_file[i]:close()
end