return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-contrib/nvim-ginkgo",
  },
  config = function()
    require("neotest").setup {
      adapters = {
        require "neotest-ginkgo",
      },
    }
  end,
}
