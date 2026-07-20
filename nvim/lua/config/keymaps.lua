-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ctrl+C/V for copy/paste
vim.keymap.set("v", "<C-c>", '"+y', { desc = "Copy to clipboard" })
vim.keymap.set({ "n", "i" }, "<C-v>", '"+p', { desc = "Paste from clipboard" })

-- Shift+Ctrl+C/V also work
vim.keymap.set("v", "<C-S-c>", '"+y', { desc = "Copy to clipboard" })
vim.keymap.set({ "n", "i" }, "<C-S-v>", '"+p', { desc = "Paste from clipboard" })
