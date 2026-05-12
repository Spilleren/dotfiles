vim.filetype.add({
  extension = {
    tf = "terraform",
    tfvars = "terraform-vars",
    sh = "sh",
    bash = "sh",
    zsh = "zsh",
  },
  pattern = {
    [".*%.env"] = "sh",
  }
})

vim.diagnostic.config({
  severity_sort = true,
  virtual_text = {
    spacing = 4,
    source = "if_many",
  },
  float = {
    border = "rounded",
    source = true,
  },
  signs = true,
  underline = true,
})

local function root_or_current(markers)
  return function(bufnr, on_dir)
    local name = vim.api.nvim_buf_get_name(bufnr)
    local root = vim.fs.root(bufnr, markers)

    if not root and name ~= "" then
      root = vim.fs.dirname(name)
    end

    if root then
      on_dir(root)
    end
  end
end

local function first_match(patterns)
  for _, pattern in ipairs(patterns) do
    local matches = vim.fn.glob(pattern, false, true)
    table.sort(matches)
    if #matches > 0 then
      return matches[#matches]
    end
  end
end

local function csharp_root(bufnr, on_dir)
  local name = vim.api.nvim_buf_get_name(bufnr)
  local start = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()

  local function find_root(match)
    local markers = vim.fs.find(match, { path = start, upward = true, type = "file", limit = 1 })
    return markers[1] and vim.fs.dirname(markers[1]) or nil
  end

  local root = find_root(function(marker)
    return marker:match("%.sln$") ~= nil or marker:match("%.slnx$") ~= nil
  end)
    or find_root(function(marker)
      return marker == "global.json" or marker == "Directory.Build.props" or marker == "Directory.Build.targets"
    end)
    or find_root(function(marker)
      return marker:match("%.csproj$") ~= nil
    end)
    or vim.fs.root(start, ".git")

  if root then
    on_dir(root)
  elseif start then
    on_dir(start)
  end
end

local sep = package.config:sub(1, 1)
local home = vim.fn.expand("~")
local roslyn = first_match({
  table.concat({ home, ".vscode", "extensions", "ms-dotnettools.csharp-*", ".roslyn", "Microsoft.CodeAnalysis.LanguageServer.exe" }, sep),
  table.concat({ home, "AppData", "Local", "Microsoft", "VisualStudio", "*", "Extensions", "**", "Microsoft.CodeAnalysis.LanguageServer.exe" }, sep),
  table.concat({ "C:", "Program Files", "Microsoft Visual Studio", "2022", "*", "Common7", "IDE", "CommonExtensions", "Microsoft", "VBCSharp", "LanguageServices", "Microsoft.CodeAnalysis.LanguageServer.exe" }, sep),
})

local roslyn_log_dir = table.concat({ vim.fn.stdpath("state"), "roslyn-lsp" }, sep)
vim.fn.mkdir(roslyn_log_dir, "p")

local servers = {
  bashls = {
    cmd = { "bash-language-server", "start" },
    filetypes = {"sh", "bash", "zsh" },
    root_dir = root_or_current({ ".git" }),
    settings = {
      bashIde = {
        globPattern ="*@(.sh|.inc|.bash|.command)",
      },
    },
  },

  gopls = {
    cmd = { "gopls" },
    filetypes = { "go", "gomod", "gowork", "gotmpl" },
    root_dir = root_or_current({ "go.work", "go.mod", ".git" }),
    settings = {
      gopls = {
        gofumpt = true,
        staticcheck = true,
        usePlaceholders = true,
        analyses = {
          unusedparams = true,
          unusedwrite = true,
        },
      },
    },
  },
  terraformls = {
    cmd = { "terraform-ls", "serve" },
    filetypes = { "terraform", "terraform-vars" },
    root_dir = root_or_current({ ".terraform", ".git" }),
  },
  roslyn = {
    cmd = roslyn
        and {
          roslyn,
          "--stdio",
          "--logLevel",
          "Information",
          "--telemetryLevel",
          "off",
          "--extensionLogDirectory",
          roslyn_log_dir,
          "--clientProcessId",
          tostring(vim.fn.getpid()),
          "--autoLoadProjects",
        }
      or { "Microsoft.CodeAnalysis.LanguageServer.exe", "--stdio" },
    filetypes = { "cs" },
    root_dir = csharp_root,
  },
}

local enabled = {}

for name, config in pairs(servers) do
  if vim.fn.executable(config.cmd[1]) == 1 then
    vim.lsp.config(name, config)
    table.insert(enabled, name)
  else
    vim.notify(("Skipping %s: %s is not executable"):format(name, config.cmd[1]), vim.log.levels.WARN)
  end
end

if #enabled > 0 then
  vim.lsp.enable(enabled)
end

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("native_lsp", { clear = true }),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    if client:supports_method("textDocument/completion", args.buf) then
      vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
    end

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
    end

    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    map("n", "gr", vim.lsp.buf.references, "References")
    map("n", "gI", vim.lsp.buf.implementation, "Go to implementation")
    map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
    map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
    map("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol")
    map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map({ "n", "v" }, "<leader>cf", function()
      vim.lsp.buf.format({ async = true })
    end, "Format")

    if vim.lsp.inlay_hint and client:supports_method("textDocument/inlayHint", args.buf) then
      map("n", "<leader>th", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = args.buf }), { bufnr = args.buf })
      end, "Toggle inlay hints")
    end
  end,
})
