name: Build PDF index and pages
on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Make generator executable
        run: chmod +x ./.github/scripts/generate_pages.sh

      - name: Generate index and per-file pages
        run: ./.github/scripts/generate_pages.sh

      - name: Commit generated files
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add pdfs/index.html $(find . -maxdepth 2 -type f -path "./*/index.html" -not -path "./.github/*") || true
          git commit -m "Auto-generate PDF index and per-file pages" || echo "no changes to commit"
          git push origin HEAD:main