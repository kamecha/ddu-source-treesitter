local M = {}

--- Check if a plugin is installed
-- @param name string: The name of the plugin
-- @return boolean: True if the plugin is installed, false otherwise
function M.is_plugin_installed(name)
	local ok, _ = pcall(require, name)
	return ok
end

--- Check if a parser is installed for the specified buffer
-- @param bufnr number: The buffer number
-- @return boolean: True if the parser is installed, false otherwise
function M.is_parser_installed(bufnr)
	local parsers = require("nvim-treesitter.parsers")
	local lang = parsers.get_buf_lang(bufnr)
	return parsers.has_parser(lang)
end

--- dump table values recursively
-- @param tbl table: The table to dump
-- @return nil
local function dump_table(tbl, bufnr)
	for key, val in pairs(tbl) do
		if type(val) == "table" then
			print(key, "table")
			dump_table(val, bufnr)
		else
			if key == "node" then
				print(key, vim.treesitter.get_node_text(val, bufnr))
				print("TSNode:start", val:start())
				print("TSNode:type", val:type())
				print("TSNode:symbol", val:symbol())
				print("TSNode:named", val:named())
				print("node type", type(val))
			end
			if key == "kind" then
				print(key, val)
			end
		end
	end
end

local function prepare_match(entry)
	local entries = {}
	if entry.node then
		table.insert(entries, entry)
	else
		for _, item in pairs(entry) do
			vim.list_extend(entries, prepare_match(item))
		end
	end
	return entries
end

--- Get the current definitions
-- @param bufnr number: The buffer number
-- @return table: { name = string, kind = string, start = [row, column, byte count] }
function M.get_definitions(bufnr)
	local results = {}
	local ts_locals = require("nvim-treesitter.locals")
	for _, definition in ipairs(ts_locals.get_definitions(bufnr)) do
		local local_nodes = ts_locals.get_local_nodes(definition)
		local entries = prepare_match(local_nodes)
		for _, entry in ipairs(entries) do
			entry.kind = vim.F.if_nil(entry.kind, "")
			-- print(">dumping local nodes<")
			-- dump_table(entry, bufnr)
			table.insert(results, {
				name = vim.treesitter.get_node_text(entry.node, bufnr),
				kind = entry.kind,
				start = { entry.node:start() },
			})
		end
	end
	-- print(vim.inspect(results))
	return results
end

return M
