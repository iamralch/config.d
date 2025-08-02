---@type LazySpec
return {
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            "██████╗  █████╗ ██╗      ██████╗██╗  ██╗",
            "██╔══██╗██╔══██╗██║     ██╔════╝██║  ██║",
            "██████╔╝███████║██║     ██║     ███████║",
            "██╔══██╗██╔══██║██║     ██║     ██╔══██║",
            "██║  ██║██║  ██║███████╗╚██████╗██║  ██║",
            "╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝",
          }, "\n"),
        },
        sections = {
          { section = "header" },
          { section = "startup" },
        },
      },
    },
  },
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "nvim-contrib/nvim-snippets",
    },
    config = function(plugin, opts)
      -- include the default astronvim config that calls the setup call
      require "astronvim.plugins.configs.luasnip"(plugin, opts)
      -- load snippets paths
      require("luasnip.loaders.from_vscode").lazy_load {
        paths = { vim.fn.stdpath "data" .. "/lazy/nvim-snippets/src/snippets" },
      }
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    opts = {
      strategies = {
        chat = {
          adapter = {
            name = "copilot",
            model = "claude-opus-4",
          },
        },
        inline = {
          adapter = {
            name = "copilot",
            model = "claude-sonnet-4",
          },
        },
        cmd = {
          adapter = {
            name = "copilot",
            model = "claude-sonnet-3-7-latest",
          },
        },
      },
    },
  },
}
