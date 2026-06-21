return {
  "yousefakbar/notmuch.nvim",
  cond = function()
    return vim.fn.executable("epel") == 1
  end,
  cmd = { "Notmuch", "NmSearch", "Inbox", "ComposeMail" },
  init = function()
    local epel_bin = vim.fn.expand("~/.local/lib/epel/bin")
    vim.env.PATH = epel_bin .. ":" .. vim.env.PATH
  end,
  opts = {
    maildir_sync_cmd = "epel sync",
    render_html_body = true,
  },
  keys = {
    { "<leader>nm", "<cmd>Notmuch<CR>", desc = "Open Notmuch mail" },
  },
}
