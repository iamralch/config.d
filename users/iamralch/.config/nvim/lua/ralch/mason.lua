---@type LazySpec
return {
  -- Use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- install language servers
        "typescript-language-server",
        "lua-language-server",
        "bash-language-server",
        "rust-analyzer",
        "terraform-ls",
        "shellcheck",
        "superhtml",
        "harper-ls",
        "gofumpt",
        "gopls",
        "zls",

        -- install formatters
        "markdownlint-cli2",
        "golangci-lint",
        "prettierd",
        "yamlfmt",
        "jupytext",
        "hadolint",
        "sqlfluff",
        "stylua",
        "hclfmt",
        "vale",

        -- install debuggers
        "debugpy",
        "delve",

        -- install any other package
        "tree-sitter-cli",
        "goimports",
        "sqlfluff",
        "tectonic",
        "impl",
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "latex",
        "lua",
        "norg",
        "regex",
        "svelte",
        "typst",
        "vim",
        "vue",
      },
    },
  },
  {
    "nvimtools/none-ls.nvim",
    opts = function(_, opts)
      -- Opts variable is the default configuration table for the setup function call
      local null_ls = require "null-ls"

      -- Check supported formatters and linters
      -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/formatting
      -- https://github.com/nvimtools/none-ls.nvim/tree/main/lua/null-ls/builtins/diagnostics

      -- Only insert new sources, do not replace the existing ones
      opts.sources = require("astrocore").list_insert_unique(opts.sources, {
        -- formatting
        null_ls.builtins.formatting.buf,
        null_ls.builtins.formatting.shfmt,
        null_ls.builtins.formatting.hclfmt,
        null_ls.builtins.formatting.yamlfmt,
        null_ls.builtins.formatting.sqlfluff,
        null_ls.builtins.formatting.stylua,
        null_ls.builtins.formatting.swiftlint,
        null_ls.builtins.formatting.prettierd,
        null_ls.builtins.formatting.gofumpt,
        null_ls.builtins.formatting.goimports,
        null_ls.builtins.formatting.terraform_fmt,
        -- diagnostics
        null_ls.builtins.diagnostics.buf,
        null_ls.builtins.diagnostics.zsh,
        null_ls.builtins.diagnostics.vale,
        null_ls.builtins.diagnostics.hadolint,
        null_ls.builtins.diagnostics.sqlfluff,
        null_ls.builtins.diagnostics.swiftlint,
        null_ls.builtins.diagnostics.todo_comments,
        null_ls.builtins.diagnostics.markdownlint_cli2,
      })
    end,
  },
}
