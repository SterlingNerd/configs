return {
  "nvim-telekasten/telekasten.nvim",
  opts = {
    home = vim.fn.expand("~/notes"),
    journals = "daily",
    templates = "templates",
    template = "templates/daily.md",
  },
  keys = {
    { "<leader>tn", "<cmd>Telekasten new<cr>", desc = "New note" },
    { "<leader>tf", "<cmd>Telekasten find<cr>", desc = "Find notes" },
    { "<leader>ts", "<cmd>Telekasten search<cr>", desc = "Search notes" },
    { "<leader>td", "<cmd>Telekasten today<cr>", desc = "Today's daily note" },
    { "<leader>tw", "<cmd>Telekasten thisweek<cr>", desc = "This week's note" },
    { "<leader>tb", "<cmd>Telekasten backlinks<cr>", desc = "Backlinks" },
    { "<leader>tl", "<cmd>Telekasten links<cr>", desc = "Find friends" },
  },
}
