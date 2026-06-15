return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "v0.2.0",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		},
		config = function()
            require('telescope').setup({
                pickers = {
                    --find_files = {
                    --    theme = "ivy"
                    --},
                    live_grep = {
                        additional_args = function()
                            return {"--hidden", "--glob", "!**/.git/*"}
                        end,
                    },
                },
                --extensions = {
                --    fzf = {}
                --},
            })
			
			--require('telescope').load_extension('fzf')

			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Telescope find files" })
			vim.keymap.set("n", "<leader>fa", function()
				builtin.find_files({ no_ignore = true, hidden = true })
			end, { desc = "Telescope find all files (hidden + ignored)" })
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope live grep" })
			vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
			vim.keymap.set("n", "<leader>fn", function()
				builtin.find_files({
					cwd = vim.fn.stdpath("config"),
					follow = true,
					hidden = true,
					no_ignore = true,
				})
			end, { desc = "Telescope find neovim config" })
		end,
	},
}
