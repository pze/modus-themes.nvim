-- Extras template builder modified from:
-- https://github.com/folke/tokyonight.nvim/blob/main/lua/tokyonight/extra/init.lua

local M = {}

-- map of plugin name to plugin extension
--- @type table<string, {ext:string, url:string, label:string}>
-- stylua: ignore
M.extras = {
	alacritty = { ext = "yml", url = "https://github.com/alacritty/alacritty", label = "Alacritty" },
	delta = { ext = "gitconfig", url = "https://github.com/dandavison/delta", label = "Delta" },
	dunst = { ext = "dunstrc", url = "https://dunst-project.org/", label = "Dunst" },
	fish = { ext = "fish", url = "https://fishshell.com/docs/current/index.html", label = "Fish" },
	foot = { ext = "ini", url = "https://codeberg.org/dnkl/foot", label = "Foot" },
}

local function write(str, fileName)
	print("[write] extras/" .. fileName .. "\n")
	vim.fn.mkdir(vim.fs.dirname("extras/" .. fileName), "p")
	local file = io.open("extras/" .. fileName, "w")
	file:write(str)
	file:close()
end

function M.read_file(file)
	local fd = assert(io.open(file, "r"))
	---@type string
	local data = fd:read("*a")
	fd:close()
	return data
end

function M.write_file(file, contents)
	local fd = assert(io.open(file, "w+"))
	fd:write(contents)
	fd:close()
end

function M.docs()
	local file = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h:h") .. "/README.md"
	local tag = "extras"
	local pattern = "(<%!%-%- " .. tag .. ":start %-%->).*(<%!%-%- " .. tag .. ":end %-%->)"
	local readme = M.read_file(file)
	local lines = {}
	local names = vim.tbl_keys(M.extras)
	table.sort(names)
	table.insert(lines, "")
	for _, name in ipairs(names) do
		local info = M.extras[name]
		table.insert(lines, "- [" .. info.label .. "](" .. info.url .. ") ([" .. name .. "](extras/" .. name .. "))")
	end
	table.insert(lines, "")
	readme = readme:gsub(pattern, "%1\n" .. table.concat(lines, "\n") .. "\n%2")
	M.write_file(file, readme)
end

function M.setup()
	M.docs()
	local modus = require("modus-themes")

	local styles = {
		modus_operandi = "Modus Operandi",
		modus_vivendi = "Modus Vivendi",
	}

	for extra, info in pairs(M.extras) do
		package.loaded["modus-themes.extras." .. extra] = nil
		local plugin = require("modus-themes.extras." .. extra)

		for style, style_name in pairs(styles) do
			modus.setup({ style = style })
			modus.load({ style = style })
			vim.cmd.colorscheme(style)
			local colors = require("modus-themes.colors").setup()
			local fname = extra .. "/" .. style .. "." .. info.ext
			colors["_upstream_url"] = "https://github.com/miikanissi/modus-themes.nvim/raw/master/extras/" .. fname
			colors["_style_name"] = style_name
			colors["_name"] = style
			write(plugin.generate(colors), fname)
		end
	end
end

return M