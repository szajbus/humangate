import { defineRouteMiddleware } from '@astrojs/starlight/route-data';

// Adds the base to root-relative hero links (frontmatter isn't Markdown, so
// the remark plugin in astro.config.mjs doesn't reach them).
export const onRequest = defineRouteMiddleware((context) => {
	const base = import.meta.env.BASE_URL.replace(/\/$/, '');
	for (const action of context.locals.starlightRoute.entry.data.hero?.actions ?? []) {
		if (/^\/(?!\/)/.test(action.link) && !action.link.startsWith(`${base}/`)) {
			action.link = base + action.link;
		}
	}
});
