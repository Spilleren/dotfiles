local function cwd_arg(opts)
  return opts.args ~= "" and opts.args or nil
end

return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = { "Telescope", "Files", "AllFiles", "Rg" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    config = function()
      local telescope = require("telescope")
      local builtin = require("telescope.builtin")

      telescope.setup({
        defaults = {
          path_display = { "smart" },
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
        pickers = {
          find_files = {
            hidden = true,
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
          },
        },
      })

      pcall(telescope.load_extension, "fzf")

      vim.api.nvim_create_user_command("Files", function(opts)
        builtin.find_files({
          cwd = cwd_arg(opts),
          hidden = true,
          find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        })
      end, { bang = true, nargs = "?", complete = "dir" })

      vim.api.nvim_create_user_command("AllFiles", function(opts)
        builtin.find_files({
          cwd = cwd_arg(opts),
          hidden = true,
          no_ignore = true,
          find_command = { "rg", "--files", "--hidden", "--no-ignore", "--glob", "!**/.git/*" },
        })
      end, { bang = true, nargs = "?", complete = "dir" })

      vim.api.nvim_create_user_command("Rg", function(opts)
        builtin.live_grep({
          default_text = opts.args ~= "" and opts.args or nil,
        })
      end, { nargs = "*" })
    end,
  },
}
