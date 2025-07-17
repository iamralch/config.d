---@type LazySpec
return {
  -- AstroNvim Community
  "AstroNvim/astrocommunity",

  -- Completion
  { import = "astrocommunity.completion.copilot-lua" },
  { import = "astrocommunity.completion.minuet-ai-nvim" },

  -- Code Runner
  { import = "astrocommunity.code-runner.overseer-nvim" },

  -- Color Scheme
  { import = "astrocommunity.colorscheme.catppuccin" },

  -- Diagnostics
  { import = "astrocommunity.diagnostics.trouble-nvim" },

  -- Editing Support
  { import = "astrocommunity.editing-support.vector-code-nvim" },
  { import = "astrocommunity.editing-support.codecompanion-nvim" },

  -- LSP
  { import = "astrocommunity.lsp.lspsaga-nvim" },
  { import = "astrocommunity.lsp.nvim-lint" },

  -- Motion
  { import = "astrocommunity.motion.flash-nvim" },
  { import = "astrocommunity.motion.grapple-nvim" },
  { import = "astrocommunity.motion.marks-nvim" },
  { import = "astrocommunity.motion.mini-surround" },
  { import = "astrocommunity.motion.portal-nvim" },

  -- Git
  { import = "astrocommunity.git.mini-diff" },

  -- Language Packs
  { import = "astrocommunity.pack.ansible" },
  { import = "astrocommunity.pack.bash" },
  { import = "astrocommunity.pack.docker" },
  { import = "astrocommunity.pack.fish" },
  { import = "astrocommunity.pack.go" },
  { import = "astrocommunity.pack.harper" },
  { import = "astrocommunity.pack.hurl" },
  { import = "astrocommunity.pack.html-css" },
  { import = "astrocommunity.pack.json" },
  { import = "astrocommunity.pack.lua" },
  { import = "astrocommunity.pack.markdown" },
  { import = "astrocommunity.markdown-and-latex.render-markdown-nvim" },
  { import = "astrocommunity.pack.nix" },
  { import = "astrocommunity.pack.python" },
  { import = "astrocommunity.pack.rust" },
  { import = "astrocommunity.pack.sql" },
  { import = "astrocommunity.pack.swift" },
  { import = "astrocommunity.pack.terraform" },
  { import = "astrocommunity.pack.toml" },
  { import = "astrocommunity.pack.typescript" },
  { import = "astrocommunity.pack.xml" },
  { import = "astrocommunity.pack.yaml" },
  { import = "astrocommunity.pack.zig" },

  -- Scrolling
  { import = "astrocommunity.scrolling.neoscroll-nvim" },
  { import = "astrocommunity.scrolling.satellite-nvim" },

  -- Testing
  { import = "astrocommunity.test.neotest" },
  { import = "astrocommunity.test.nvim-coverage" },

  -- Utility
  { import = "astrocommunity.utility.noice-nvim" },

  -- Workflow
  { import = "astrocommunity.workflow.hardtime-nvim" },
  { import = "astrocommunity.workflow.precognition-nvim" },
}
