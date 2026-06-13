return {
  -- GitHub Copilot (inline completion) 
  {
    "github/copilot.vim",
    lazy = false,
    init = function()
      -- disable default <Tab> mapping
      vim.g.copilot_no_tab_map = true

      -- use <C-s> to accept Copilot completion
      vim.keymap.set("i", "<C-s>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
        silent = true,
      })
    end,
  },
  -- GitHub Copilot Chat (chat-based interaction)
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {
      --model = "gpt-4.1",        -- will map to what Copilot exposes for your plan/settings
      temperature = 0.1,
      auto_insert_mode = true,
      window = {
        layout = "vertical",
        width = 0.45,
      },
    },
    keys = {
      { "<leader>cc", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat: Toggle" },
      { "<leader>co", "<cmd>CopilotChatOpen<cr>",   desc = "CopilotChat: Open" },
      { "<leader>cx", "<cmd>CopilotChatReset<cr>",  desc = "CopilotChat: Reset" },

      -- handy built-in prompts (you can add more)
      { "<leader>ce", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat: Explain" },
      { "<leader>cr", "<cmd>CopilotChatReview<cr>",  desc = "CopilotChat: Review" },
      { "<leader>cf", "<cmd>CopilotChatFix<cr>",     desc = "CopilotChat: Fix" },
      { "<leader>ct", "<cmd>CopilotChatTests<cr>",   desc = "CopilotChat: Tests" },
    },
  },
}
