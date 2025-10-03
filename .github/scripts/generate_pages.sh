#!/usr/bin/env bash
set -euo pipefail

# Configuration
PDF_DIR="pdfs"           # where you put your PDFs
ROOT_INDEX="index.html"  # optional root index (kept minimal)
PDFS_INDEX="$PDF_DIR/index.html"
SLUG_DIR_PREFIX=""       # leave blank; will create <slug>/index.html

# Helper: slugify filename (strip extension, replace spaces with -, remove unsafe chars)
slugify() {
  local name="$1"
  # remove extension
  name="${name%.*}"
  # lowercase, replace spaces and %20 with -, remove characters except alnum-_
  local s
  s="$(echo "$name" | iconv -t ascii//TRANSLIT 2>/dev/null || echo "$name")"
  s="$(echo "$s" | tr '[:upper:]' '[:lower:]')"
  s="$(echo "$s" | sed -E 's/[^a-z0-9]+/-/g' | sed -E 's/^-+|-+$//g')"
  echo "$s"
}

# Ensure pdf directory exists
mkdir -p "$PDF_DIR"

# Generate pdfs/index.html — formal listing of all PDFs
cat > "$PDFS_INDEX" <<'HTMLHEAD'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>PDFs</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    body{font-family:ui-sans-serif,system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial;margin:32px;background:#f7f7f8;color:#111}
    h1{margin-top:0}
    .list{display:flex;flex-direction:column;gap:8px;max-width:900px}
    a{color:#0b5fff;text-decoration:none;padding:10px 12px;border-radius:8px;background:#fff;box-shadow:0 2px 8px rgba(0,0,0,0.06)}
    .meta{font-size:12px;color:#666;margin-left:8px}
    header{margin-bottom:16px}
  </style>
</head>
<body>
  <header>
    <h1>PDF Library</h1>
    <p>Files in <code>/pdfs</code>. Click a name to open the pretty landing page for the file, or click the PDF link to download/view directly.</p>
  </header>
  <div class="list">
HTMLHEAD

# For each PDF create a slug directory with index.html (pretty page), and add entry to pdfs/index.html
shopt -s nullglob
for f in "$PDF_DIR"/*.pdf; do
  filename="$(basename "$f")"
  slug="$(slugify "$filename")"
  slug_dir="$SLUG_DIR_PREFIX$slug"
  pdf_rel_path="./$PDF_DIR/$filename"   # relative from root; used where appropriate
  mkdir -p "$slug_dir"

  # Add link to PDF listing page (pdfs/index.html) — link to pretty landing: /<slug>/
  echo "  <div><a href=\"/$slug/\">$filename</a> <a class=\"meta\" href=\"$pdf_rel_path\">(raw pdf)</a></div>" >> "$PDFS_INDEX"

  # Create pretty landing page for this PDF at <slug>/index.html using the user's UI
  # pdfPath must be relative to the slug folder: '../pdfs/<filename>.pdf'
  cat > "$slug_dir/index.html" <<HTMLPAGE
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>$filename</title>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    :root {
      --chip-bg: rgba(0,0,0,0.65);
      --chip-fg: #fff;
      --btn-bg: rgba(0,0,0,0.78);
      --btn-fg: #fff;
      --btn-bg-hover: rgba(0,0,0,0.92);
      --shadow: 0 6px 24px rgba(0,0,0,0.18);
      --radius: 12px;
    }
    html, body { height: 100%; margin: 0; background: #111; color: #eee; font-family: ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial; }
    /* PDF area */
    #pdfWrap { position: fixed; inset: 0; }
    #pdfObject, #pdfEmbed { width: 100%; height: 100%; border: 0; background:#1a1a1a; display:block; }
    /* Last updated chip */
    .chip {
      position: fixed; top: 14px; right: 14px; background: var(--chip-bg); color: var(--chip-fg);
      padding: 8px 12px; border-radius: 999px; font-size: 12px; line-height: 1;
      box-shadow: var(--shadow); opacity: 0; transform: translateY(-6px);
      transition: opacity .6s ease, transform .6s ease; z-index: 5; white-space: nowrap;
      pointer-events:auto;
    }
    .chip.show { opacity: 1; transform: translateY(0); }
    .chip.vanish { opacity: 0; transform: translateY(-6px); }
    /* Action buttons */
    .fab { position: fixed; right: 14px; bottom: 14px; display: flex; gap: 10px; z-index: 5; }
    .btn {
      border: none; border-radius: var(--radius); background: var(--btn-bg); color: var(--btn-fg);
      padding: 10px 14px; font-size: 14px; display: inline-flex; align-items: center; gap: 8px;
      cursor: pointer; box-shadow: var(--shadow); text-decoration: none; transition: background .2s ease, transform .05s ease;
    }
    .btn:hover { background: var(--btn-bg-hover); }
    .btn:active { transform: translateY(1px); }
    .btn svg { width: 16px; height: 16px; }
    /* Fallback */
    .fallback { position: fixed; inset: 0; display: grid; place-items: center; text-align: center; padding: 32px; }
    .hidden { display: none !important; }
    @media print { .chip, .fab { display: none !important; } body { background:#fff; } }
  </style>
</head>
<body>
  <div id="pdfWrap">
    <!-- Prefer <object> for Safari; <embed> as nested fallback -->
    <object id="pdfObject" type="application/pdf" data="">
      <embed id="pdfEmbed" type="application/pdf" src="">
      </embed>
    </object>
  </div>

  <div id="chip" class="chip" aria-live="polite">Last updated: —</div>

  <div class="fab">
    <a id="downloadBtn" class="btn" download>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
        <path d="M7 10l5 5 5-5"/>
        <path d="M12 15V3"/>
      </svg>
      Download
    </a>
    <button id="printBtn" class="btn" type="button">
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M6 9V2h12v7"/>
        <path d="M6 18H4a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v3a2 2 0 0 1-2 2h-2"/>
        <path d="M6 14h12v8H6z"/>
      </svg>
      Print
    </button>
  </div>

  <div id="fallback" class="fallback hidden">
    <div>
      <p>Can’t display the PDF inline in this browser.</p>
      <p><a id="fallbackLink" href="#" class="btn">Open the PDF</a></p>
    </div>
  </div>

  <script>
    (async function () {
      const filename = ${JSON.stringify("$filename")};
      const pdfPath = '../$PDF_DIR/$filename';
      const pdfWithView = pdfPath + '#toolbar=0&navpanes=0&view=FitH';

      const pdfObject = document.getElementById('pdfObject');
      const pdfEmbed  = document.getElementById('pdfEmbed');
      const chip = document.getElementById('chip');
      const downloadBtn = document.getElementById('downloadBtn');
      const printBtn = document.getElementById('printBtn');
      const fallback = document.getElementById('fallback');
      const fallbackLink = document.getElementById('fallbackLink');

      // Set sources (same-origin)
      pdfObject.setAttribute('data', pdfWithView);
      pdfEmbed.setAttribute('src', pdfWithView);
      downloadBtn.href = pdfPath;
      fallbackLink.href = pdfPath;

      // Vanishing chip helpers
      const fmtDate = (iso) => {
        try {
          const d = new Date(iso);
          return d.toLocaleString(undefined, {
            year: 'numeric', month: 'short', day: '2-digit',
            hour: '2-digit', minute: '2-digit'
          });
        } catch { return iso; }
      };
      const showChip = (text) => {
        chip.textContent = text;
        chip.classList.add('show');
        let t = setTimeout(() => chip.classList.add('vanish'), 6000);
        chip.addEventListener('mouseenter', () => { clearTimeout(t); chip.classList.remove('vanish'); });
        chip.addEventListener('mouseleave', () => { t = setTimeout(() => chip.classList.add('vanish'), 2000); });
      };

      // Print (will print the embedded PDF on most browsers)
      printBtn.addEventListener('click', () => window.print());

      // Best-effort inline support detection: if not loaded within 3s, show fallback
      let loaded = false;
      const timer = setTimeout(() => { if (!loaded) fallback.classList.remove('hidden'); }, 3000);
      // We don’t always get a 'load' on <object>. Add a small fetch HEAD fallback to confirm availability.
      try {
        const r = await fetch(pdfPath, { method: 'HEAD' });
        if (!r.ok) throw new Error();
        loaded = true; clearTimeout(timer);
      } catch {
        // Fallback will show after timer
      }

      // Show last updated using GitHub commits API for this file
      try {
        const host = location.host; // "<username>.github.io"
        const owner = host.endsWith('.github.io') ? host.split('.github.io')[0] : host.split(':')[0];
        const pathParts = location.pathname.split('/').filter(Boolean);
        // repo should be first path part (e.g. /MyPDFs/<slug>/)
        const repo = pathParts[0] || 'MyPDFs';
        const commitsURL = \`https://api.github.com/repos/\${owner}/\${repo}/commits?path=$PDF_DIR/\${filename}&per_page=1\`;
        const res = await fetch(commitsURL, { headers: { 'Accept': 'application/vnd.github+json' }});
        if (!res.ok) throw new Error('commit fetch failed');
        const data = await res.json();
        const c = Array.isArray(data) && data[0];
        const iso = c?.commit?.author?.date || null;
        showChip(iso ? \`Last updated • \${fmtDate(iso)}\` : 'Last updated • unknown');
      } catch {
        showChip('Last updated • unavailable');
      }
    })();
  </script>
</body>
</html>
HTMLPAGE

done
shopt -u nullglob

# Close pdfs/index.html
cat >> "$PDFS_INDEX" <<'HTMLTAIL'
  </div>
  <p style="margin-top:16px;color:#666">Auto-generated listing — drop PDFs into the <code>/pdfs</code> folder and push to regenerate.</p>
</body>
</html>
HTMLTAIL

echo "Generated $PDFS_INDEX and per-file pages."