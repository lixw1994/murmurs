import type { QueryClient } from "@tanstack/react-query";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import {
  createRootRouteWithContext,
  HeadContent,
  Outlet,
  Scripts,
} from "@tanstack/react-router";
import { TanStackRouterDevtools } from "@tanstack/react-router-devtools";

import { RootShell } from "~/components/layout/RootShell";
import { ThemeProvider } from "~/components/theme-provider";
import i18n from "~/i18n"; // Initialize i18n before any component renders
import { getLocale } from "~/i18n/get-locale";

import appCss from "~/styles.css?url";

export const Route = createRootRouteWithContext<{
  queryClient: QueryClient;
}>()({
  beforeLoad: () => {
    // Detect the locale from the cookie (isomorphic) and apply it before render
    // so SSR and the first client render use the same language (no flash).
    const locale = getLocale();
    if (i18n.language !== locale) {
      void i18n.changeLanguage(locale);
    }

    return { locale };
  },
  head: () => {
    const name = i18n.t("app_name");
    const description = i18n.t("web.landing.description");
    return {
      meta: [
        { charSet: "utf-8" },
        { name: "viewport", content: "width=device-width, initial-scale=1" },
        { title: name },
        { name: "description", content: description },
        { property: "og:title", content: name },
        { property: "og:description", content: description },
        { property: "og:type", content: "website" },
        { property: "og:site_name", content: name },
        { name: "twitter:card", content: "summary_large_image" },
        { name: "twitter:title", content: name },
        { name: "twitter:description", content: description },
      ],
      links: [{ rel: "stylesheet", href: appCss }],
    };
  },
  component: RootComponent,
});

function RootComponent() {
  const { locale } = Route.useRouteContext();
  return (
    <RootDocument locale={locale}>
      <RootShell>
        <Outlet />
      </RootShell>
    </RootDocument>
  );
}

function RootDocument({
  children,
  locale,
}: {
  readonly children: React.ReactNode;
  readonly locale: string;
}) {
  return (
    // suppress since ThemeProvider updates the theme class before hydration
    <html lang={locale} suppressHydrationWarning>
      <head>
        <HeadContent />
      </head>
      <body>
        <ThemeProvider>{children}</ThemeProvider>

        <ReactQueryDevtools buttonPosition="bottom-left" />
        <TanStackRouterDevtools position="bottom-right" />

        <Scripts />
      </body>
    </html>
  );
}
