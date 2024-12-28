local M = {}

M.state = {}

M.getWinSize = function()
	M.state.width = math.floor(vim.o.columns * 0.8)
	M.state.height = 1
	M.state.row = math.floor((vim.o.lines - M.state.height) / 2)
	M.state.col = math.floor((vim.o.columns - M.state.width) / 2)
end

M.getWindowConfiguration = function()
	return {
		style = "minimal",
		border = "single",
		title_pos = "left",
		title = "nightwatchman",
		relative = "win",
		row = M.state.row,
		col = M.state.col,
		width = M.state.width,
		height = M.state.height,
	}
end

M.getWinSize()

M.start = function()
	M.state.input_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value("buftype", "prompt", { buf = M.state.input_buf })
	vim.fn.prompt_setcallback(M.state.input_buf, function(input)
		print("You entered " .. input .. " in " .. M.state.input_buf)
		M.close()
	end)

	M.state.in_win = vim.api.nvim_open_win(M.state.input_buf, true, M.getWindowConfiguration())
end

M.close = function()
	vim.api.nvim_win_close(M.state.in_win, true)
	vim.api.nvim_command("bdelete! " .. M.state.input_buf)
end

vim.api.nvim_create_autocmd("VimResized", {
	group = vim.api.nvim_create_augroup("nightwatchman-resized", {}),
	callback = function()
		if not vim.api.nvim_win_is_valid(M.state.in_win) or M.state.in_win == nil then
			return
		end
		M.getWinSize()
		vim.api.nvim_win_set_config(M.state.in_win, M.getWindowConfiguration())
	end,
})

return M
