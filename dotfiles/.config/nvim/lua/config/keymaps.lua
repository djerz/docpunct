-- Map space to leader
-- Remove default behavior of space
vim.keymap.set('', '<Space>', '<Nop>', { noremap = true, silent = true })
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Map Esc to exit terminal mode
--vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]])
-- Map C-Space to exit terminal mode
vim.keymap.set('t', '<C-Space>', [[<C-\><C-n>]])

-- Mapping for diff navigation
vim.keymap.set("n", "<leader>h", "[c", { remap = true })
vim.keymap.set("n", "<leader>l", "]c", { remap = true })

-- Neovide zoom keymaps
if vim.g.neovide then
	vim.keymap.set({ "n", "v" }, "<C-+>", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>")
	vim.keymap.set({ "n", "v" }, "<C-->", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>")
	vim.keymap.set({ "n" , "v" }, "<C-0>", ":lua vim.g.neovide_scale_factor = 1<CR>")
	vim.keymap.set({ "n", "v" }, "<C-ScrollWheelUp>", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor + 0.1<CR>")
	vim.keymap.set({ "n", "v" }, "<C-ScrollWheelDown>", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor - 0.1<CR>")
end
