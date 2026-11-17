# UET-IAI · JD tuyển sinh viên nghiên cứu (Quarto)

JD tuyển sinh viên nghiên cứu **AI cho chẩn đoán Ung thư phổi trên ảnh CT**, song ngữ (VI/EN), xuất ra:

- **Web** (Quarto website) trên GitHub Pages: <https://anhsuplo-87.github.io/uet-iai-research-jd/>
- **PDF** (LaTeX, `xelatex`), mỗi ngôn ngữ một file, có nút "Tải PDF" trên web.

Cả hai cùng sinh ra từ một nguồn nội dung.

## Cấu trúc

```
_quarto.yml            cấu hình site, navbar (VI | EN), định dạng html + pdf
index.qmd              trang gốc /, chuyển hướng sang /vi/
vi/index.qmd           nội dung tiếng Việt (nguồn chính)
en/index.qmd           nội dung tiếng Anh
_data/meta.yml         supervisor, PI, email, trạng thái tuyển, số vị trí, ngày cập nhật, URL site
_data/skills.yml       danh sách Kiến thức / Kỹ năng (mục "Ưu tiên")
_data/i18n.yml         chuỗi giao diện hai ngôn ngữ (nút, nhãn...)
styles.scss            theme web + 2 màu nhận diện (PDF đọc màu từ đây)
partials/              template LaTeX: header.tex (preamble), title.tex, before-body.tex
_extensions/jd/        shortcode + filter Lua (đọc _data/*.yml cho cả HTML lẫn PDF)
fonts/BeVietnamPro/    font cho PDF (SIL OFL 1.1, xem OFL.txt)
assets/                logo IAI, UET, VNU (bản gốc + bản 600px dùng cho web/PDF)
```

## Cài đặt và render local

1. Cài [Quarto](https://quarto.org/docs/get-started/) ≥ 1.5.
2. Cài LaTeX nếu máy chưa có: `quarto install tinytex` (hoặc dùng MiKTeX / TeX Live sẵn có).
3. Chạy:

```bash
quarto preview      # xem trực tiếp, tự reload khi sửa file
```

```bash
quarto render       # build toàn bộ vào _site/ (HTML + vi/index.pdf + en/index.pdf)
```

Chỉ build PDF một ngôn ngữ: `quarto render vi/index.qmd --to pdf`.

## Sửa nội dung

- **Nội dung chính**: sửa `vi/index.qmd`, rồi cập nhật ý tương ứng trong `en/index.qmd`.
- **Thông tin meta** (supervisor, PI, email, trạng thái, số vị trí, hạn nộp, tiêu đề email): chỉ sửa `_data/meta.yml`.
  - Đóng tuyển: `recruiting.open: false` → badge chuyển thành "Đã đóng / Closed".
  - Mỗi lần sửa nội dung, cập nhật `updated:` → hiện ở dòng "Cập nhật lần cuối" trên web và footer PDF.
- **Màu**: sửa `$jd-primary` / `$jd-secondary` trong `styles.scss` (giữ dạng `#RRGGBB`), PDF tự đổi theo.
- **Chuỗi giao diện** (nút, nhãn): `_data/i18n.yml`.

Trong file `.qmd`, các shortcode dùng được:

| Shortcode | Kết quả |
|---|---|
| `{{< jd-summary >}}` | khối thông tin đầu trang + nút Ứng tuyển / Tải PDF |
| `{{< skills >}}` | danh sách Kiến thức / Kỹ năng từ `skills.yml` |
| `{{< jd-status >}}` | badge "Đang mở · 3–5 vị trí" |
| `{{< jd-apply >}}` | nút Ứng tuyển (mailto có sẵn tiêu đề) |
| `{{< jd email >}}`, `{{< jd pi >}}`... | một giá trị trong `meta.yml` (tự chọn theo `lang`) |

Hai hướng dự án là hai khối `::: {.project-card track="1"}` — web hiển thị dạng card, PDF thành khối có khung màu.

## Thêm skill vào `skills.yml`

Thêm một dòng vào nhóm phù hợp. Thuật ngữ giữ nguyên tiếng Anh (Glossary) ghi dạng chuỗi; mục cần dịch ghi dạng `{vi, en}`:

```yaml
groups:
  - id: skills
    label: { vi: "Kỹ năng", en: "Skills" }
    items:
      - PyTorch
      - Docker
      - Weights & Biases                                       # mới: giống nhau ở 2 bản
      - { vi: "đọc ảnh DICOM", en: "reading DICOM images" }    # mới: có bản dịch
```

Muốn thêm nhóm mới (ví dụ "Công cụ y tế"): copy nguyên một khối `- id: ...` và đổi `label`. Web, PDF và cả hai ngôn ngữ đều cập nhật sau lần render tiếp theo.

## Deploy (GitHub Actions → GitHub Pages)

Workflow `.github/workflows/publish.yml` chạy mỗi lần push lên `main`: cài Quarto + TinyTeX, render HTML và PDF, rồi đẩy `_site/` lên nhánh `gh-pages`.

Bật GitHub Pages (làm một lần):

1. Vào repo trên GitHub → **Settings → Pages**.
2. **Source**: *Deploy from a branch*; **Branch**: `gh-pages`, thư mục `/ (root)` → **Save**.
3. Kiểm tra **Settings → Actions → General → Workflow permissions** là *Read and write permissions* (workflow cần quyền push lên `gh-pages`).

Sau vài phút site có tại `https://anhsuplo-87.github.io/uet-iai-research-jd/`. Nếu đổi tên repo hoặc dùng domain riêng, sửa `site_url` trong `_data/meta.yml` để QR code trong PDF trỏ đúng.

## License

Font Be Vietnam Pro: SIL Open Font License 1.1 (`fonts/BeVietnamPro/OFL.txt`).
