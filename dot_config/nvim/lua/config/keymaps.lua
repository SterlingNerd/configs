-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ctrl+C for copy (Visual mode)
vim.keymap.set("v", "<C-c>", '"+y', { desc = "Copy to clipboard" })
vim.keymap.set("v", "<C-S-c>", '"+y', { desc = "Copy to clipboard" })

-- Ctrl+V for paste (Normal mode uses p, Insert mode uses <C-r>)
vim.keymap.set("n", "<C-v>", '"+p', { desc = "Paste from clipboard" })
vim.keymap.set("i", "<C-v>", '<C-r>+', { desc = "Paste from clipboard in insert mode" })

-- Shift+Ctrl+V for paste
vim.keymap.set("n", "<C-S-v>", '"+p', { desc = "Paste from clipboard" })
vim.keymap.set("i", "<C-S-v>", '<C-r>+', { desc = "Paste from clipboard in insert mode" })
