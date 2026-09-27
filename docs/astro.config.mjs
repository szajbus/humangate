// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

const repo = 'https://github.com/szajbus/humangate';

// Served from GitHub Pages, under the owner's domain: szajbus.dev/humangate/.
// With a domain of its own: set `site` to it, drop `base`, and add
// public/CNAME with the domain. Pages link to each other from the site root
// (/tools/), and the base is added here - so moving needs no changes to the
// pages.
const base = '/humangate';

// Adds the base to root-relative links in Markdown.
function baseLinks() {
	const walk = (node) => {
		if (node.type === 'link' && /^\/(?!\/)/.test(node.url) && !node.url.startsWith(`${base}/`)) {
			node.url = base + node.url;
		}
		node.children?.forEach(walk);
	};
	return walk;
}

export default defineConfig({
	site: 'https://szajbus.dev',
	base,
	markdown: { remarkPlugins: [baseLinks] },
	integrations: [
		starlight({
			title: 'humangate',
			description:
				'Keeps a person in the loop for what a sandboxed coding agent can’t be trusted to do alone.',
			social: [{ icon: 'github', label: 'GitHub', href: repo }],
			editLink: { baseUrl: `${repo}/edit/main/docs/` },
			routeMiddleware: './src/routeData.ts',
			sidebar: [
				{ label: 'Getting started', slug: 'getting-started' },
				{ label: 'Which credentials go where', slug: 'credentials' },
				{ label: 'Tools', slug: 'tools' },
				{ label: 'Starter tools', slug: 'starter-tools' },
				{ label: 'Guarding files', slug: 'guarding-files' },
				{ label: 'Security', slug: 'security' },
			],
		}),
	],
});
