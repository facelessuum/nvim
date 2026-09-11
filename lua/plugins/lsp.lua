-- Advertise Blink's completion support, including resolved import edits.
vim.lsp.config("*", {
  capabilities = require("blink.cmp").get_lsp_capabilities(),
})

-- Preserve lspconfig's monorepo root detection and Deno exclusions.
local project_root = vim.lsp.config.ts_ls.root_dir
local native_bins = {}
local function native_compiler(root)
  local manifest = root .. "/node_modules/typescript/package.json"
  local ok, package = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(manifest), "\n"))
  end)
  local major = ok and type(package) == "table" and tonumber((package.version or ""):match("^(%d+)"))
  local bin = root .. "/node_modules/.bin/tsc"
  if major and major >= 7 and vim.fn.executable(bin) == 1 then
    return bin
  end
end

vim.lsp.config("tsc", {
  root_dir = function(bufnr, on_dir)
    project_root(bufnr, function(root)
      local bin = native_compiler(root)
      if bin then
        native_bins[root] = bin
        on_dir(root)
      end
    end)
  end,
  cmd = function(dispatchers, config)
    return vim.lsp.rpc.start({ assert(native_bins[config.root_dir]), "--lsp", "--stdio" }, dispatchers)
  end,
})

vim.lsp.config("ts_ls", {
  root_dir = function(bufnr, on_dir)
    project_root(bufnr, function(root)
      if not native_compiler(root) then
        on_dir(root)
      end
    end)
  end,
  init_options = {
    preferences = {
      includeCompletionsForModuleExports = true,
      includeCompletionsForImportStatements = true,
      includeCompletionsWithInsertText = true,
      includeAutomaticOptionalChainCompletions = true,
    },
  },
})

vim.lsp.enable({ "tsc", "ts_ls" })

-- Supply syntax diagnostics for JSON and JSONC, including standalone files.
vim.lsp.config("jsonls", {
  settings = { json = { validate = { enable = true } } },
})
vim.lsp.enable("jsonls")

-- Error Lens uses diagnostics from these servers, not the formatters.
-- Install the corresponding executables through Mason (see README).
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      workspace = { checkThirdParty = false },
    },
  },
})
vim.lsp.config("yamlls", {
  settings = { yaml = { validate = true } },
})
vim.lsp.enable({
  "lua_ls", "html", "cssls", "yamlls", "taplo", "bashls", "marksman",
  "gopls", "rust_analyzer", "clangd", "intelephense", "ruby_lsp",
})

-- Use the project's environment even when it was not activated before nvim.
local pyright_attach = vim.lsp.config.pyright.on_attach
vim.lsp.config("pyright", {
  handlers = { ["textDocument/publishDiagnostics"] = require("core.python_diagnostics").publish },
  before_init = function(_, config)
    local python = config.settings.python
    if python.pythonPath then return end
    python.pythonPath = require("core.python_environment").find(config.root_dir)
  end,
  on_attach = function(client, bufnr)
    if pyright_attach then pyright_attach(client, bufnr) end
    vim.api.nvim_buf_create_user_command(bufnr, "LspPyrightSetPythonPath", function(command)
      for _, attached in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        if attached.name == "pyright" then
          attached.settings.python.pythonPath = command.args
          attached:notify("workspace/didChangeConfiguration", { settings = attached.settings })
        elseif attached.name == "ty" then
          -- Rebuild ty's module index when switching environments.
          local config = vim.deepcopy(attached.config)
          config.settings = vim.deepcopy(attached.settings)
          config.settings.ty.configuration.environment.python = command.args
          local buffers = vim.tbl_keys(attached.attached_buffers)
          for _, buffer in ipairs(buffers) do
            if vim.api.nvim_buf_is_valid(buffer) then vim.lsp.buf_detach_client(buffer, attached.id) end
          end
          attached:stop()
          local id = vim.lsp.start(config, { bufnr = bufnr, reuse_client = function() return false end })
          if id then
            for _, buffer in ipairs(buffers) do
              if buffer ~= bufnr and vim.api.nvim_buf_is_valid(buffer) then
                vim.lsp.buf_attach_client(buffer, id)
              end
            end
          end
        end
      end
    end, { nargs = 1, complete = "file", desc = "Select Python for diagnostics and completion" })
  end,
  settings = {
    python = {
      analysis = {
        autoImportCompletions = true,
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        -- Match Pylance defaults; ty indexes unopened files for completion.
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "off",
      },
    },
  },
})
vim.lsp.enable("pyright")

-- ty supplies indexed auto-imports for project code and installed packages.
-- Pyright remains responsible for diagnostics and the other language features.
vim.lsp.config("ty", {
  before_init = function(_, config)
    local settings = config.settings.ty
    settings.configuration = settings.configuration or {}
    settings.configuration.environment = settings.configuration.environment or {}
    settings.configuration.environment.python = settings.configuration.environment.python
      or vim.lsp.config.pyright.settings.python.pythonPath
      or require("core.python_environment").find(config.root_dir)
  end,
  on_attach = function(client)
    -- Keep navigation and hover responses from a single server.
    for _, capability in ipairs({
      "hoverProvider", "definitionProvider", "declarationProvider", "typeDefinitionProvider",
      "referencesProvider", "renameProvider", "documentSymbolProvider", "workspaceSymbolProvider",
      "signatureHelpProvider", "inlayHintProvider", "semanticTokensProvider", "codeActionProvider",
    }) do
      client.server_capabilities[capability] = nil
    end
  end,
  settings = {
    ty = {
      diagnosticMode = "off",
      showSyntaxErrors = false,
      completions = { autoImport = true, completeFunctionParentheses = false },
    },
  },
})
vim.lsp.enable("ty")
