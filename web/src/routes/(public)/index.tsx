import { createFileRoute } from "@tanstack/react-router";
import { useTranslation } from "react-i18next";

import { ThemeLangSwitcher } from "~/components/common/ThemeLangSwitcher";

export const Route = createFileRoute("/(public)/")({
  component: LandingPage,
});

function LandingPage() {
  const { t } = useTranslation();

  return (
    <div className="flex min-h-screen flex-col bg-background">
      <header className="border-b">
        <div className="mx-auto flex h-16 max-w-5xl items-center justify-between px-6">
          <span className="flex items-center gap-2 font-semibold">
            <img src="/logo.svg" alt="" className="h-8" />
            {t("app_name")}
          </span>
          <ThemeLangSwitcher />
        </div>
      </header>

      <main className="mx-auto flex max-w-5xl flex-1 flex-col justify-center gap-6 px-6 py-20">
        <h1 className="text-4xl font-bold tracking-tight sm:text-5xl">
          {t("web.landing.tagline")}
        </h1>
        <p className="max-w-2xl text-lg text-muted-foreground">
          {t("web.landing.description")}
        </p>
        <p className="text-sm text-muted-foreground">{t("web.landing.platforms")}</p>
      </main>
    </div>
  );
}
