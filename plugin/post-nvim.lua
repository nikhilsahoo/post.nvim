if vim.g.post_nvim_loaded then
  return
end
vim.g.post_nvim_loaded = true

local post = require("post-nvim")

vim.api.nvim_create_user_command("PostRun", function()
  post.run_buffer()
end, { desc = "Run HTTP request from current buffer" })

vim.api.nvim_create_user_command("PostRunVisual", function()
  post.run_visual_selection()
end, { range = true, desc = "Run HTTP request from visual selection" })

vim.api.nvim_create_user_command("PostEnv", function(args)
  if args.args and args.args ~= "" then
    post.set_env(args.args)
  else
    post.list_envs()
  end
end, { nargs = "?", desc = "Set or list environments" })

vim.api.nvim_create_user_command("PostSessions", function()
  post.list_sessions()
end, { desc = "List stored sessions" })

vim.api.nvim_create_user_command("PostSessionDelete", function(args)
  post.delete_session(args.args)
end, { nargs = 1, desc = "Delete a session by name" })

vim.api.nvim_create_user_command("PostSessionGC", function()
  post.session_gc()
end, { desc = "Run session garbage collection" })

vim.api.nvim_create_user_command("PostCancel", function()
  post.cancel()
end, { desc = "Cancel all active HTTP requests" })

-- Visual mode keymap for running selected request
vim.api.nvim_set_keymap("v", "<leader>pr", ":PostRunVisual<CR>", { noremap = true, silent = true, desc = "Run selected HTTP request" })
-- Normal mode keymap for running buffer request
vim.api.nvim_set_keymap("n", "<leader>pr", ":PostRun<CR>", { noremap = true, silent = true, desc = "Run HTTP request in buffer" })

-- Register nvim-cmp source
local ok, completion = pcall(require, "post-nvim.completion")
if ok then
  completion.register()
end
