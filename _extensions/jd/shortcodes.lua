-- Shortcodes for the JD pages. Every shortcode works for HTML and LaTeX/PDF
-- and picks the language from the page's `lang` metadata.
--
--   {{< jd email >}}          value from _data/meta.yml (localized if {vi,en})
--   {{< jd email link=true >}}  ... rendered as a mailto link
--   {{< skills >}}            "Preferred" list from _data/skills.yml
--   {{< jd-summary >}}        info box: group, PI, supervisor, status, deadline, buttons
--   {{< jd-status >}}         status badge ("Đang mở · 3–5 vị trí")
--   {{< jd-apply >}}          Apply button (mailto with pre-filled subject)

local C = dofile(quarto.utils.resolve_path("common.lua"))
local stringify = pandoc.utils.stringify

local function is_html()
  return quarto.doc.is_format("html")
end

local function is_latex()
  return quarto.doc.is_format("latex")
end

local function raw_html(s)
  return pandoc.RawInline("html", s)
end

local function raw_tex(s)
  return pandoc.RawInline("latex", s)
end

local function kwarg(kwargs, name)
  local v = kwargs[name]
  if v == nil then
    return nil
  end
  v = stringify(v)
  if v == "" then
    return nil
  end
  return v
end

-- ----------------------------------------------------------------- helpers --

local function status_html(lang)
  local open = C.is_true((C.data("meta").recruiting or {}).open)
  return '<span class="status-badge ' .. (open and "is-open" or "is-closed") .. '">'
    .. '<span class="status-dot" aria-hidden="true"></span>'
    .. C.html_escape(C.status_text(lang)) .. "</span>"
end

local function status_tex(lang)
  return "\\jdbadge{" .. C.latex_escape(C.status_text(lang)) .. "}"
end

local function apply_html(lang, extra_class)
  return '<a class="btn btn-apply ' .. (extra_class or "") .. '" href="'
    .. C.html_escape(C.mailto(lang)) .. '">'
    .. '<i class="bi bi-envelope-paper" aria-hidden="true"></i> '
    .. C.html_escape(C.ui("apply", lang)) .. "</a>"
end

local function apply_tex(lang)
  return "\\jdapply{" .. C.latex_url(C.mailto(lang)) .. "}{"
    .. C.latex_escape(C.ui("apply_via", lang) .. ": " .. stringify(C.data("meta").email)) .. "}"
end

local function pdf_html(lang)
  local file = "UET-IAI-JD-" .. lang:upper() .. ".pdf"
  return '<a class="btn btn-pdf" href="index.pdf" download="' .. file .. '">'
    .. '<i class="bi bi-file-earmark-arrow-down" aria-hidden="true"></i> '
    .. C.html_escape(C.ui("download_pdf", lang)) .. "</a>"
end

-- -------------------------------------------------------------- shortcodes --

local function jd(args, kwargs, meta)
  local lang = C.lang(meta)
  local key = args[1] and stringify(args[1]) or ""
  local value = C.get(C.data("meta"), key)
  if value == nil then
    quarto.log.warning("[jd] unknown key: " .. key)
    return pandoc.Strong({ pandoc.Str("??" .. key .. "??") })
  end
  local text = C.tr(value, lang)
  if key == "updated" then
    text = C.updated_date(lang)
  end
  if kwarg(kwargs, "link") == "true" and key == "email" then
    return pandoc.Link({ pandoc.Str(text) }, "mailto:" .. text)
  end
  return pandoc.Str(text)
end

local function skills(args, kwargs, meta)
  local lang = C.lang(meta)
  local items = {}
  for _, group in ipairs(C.data("skills").groups or {}) do
    local names = {}
    for _, it in ipairs(group.items or {}) do
      table.insert(names, C.tr(it, lang))
    end
    table.insert(items, pandoc.Plain({
      pandoc.Strong({ pandoc.Str(C.tr(group.label, lang) .. ":") }),
      pandoc.Space(),
      pandoc.Str(table.concat(names, ", ") .. "."),
    }))
  end
  return pandoc.BulletList(items)
end

local function jd_status(args, kwargs, meta)
  local lang = C.lang(meta)
  if is_html() then
    return raw_html(status_html(lang))
  elseif is_latex() then
    return raw_tex(status_tex(lang))
  end
  return pandoc.Str(C.status_text(lang))
end

local function jd_apply(args, kwargs, meta)
  local lang = C.lang(meta)
  if is_html() then
    return pandoc.RawBlock("html", '<div class="jd-actions">' .. apply_html(lang, "btn-lg") .. "</div>")
  elseif is_latex() then
    return pandoc.RawBlock("latex", "\\medskip\\noindent" .. apply_tex(lang) .. "\\par")
  end
  return pandoc.Para({ pandoc.Link({ pandoc.Str(C.ui("apply", lang)) }, C.mailto(lang)) })
end

local function jd_summary(args, kwargs, meta)
  local lang = C.lang(meta)
  local m = C.data("meta")
  local email = stringify(m.email)
  local rows = {
    { C.ui("group", lang), C.tr(m.group, lang) },
    { C.ui("pi", lang), C.tr(m.pi, lang) },
    { C.ui("supervisor", lang), C.tr(m.supervisor, lang), email },
    { C.ui("status", lang), nil },
    { C.ui("deadline", lang), C.tr(m.deadline, lang) },
  }

  if is_html() then
    local h = { '<div class="jd-summary">', '<dl class="jd-meta">' }
    for _, r in ipairs(rows) do
      local dd
      if r[2] == nil then
        dd = status_html(lang)
      else
        dd = C.html_escape(r[2])
        if r[3] then
          dd = dd .. ' · <a href="mailto:' .. C.html_escape(r[3]) .. '">' .. C.html_escape(r[3]) .. "</a>"
        end
      end
      table.insert(h, "<div><dt>" .. C.html_escape(r[1]) .. "</dt><dd>" .. dd .. "</dd></div>")
    end
    table.insert(h, "</dl>")
    table.insert(h, '<div class="jd-actions">' .. apply_html(lang, "btn-lg") .. pdf_html(lang) .. "</div>")
    table.insert(h, '<p class="jd-updated"><i class="bi bi-clock-history" aria-hidden="true"></i> '
      .. C.html_escape(C.ui("updated", lang)) .. ": " .. C.html_escape(C.updated_date(lang)) .. "</p>")
    table.insert(h, "</div>")
    -- Floating Apply button, shown only on small screens (see styles.scss).
    table.insert(h, '<div class="apply-fab">' .. apply_html(lang) .. "</div>")
    return pandoc.RawBlock("html", table.concat(h, "\n"))
  end

  if is_latex() then
    local t = { "\\begin{jdinfo}" }
    for _, r in ipairs(rows) do
      local val
      if r[2] == nil then
        val = status_tex(lang)
      else
        val = C.latex_escape(r[2])
        if r[3] then
          val = val .. " · \\href{mailto:" .. r[3] .. "}{" .. C.latex_escape(r[3]) .. "}"
        end
      end
      table.insert(t, "\\textbf{" .. C.latex_escape(r[1]) .. "} & " .. val .. " \\\\")
    end
    table.insert(t, "\\end{jdinfo}")
    table.insert(t, "\\noindent" .. apply_tex(lang) .. "\\par\\medskip")
    return pandoc.RawBlock("latex", table.concat(t, "\n"))
  end

  -- Other formats: a plain definition list.
  local dl = {}
  for _, r in ipairs(rows) do
    table.insert(dl, { { pandoc.Str(r[1]) }, { { pandoc.Plain({ pandoc.Str(r[2] or C.status_text(lang)) }) } } })
  end
  return pandoc.DefinitionList(dl)
end

return {
  ["jd"] = jd,
  ["skills"] = skills,
  ["jd-status"] = jd_status,
  ["jd-apply"] = jd_apply,
  ["jd-summary"] = jd_summary,
}
