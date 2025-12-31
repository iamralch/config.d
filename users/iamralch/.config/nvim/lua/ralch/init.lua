require("lazy").setup({
  {
    "AstroNvim/AstroNvim",
    version = "^5", -- Remove version tracking to elect for nightly AstroNvim
    import = "astronvim.plugins",
    opts = { -- AstroNvim options must be set here with the `import` key
      mapleader = " ", -- This ensures the leader key must be configured before Lazy is set up
      maplocalleader = ",", -- This ensures the local leader key must be configured before Lazy is set up
      icons_enabled = true, -- Set to false to disable icons (if no Nerd Font is available)
      pin_plugins = nil, -- Default will pin plugins when tracking `version` of AstroNvim, set to true/false to override
      update_notifications = true, -- Enable/disable notification about running `:Lazy update` twice to update pinned plugins
    },
  },
  {
    "AstroNvim/astroui",
    ---@type AstroUIOpts
    opts = {
      colorscheme = "catppuccin",
    },
  },
  {
    "AstroNvim/astrocore",
    ---@type AstroCoreOpts
    opts = {
      options = {
        g = {
          -- Use nix-managed Python
          python3_host_prog = vim.env.DEVPOD ~= "true" and "/run/current-system/sw/bin/python3" or nil,
        },
      },
    },
  },
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
  { import = "ralch.mason" },
  { import = "ralch.plugins" },
} --[[@as LazySpec]], {
  ui = { backdrop = 100 },
  performance = {
    rtp = {
      -- disable some plugins, add more to your liking
      disabled_plugins = {
        "gzip",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "zipPlugin",
      },
    },
  },
} --[[@as LazyConfig]])
