-- Shared helpers for the JD shortcodes and filter.
-- Data lives in <project>/_data/*.yml; brand colors live in <project>/styles.scss.

local M = {}

local stringify = pandoc.utils.stringify

-- Project root: prefer Quarto's API, fall back to two levels above this script.
local function project_dir()
  if quarto.project and quarto.project.directory then
    return quarto.project.directory
  end
  return quarto.utils.resolve_path("../..")
end

local function read_file(path)
  local f = io.open(path, "rb")
  if not f then
    error("[jd] cannot open " .. path)
  end
  local txt = f:read("a")
  f:close()
  return txt
end

local cache = {}

-- Parse a YAML file through pandoc's metadata reader (no extra Lua deps).
function M.data(name)
  if cache[name] == nil then
    local path = pandoc.path.join({ project_dir(), "_data", name .. ".yml" })
    local txt = read_file(path)
    cache[name] = pandoc.read("---\n" .. txt .. "\n---\n", "markdown").meta
  end
  return cache[name]
end

-- Brand colors are defined once in styles.scss ($jd-primary, $jd-secondary).
function M.colors()
  if cache.colors == nil then
    local scss = read_file(pandoc.path.join({ project_dir(), "styles.scss" }))
    local function grab(name)
      local hex = scss:match("%$" .. name .. "%s*:%s*#(%x%x%x%x%x%x)")
      if not hex then
        error("[jd] $" .. name .. " (#RRGGBB) not found in styles.scss")
      end
      return hex:upper()
    end
    cache.colors = { primary = grab("jd%-primary"), secondary = grab("jd%-secondary") }
  end
  return cache.colors
end

-- Current page language ("vi" by default).
function M.lang(meta)
  local l = meta and meta.lang and stringify(meta.lang) or "vi"
  l = l:match("^(%a%a)") or "vi"
  return l:lower()
end

-- Pick the localized string of a value that is either plain or {vi=..., en=...}.
function M.tr(value, lang)
  if value == nil then
    return ""
  end
  if type(value) == "table" and value[lang] ~= nil then
    return stringify(value[lang])
  end
  if type(value) == "table" and value.vi ~= nil then
    return stringify(value.vi)
  end
  return stringify(value)
end

-- Look up a dotted key ("recruiting.positions") in a meta table.
function M.get(meta, key)
  local v = meta
  for part in key:gmatch("[^%.]+") do
    if type(v) ~= "table" then
      return nil
    end
    v = v[part]
  end
  return v
end

function M.ui(key, lang)
  return M.tr(M.data("i18n")[key], lang)
end

function M.is_true(v)
  if type(v) == "boolean" then
    return v
  end
  return v ~= nil and stringify(v) == "true"
end

function M.status_text(lang)
  local meta = M.data("meta")
  local r = meta.recruiting or {}
  if M.is_true(r.open) then
    return M.ui("status_open", lang) .. " · " .. stringify(r.positions) .. " " .. M.ui("positions", lang)
  end
  return M.ui("status_closed", lang)
end

-- "2026-11-17" -> "17/11/2026" (vi) or "17 November 2026" (en)
local months = { "January", "February", "March", "April", "May", "June", "July",
  "August", "September", "October", "November", "December" }
function M.format_date(iso, lang)
  local y, m, d = iso:match("(%d+)-(%d+)-(%d+)")
  if not y then
    return iso
  end
  if lang == "en" then
    return tonumber(d) .. " " .. months[tonumber(m)] .. " " .. y
  end
  return string.format("%02d/%02d/%s", tonumber(d), tonumber(m), y)
end

function M.updated_date(lang)
  return M.format_date(stringify(M.data("meta").updated), lang)
end

function M.page_url(lang)
  local base = stringify(M.data("meta").site_url):gsub("/+$", "")
  return base .. "/" .. lang .. "/"
end

function M.urlencode(s)
  -- ASCII-only class: %w is locale-dependent and may match UTF-8 lead bytes.
  return (s:gsub("[^A-Za-z0-9%-%._~]", function(c)
    return string.format("%%%02X", string.byte(c))
  end))
end

function M.mailto(lang)
  local meta = M.data("meta")
  return "mailto:" .. stringify(meta.email) .. "?subject=" .. M.urlencode(M.tr(meta.apply_subject, lang))
end

function M.html_escape(s)
  return (s:gsub("[&<>\"]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;" }))
end

function M.latex_escape(s)
  return (s:gsub("[\\&%%%$#_{}~%^]", {
    ["\\"] = "\\textbackslash{}", ["&"] = "\\&", ["%"] = "\\%", ["$"] = "\\$",
    ["#"] = "\\#", ["_"] = "\\_", ["{"] = "\\{", ["}"] = "\\}",
    ["~"] = "\\textasciitilde{}", ["^"] = "\\textasciicircum{}",
  }))
end

-- A URL inside a LaTeX macro argument: only % and # need escaping for \href.
function M.latex_url(s)
  return (s:gsub("[%%#]", { ["%"] = "\\%", ["#"] = "\\#" }))
end

return M
