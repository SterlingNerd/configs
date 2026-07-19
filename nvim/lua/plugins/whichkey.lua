return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  opts = {
    preset = "modern",
    icons = {
      mappings = false, -- show text instead of icons
      keys = {
        up = "↑", down = "↓", left = "←", right = "→",
        enter = "↵", escape = "⎋", backspace = "⌫",
        tab = "⇥", s_tab = "⇤",
      },
    },
    triggers = {
      { "<leader>", mode = "n" },
      { "<leader>", mode = "v" },
    },
    windows = { border = "single" },
    layout = { spacing = 6 },
    expand = 0, -- expand groups on enter
    delay = 0, -- no delay showing the menu
  },
}
