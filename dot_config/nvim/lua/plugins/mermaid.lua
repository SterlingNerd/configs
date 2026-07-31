--[[
Mermaid rendering for render-markdown.nvim

This spec configures:
- render-markdown.nvim (markdown rendering with code blocks, headings, etc.)
- cavanaug/render-markdown-mermaid.nvim (mermaid diagram rendering)
- Dependencies: nvim-treesitter (markdown parser), nvim-web-devicons
- Integrates mermaid_sanitize utility to strip unsupported mermaid syntax:
  %%{init...}%%, style/classDef, :::class, and collapses extra blank lines
- Patches render-markdown-mermaid.renderer.render to sanitize before rendering
  and clear plugin cache on load so old failures don't persist
]]--

local mermaid_sanitize = require("utils.mermaid_sanitize")

return {
  -- render-markdown.nvim: beautiful markdown rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    name = "render-markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown", "mdx", "markdown.mdx", "Avante", "codecompanion" },
    opts = {
      enabled = true,
      file_types = { "markdown", "mdx", "markdown.mdx", "Avante", "codecompanion" },
      anti_conceal = { enabled = true, ignore = { code_background = true, sign = true } },
      heading = {
        enabled = true, sign = true, position = "overlay",
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        signs = { "󰫎 " }, width = "full", left_margin = 0, left_pad = 0, right_pad = 0, min_width = 0,
        border = false, border_virtual = false, border_prefix = false,
        above = "▄", below = "▀",
        backgrounds = { "RenderMarkdownH1Bg", "RenderMarkdownH2Bg", "RenderMarkdownH3Bg", "RenderMarkdownH4Bg", "RenderMarkdownH5Bg", "RenderMarkdownH6Bg" },
        foregrounds = { "RenderMarkdownH1", "RenderMarkdownH2", "RenderMarkdownH3", "RenderMarkdownH4", "RenderMarkdownH5", "RenderMarkdownH6" },
      },
      code = {
        enabled = true, sign = true, style = "full", position = "left", language_pad = 0,
        disable_background = { "diff" }, width = "full", left_margin = 0, left_pad = 0, right_pad = 0, min_width = 0,
        border = "thin", above = "▄", below = "▀",
        highlight = "RenderMarkdownCode", highlight_inline = "RenderMarkdownCodeInline",
      },
      dash = { enabled = true, icon = "─", width = "full", highlight = "RenderMarkdownDash" },
      bullet = { enabled = true, icons = { "●", "○", "◆", "◇" }, ordered_icons = { "1.", "2.", "3.", "4.", "5.", "6.", "7.", "8.", "9." }, left_pad = 0, right_pad = 1, highlight = "RenderMarkdownBullet" },
      checkbox = { enabled = true, unchecked = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked" }, checked = { icon = "󰱒 ", highlight = "RenderMarkdownChecked" }, custom = { todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" } } },
      quote = { enabled = true, icon = "▋", repeat_linebreak = true, highlight = "RenderMarkdownQuote" },
      pipe_table = { enabled = true, preset = "round", style = "full", cell = "padded", alignment_indicator = "━", border = { "┌","┬","┐", "├","┼","┤", "└","┴","┘" }, head = "RenderMarkdownTableHead", row = "RenderMarkdownTableRow", filler = "RenderMarkdownTableFill" },
      callout = {
        note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
        tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
        important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
        warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
        caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
        abstract = { raw = "[!ABSTRACT]", rendered = "󰨸 Abstract", highlight = "RenderMarkdownInfo" },
        summary = { raw = "[!SUMMARY]", rendered = "󰨸 Summary", highlight = "RenderMarkdownInfo" },
        tldr = { raw = "[!TLDR]", rendered = "󰨸 TL;DR", highlight = "RenderMarkdownInfo" },
        info = { raw = "[!INFO]", rendered = "󰋽 Info", highlight = "RenderMarkdownInfo" },
        todo = { raw = "[!TODO]", rendered = "󰗡 Todo", highlight = "RenderMarkdownInfo" },
        hint = { raw = "[!HINT]", rendered = "󰌶 Hint", highlight = "RenderMarkdownSuccess" },
        success = { raw = "[!SUCCESS]", rendered = "󰄬 Success", highlight = "RenderMarkdownSuccess" },
        check = { raw = "[!CHECK]", rendered = "󰄬 Check", highlight = "RenderMarkdownSuccess" },
        done = { raw = "[!DONE]", rendered = "󰄬 Done", highlight = "RenderMarkdownSuccess" },
        question = { raw = "[!QUESTION]", rendered = "󰋗 Question", highlight = "RenderMarkdownWarn" },
        faq = { raw = "[!FAQ]", rendered = "󰋗 FAQ", highlight = "RenderMarkdownWarn" },
        attention = { raw = "[!ATTENTION]", rendered = "󰀪 Attention", highlight = "RenderMarkdownWarn" },
        failure = { raw = "[!FAILURE]", rendered = "󰅖 Failure", highlight = "RenderMarkdownError" },
        fail = { raw = "[!FAIL]", rendered = "󰅖 Fail", highlight = "RenderMarkdownError" },
        missing = { raw = "[!MISSING]", rendered = "󰅖 Missing", highlight = "RenderMarkdownError" },
        danger = { raw = "[!DANGER]", rendered = "󰀪 Danger", highlight = "RenderMarkdownError" },
        error = { raw = "[!ERROR]", rendered = "󰅖 Error", highlight = "RenderMarkdownError" },
        bug = { raw = "[!BUG]", rendered = "󰃤 Bug", highlight = "RenderMarkdownError" },
        example = { raw = "[!EXAMPLE]", rendered = "󰉹 Example", highlight = "RenderMarkdownHint" },
        quote = { raw = "[!QUOTE]", rendered = "󰆓 Quote", highlight = "RenderMarkdownQuote" },
        cite = { raw = "[!CITE]", rendered = "󰆓 Cite", highlight = "RenderMarkdownQuote" },
      },
      link = { enabled = true, image = "󰥶 ", email = "󰀓 ", hyperlink = "󰌹 ", highlight = "RenderMarkdownLink", wiki = { icon = "󱗖 ", highlight = "RenderMarkdownWikiLink" }, custom = {} },
      sign = { enabled = true, highlight = "RenderMarkdownSign" },
      inline_highlight = { enabled = true, highlight = "RenderMarkdownInlineHighlight" },
      indent = { enabled = true, per_level = 2, skip_level = 1, skip_heading = true, icon = "│", highlight = "RenderMarkdownIndent" },
      html = { enabled = true, comment = { conceal = true, highlight = "RenderMarkdownHtmlComment" } },
      win_options = { conceallevel = { default = 2, rendered = 3 }, concealcursor = { default = "", rendered = "" } },
      overrides = { buftype = { nofile = { code = { style = "normal" } } }, filetype = { Avante = { heading = { enabled = false } } } },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)

      -- Patch render-markdown-mermaid renderer to sanitize before rendering and clear cache
      local ok, mermaid = pcall(require, "render-markdown-mermaid.renderer")
      if ok and mermaid and mermaid.render then
        local orig_render = mermaid.render
        mermaid.render = function(source, opts, cb)
          local ok_san, sanitized = pcall(mermaid_sanitize.safe_sanitize, source)
          local src = ok_san and sanitized or source
          if mermaid.cache then mermaid.cache = {} end
          return orig_render(src, opts, cb)
        end
      end
    end,
  },

  -- cavanaug/render-markdown-mermaid.nvim: Mermaid diagram rendering for render-markdown
  {
    "cavanaug/render-markdown-mermaid.nvim",
    dependencies = {
      "MeanderingProgrammer/render-markdown.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    build = ":TSUpdate markdown markdown_inline",
    ft = { "markdown", "mdx", "markdown.mdx" },
    opts = {
      placement = "above",
      mode = "unicode",
    },
    config = function(_, opts)
      require("render-markdown-mermaid").setup(opts)

      -- Re-apply renderer patch after plugin loads (in case it reloads)
      vim.defer_fn(function()
        local ok, mermaid = pcall(require, "render-markdown-mermaid.renderer")
        if ok and mermaid and mermaid.render then
          local orig_render = mermaid.render
          mermaid.render = function(source, opts, cb)
            local ok_san, sanitized = pcall(mermaid_sanitize.safe_sanitize, source)
            local src = ok_san and sanitized or source
            if mermaid.cache then mermaid.cache = {} end
            return orig_render(src, opts, cb)
          end
        end
      end, 0)
    end,
  },

  -- Ensure treesitter has markdown parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { "markdown", "markdown_inline", "mermaid" })
    end,
  },
}