# humangate docs

The documentation site, built with [Astro Starlight](https://starlight.astro.build) and deployed
to GitHub Pages by `.github/workflows/docs.yml` on every push to `main` that changes `docs/`.
Pages are Markdown files in `src/content/docs/`; the sidebar is in `astro.config.mjs`.

```bash
npm install
npm run dev     # http://localhost:4321/humangate/
npm run build   # into dist/
```
