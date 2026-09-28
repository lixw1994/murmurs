import {
  ErrorComponent,
  type ErrorComponentProps,
  Link,
  rootRouteId,
  useMatch,
  useRouter,
} from "@tanstack/react-router";
import { useTranslation } from "react-i18next";

import { Button } from "./ui/button";

export function DefaultCatchBoundary({ error }: Readonly<ErrorComponentProps>) {
  const { t } = useTranslation();
  const router = useRouter();
  const isRoot = useMatch({
    strict: false,
    select: (state) => state.id === rootRouteId,
  });

  console.error(error);

  return (
    <div className="flex min-w-0 flex-1 flex-col items-center justify-center gap-6 p-4">
      <ErrorComponent error={error} />
      <div className="flex flex-wrap items-center gap-2">
        <Button type="button" onClick={() => router.invalidate()}>
          {t("try_again")}
        </Button>
        {isRoot ? (
          <Button asChild variant="secondary">
            <Link to="/">{t("web.errors.home")}</Link>
          </Button>
        ) : (
          <Button asChild variant="secondary">
            <Link
              to="/"
              onClick={(e) => {
                e.preventDefault();
                window.history.back();
              }}
            >
              {t("web.errors.go_back")}
            </Link>
          </Button>
        )}
      </div>
    </div>
  );
}
