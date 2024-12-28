local M = {}

M.logs = {}
M.std_in = nil
M.std_out = nil
M.std_err = nil

M.read_buffer_on_enter = function(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false) -- Get all lines from the buffer
	local input = table.concat(lines, "\n") -- Join lines with newline character
	return input
end

M.list_files_in_directory = function(directory)
	local result = {}
	-- Open a command to list the files in the directory
	local p = io.popen('ls -pa "' .. directory .. '"') -- Use "dir" for Windows

	if not p then
		table.insert(M.logs, "failed to get files in directory:" .. directory)
		return {}
	end

	-- Iterate over each file name returned by the command
	for file in p:lines() do
		table.insert(M.logs, "file found in dir:" .. file)
		table.insert(result, file)
	end

	-- Close the popen handle
	p:close()
	return result
end

M.determine_env_name = function(currentDir)
	local found = false
	local envFile = nil

	repeat
		local files = M.list_files_in_directory(currentDir)

		if next(files) == nil then
			table.insert(M.logs, "failed to get files in currentDir or parents:" .. currentDir)
			return nil
		end

		for _, file in ipairs(files) do
			if string.find(file, ".env") then
				found = true
				envFile = file
			end
		end

		currentDir = "../" .. currentDir
	until found

	return envFile
end

M.runCommand = function(command, args, buf)
	-- Function to append text to buffer
	local function append_output(output)
		if buf == nil then
			return
		end

		local lines = vim.split(output, "\n", nil)
		vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
	end

	-- Spawn the command using vim.loop.spawn()
	local stdin = vim.loop.new_pipe(false)
	local stdout = vim.loop.new_pipe(false)
	local stderr = vim.loop.new_pipe(false)
	local handle

	M.std_in = stdin
	M.std_out = stdout
	M.std_err = stderr

	append_output(command)

	handle = vim.loop.spawn(command, {
		args = args,
		stdio = { stdin, stdout, stderr },
	}, function(code, signal)
		-- Close the floating window when done
		vim.schedule(function()
			append_output("DONE")
			print("exit code", code)
			print("exit signal", signal)
			if stdout ~= nil then
				stdout:close()
			end
			if stderr ~= nil then
				stderr:close()
			end
			if handle ~= nil then
				handle:close()
			end
		end)
	end)

	-- Read stdout
	vim.loop.read_start(stdout, function(err, data)
		if err then
			vim.schedule(function()
				append_output({ err })
			end)
		end
		if data then
			vim.schedule(function()
				append_output(data)
			end)
		end
	end)

	-- Read stderr (optional)
	vim.loop.read_start(stderr, function(err, data)
		if err then
			vim.schedule(function()
				append_output({ err })
			end)
		end
		if data then
			vim.schedule(function()
				append_output(data)
			end)
		end
	end)
end

return M
