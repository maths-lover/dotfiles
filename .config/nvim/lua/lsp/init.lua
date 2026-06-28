-- lua/lsp/init.lua - modular LSP core.
-- Shared setup (diagnostics, capabilities, on-attach keymaps) plus a small loader
-- that aggregates every stack module in lua/lsp/langs/ and drives Mason.
--
-- TO ADD A TECH STACK: drop lua/lsp/langs/<name>.lua returning a table with any
-- of these fields (all optional):
--
--   servers = {
--     <lsp_name> = {
--       system   = "<exe>",     -- comes from PATH (uv/brew), not Mason; enabled
--                               -- only when <exe> is executable. Omit = via Mason.
--       settings = { ... },     -- passed to vim.lsp.config
--       before_init = function(params, config) ... end,
--       on_attach   = function(client, bufnr) ... end,
--     },
--   },
--   tools   = { "stylua", ... },  -- formatters/linters to install via Mason
--   plugins = { <lazy specs> },   -- extra plugins for this stack (e.g. flutter-tools)
--   setup   = function() ... end, -- any custom wiring run during LSP setup
--
-- Mason-managed servers are auto-enabled; `system` servers are enabled here and
-- excluded from Mason's auto-enable. Formatting itself lives in conform (see
-- lua/plugins/formatting.lua); `tools` just guarantees the binaries exist.

local M = {}

-- Discover and require every module in lua/lsp/langs/ (sorted, deterministic).
local function langs()
  if M._langs then return M._langs end
  local out = {}
  local dir = vim.fn.stdpath("config") .. "/lua/lsp/langs"
  local names = {}
  for name, _ in vim.fs.dir(dir) do
    if name:match("%.lua$") then names[#names + 1] = name:gsub("%.lua$", "") end
  end
  table.sort(names)
  for _, n in ipairs(names) do
    local ok, mod = pcall(require, "lsp.langs." .. n)
    if ok and type(mod) == "table" then
      mod._name = n
      out[#out + 1] = mod
    else
      vim.notify("lsp: failed to load stack '" .. n .. "': " .. tostring(mod), vim.log.levels.WARN)
    end
  end
  M._langs = out
  return out
end
M.languages = langs

-- Lazy plugin specs declared by stack modules (gathered by lua/plugins/lsp.lua).
function M.plugin_specs()
  local specs = {}
  for _, lang in ipairs(langs()) do
    for _, p in ipairs(lang.plugins or {}) do specs[#specs + 1] = p end
  end
  return specs
end

-- Buffer-local keymaps applied whenever any server attaches.
local function on_attach(ev)
  local buf = ev.buf
  local ok_fzf, fzf = pcall(require, "fzf-lua")
  local function map(keys, fn, desc, mode)
    vim.keymap.set(mode or "n", keys, fn, { buffer = buf, desc = "LSP: " .. desc })
  end
  map("gd", ok_fzf and fzf.lsp_definitions or vim.lsp.buf.definition, "Definition")
  map("gr", ok_fzf and fzf.lsp_references or vim.lsp.buf.references, "References")
  map("gI", ok_fzf and fzf.lsp_implementations or vim.lsp.buf.implementation, "Implementation")
  map("gy", ok_fzf and fzf.lsp_typedefs or vim.lsp.buf.type_definition, "Type definition")
  map("gD", vim.lsp.buf.declaration, "Declaration")
  map("K", function() vim.lsp.buf.hover() end, "Hover")
  map("<leader>cr", vim.lsp.buf.rename, "Rename")
  map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "v" })
  map("<leader>cs", ok_fzf and fzf.lsp_document_symbols or vim.lsp.buf.document_symbol, "Symbols")
  if vim.lsp.inlay_hint then
    map("<leader>ci", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
    end, "Toggle inlay hints")
  end
end

function M.setup()
  -- Diagnostics UI
  vim.diagnostic.config({
    severity_sort = true,
    float = { border = "rounded", source = true },
    underline = { severity = vim.diagnostic.severity.ERROR },
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = " ",
        [vim.diagnostic.severity.WARN] = " ",
        [vim.diagnostic.severity.INFO] = " ",
        [vim.diagnostic.severity.HINT] = " ",
      },
    },
    virtual_text = { spacing = 2, source = "if_many" },
  })

  -- Capabilities: blink.cmp extends the defaults for richer completion
  local caps = vim.lsp.protocol.make_client_capabilities()
  local ok_blink, blink = pcall(require, "blink.cmp")
  if ok_blink then caps = blink.get_lsp_capabilities(caps) end
  vim.lsp.config("*", { capabilities = caps })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
    callback = on_attach,
  })

  -- Aggregate servers + tools from every stack module.
  local mason_lsp, mason_tools = {}, {}
  -- stylua is a formatter (lspconfig ships a stray "stylua --lsp"); marksman is
  -- replaced by markdown_oxide. Never auto-start either as a language server.
  local exclude = { "stylua", "marksman" }
  for _, lang in ipairs(langs()) do
    for srv, cfg in pairs(lang.servers or {}) do
      vim.lsp.config(srv, {
        settings = cfg.settings,
        before_init = cfg.before_init,
        on_attach = cfg.on_attach,
      })
      if cfg.system then
        exclude[#exclude + 1] = srv -- never let Mason auto-enable a system server
        if vim.fn.executable(cfg.system) == 1 then vim.lsp.enable(srv) end
      else
        mason_lsp[#mason_lsp + 1] = srv
      end
    end
    for _, t in ipairs(lang.tools or {}) do mason_tools[#mason_tools + 1] = t end
    if type(lang.setup) == "function" then lang.setup() end
  end

  require("mason-lspconfig").setup({
    ensure_installed = mason_lsp,
    automatic_enable = { exclude = exclude },
  })
  require("mason-tool-installer").setup({ ensure_installed = mason_tools })
end

return M
