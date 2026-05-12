local function preferred_shell()
  if vim.fn.executable("zsh") == 1 then
    return "zsh"
  end
  if vim.fn.executable("pwsh") == 1 then
    return "pwsh"
  end
  if vim.fn.executable("powershell") == 1 then
    return "powershell"
  end
  return vim.o.shell
end

local sep = package.config:sub(1, 1)
local function plugged(plugin)
  return table.concat({ vim.fn.expand("~"), ".vim", "plugged", plugin }, sep)
end

return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      terminal_colors = true,
      contrast = "soft",
    },
    config = function(_, opts)
      vim.opt.background = "dark"
      require("gruvbox").setup(opts)
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
      },
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeFocus", "NvimTreeToggle", "NvimTreeFindFile" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function(data)
          if vim.fn.isdirectory(data.file) == 1 then
            vim.cmd.cd(data.file)
            require("nvim-tree.api").tree.open()
          end
        end,
      })
    end,
    opts = {
      view = {
        width = 45,
      },
      renderer = {
        group_empty = true,
      },
      update_focused_file = {
        enable = true,
      },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = { "<F12>" },
    opts = {
      shell = preferred_shell(),
      direction = "float",
      size = 20,
    },
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    lazy = false,
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = {
        mode = "buffers",
        separator_style = "sloped",
        always_show_bufferline = true,
        show_buffer_icons = true,
        diagnostics = "nvim_lsp",
        close_command = function(bufnum)
          local bufs = vim.fn.getbufinfo({ buflisted = 1 })
          if #bufs > 1 then
            vim.cmd("BufferLineCycleNext")
          end
          vim.cmd("bd " .. bufnum)
        end,
      },
    },
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "tpope/vim-surround",
    event = "VeryLazy",
  },
  {
    "justinmk/vim-sneak",
    dir = plugged("vim-sneak"),
    keys = { "s", "S" },
    cond = function()
      return vim.fn.isdirectory(plugged("vim-sneak")) == 1
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
}
