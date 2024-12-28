local M = require("neovimPlugins.lua.nightwatchman")

print(M)

vim.keymap.set("n", "<leader><leader>nw", M.start, { desc = "[N]ight[W]atchman" })
