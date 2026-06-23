-- Font settings
--vim.opt.guifont = "SauceCodePro NF:h10" -- Set the GUI font to "SauceCodePro NF" with a size of 10
--vim.opt.guifont = "Noto Mono:h12" -- Set the GUI font to "Noto Mono" with a size of 12
vim.opt.guifont = "FiraCode Nerd Font:h12" -- Set the GUI font to "FiraCode Nerd Font" with a size of 10

-- Theme settings
vim.cmd.colorscheme("peachpuff") -- Set the colorscheme to "peachpuff"

-- Line numbers
vim.opt.number = true -- Enable absolute line numbers
--vim.opt.relativenumber = true -- Enable relative line numbers

-- Word wrap settings
vim.opt.wrap = true -- Enable line wrapping
vim.opt.linebreak = true -- Break lines at word boundaries
vim.opt.breakindent = true -- Preserve indentation on wrapped lines

-- Indentation settings
vim.opt.tabstop = 4 -- A TAB character looks like 4 spaces
vim.opt.expandtab = true -- Pressing the TAB key will insert spaces instead of a TAB character
vim.opt.softtabstop = 4 -- Number of spaces inserted instead of a TAB character
vim.opt.shiftwidth = 4 -- Number of spaces inserted when indenting

-- file diff options
vim.opt.diffopt:append("vertical") -- Show diffs in vertical splits
vim.opt.fillchars:append { diff = "╱" } -- Use a diagonal line to indicate deleted lines in diffs

-- Load configurations
require("config.keymaps")
require("config.lazy")

