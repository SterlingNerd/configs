-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Ctrl+C/V for copy/paste
vim.keymap.set("v", "<C-c>", 'y', { desc = "Copy to clipboard" })
vim.keymap.set("n", "<C-v>", '"*p', { desc = "Paste from clipboard" })

-- Shift+Ctrl+C/V also work (pass through to terminal)
vim.keymap.set({ "n", "i" }, "<S-C-C>", "<Nop>")
vim.keymap.set({ "n", "i" }, "<S-C-V>", "<Nop>")


