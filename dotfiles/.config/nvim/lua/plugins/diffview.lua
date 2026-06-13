return {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },

    keys = {
        { "<leader>dv", "<cmd>DiffviewOpen<CR>", desc = "Open Diffview" },
        { "<leader>dc", "<cmd>DiffviewClose<CR>", desc = "Close Diffview" },
        { "<leader>dh", "<cmd>DiffviewFileHistory %<CR>", desc = "File History" },
    },
}
