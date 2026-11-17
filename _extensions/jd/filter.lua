-- Filter for the JD pages.
-- 1. Meta: exposes data from _data/*.yml + brand colors to the LaTeX template
--    partials as $jd.*$ (colors, QR url, "last updated", running header ...).
-- 2. Div.keep-together: kept on one page in the PDF.
-- 3. Div.project-card: renders a project track as a card (HTML) or a
--    tcolorbox block (PDF). The first header inside the div is its title;
--    attribute track="1" adds the "Hướng 1" / "Track 1" label.

local C = dofile(quarto.utils.resolve_path("common.lua"))

local lang = "vi"

local function tex(s)
  return pandoc.MetaInlines({ pandoc.RawInline("latex", s) })
end

local function Meta(meta)
  lang = C.lang(meta)
  if not quarto.doc.is_format("latex") then
    return nil
  end
  local m = C.data("meta")
  local colors = C.colors()
  meta.jd = pandoc.MetaMap({
    primary = tex(colors.primary),
    secondary = tex(colors.secondary),
    url = tex(C.page_url(lang)),
    url_label = tex(C.latex_escape(C.ui("web_version", lang))),
    updated = tex(C.latex_escape(C.ui("updated", lang) .. ": " .. C.updated_date(lang))),
    short_title = tex(C.latex_escape(C.tr(m.short_title, lang))),
    group = tex(C.latex_escape(C.tr(m.group, lang))),
    institution = tex(C.latex_escape(C.tr(m.institution, lang))),
    page_label = tex(C.latex_escape(C.ui("page", lang))),
    of_label = tex(C.latex_escape(C.ui("of", lang))),
  })
  return meta
end

local function Div(el)
  -- .keep-together: never split across PDF pages (no effect on the web).
  if el.classes:includes("keep-together") then
    if not quarto.doc.is_format("latex") then
      return nil
    end
    local blocks = pandoc.List({ pandoc.RawBlock("latex", "\\par\\noindent\\begin{minipage}{\\linewidth}\\setlength{\\parskip}{0.4em}") })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock("latex", "\\end{minipage}\\par"))
    return blocks
  end

  if not el.classes:includes("project-card") then
    return nil
  end
  local track = el.attributes["track"]
  local kicker = track and (C.ui("track", lang) .. " " .. track) or ""

  local title = {}
  if el.content[1] and el.content[1].t == "Header" then
    title = el.content[1].content
    el.content:remove(1)
  end

  if quarto.doc.is_format("latex") then
    local open = pandoc.List({ pandoc.RawInline("latex", "\\begin{jdproject}{" .. C.latex_escape(kicker) .. "}{") })
    open:extend(title)
    open:insert(pandoc.RawInline("latex", "}"))
    local blocks = pandoc.List({ pandoc.Plain(open) })
    blocks:extend(el.content)
    blocks:insert(pandoc.RawBlock("latex", "\\end{jdproject}"))
    return blocks
  end

  -- HTML (and others): kicker + title header, then content.
  local head = pandoc.List()
  if kicker ~= "" then
    head:insert(pandoc.Div({ pandoc.Plain({ pandoc.Str(kicker) }) }, { class = "track-label" }))
  end
  head:insert(pandoc.Header(3, title, { class = "card-title unnumbered unlisted" }))
  head:extend(el.content)
  el.content = head
  return el
end

return {
  { Meta = Meta },
  { Div = Div },
}
