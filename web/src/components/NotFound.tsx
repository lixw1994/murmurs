import { Link } from "@tanstack/react-router";
import { useTranslation } from "react-i18next";

import { Button } from "./ui/button";

export function NotFound() {
  const { t } = useTranslation();

  return (
    <div className="space-y-2 p-2">
      <p>{t("web.errors.not_found")}</p>
      <p className="flex flex-wrap items-center gap-2">
        <Button type="button" onClick={() => window.history.back()}>
          {t("web.errors.go_back")}
        </Button>
        <Button asChild variant="secondary">
          <Link to="/">{t("web.errors.home")}</Link>
        </Button>
      </p>
    </div>
  );
}
