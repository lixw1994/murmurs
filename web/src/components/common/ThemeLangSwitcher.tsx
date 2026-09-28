import { Globe, Moon, Sun } from "lucide-react";
import { useTranslation } from "react-i18next";

import { useTheme } from "~/components/theme-provider";
import { Button } from "~/components/ui/button";
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from "~/components/ui/tooltip";

/**
 * Compact theme and language switcher component for headers.
 *
 * The theme icon is driven by the `dark` class on <html> (set before hydration
 * by ThemeProvider), so it renders correctly on first paint with no flash.
 */
export function ThemeLangSwitcher() {
  const { i18n, t } = useTranslation();
  const { resolvedTheme, setTheme } = useTheme();

  const toggleTheme = () => setTheme(resolvedTheme === "dark" ? "light" : "dark");

  const toggleLanguage = () => {
    const next = i18n.language === "en" ? "zh-Hans" : "en";
    void i18n.changeLanguage(next);
  };

  return (
    <TooltipProvider delayDuration={0}>
      <div className="flex items-center gap-1">
        <Tooltip>
          <TooltipTrigger asChild>
            <Button variant="ghost" size="icon" onClick={toggleTheme} className="h-8 w-8">
              <Sun className="h-4 w-4 dark:hidden" />
              <Moon className="hidden h-4 w-4 dark:block" />
              <span className="sr-only">{t("web.theme.toggle")}</span>
            </Button>
          </TooltipTrigger>
          <TooltipContent side="bottom">
            {resolvedTheme === "light" ? t("dark_mode_dark") : t("dark_mode_light")}
          </TooltipContent>
        </Tooltip>

        <Tooltip>
          <TooltipTrigger asChild>
            <Button
              variant="ghost"
              size="icon"
              onClick={toggleLanguage}
              className="h-8 w-8"
            >
              <Globe className="h-4 w-4" />
              <span className="sr-only">{t("web.language.toggle")}</span>
            </Button>
          </TooltipTrigger>
          <TooltipContent side="bottom">
            {i18n.language === "en" ? t("web.language.zh_hans") : t("web.language.en")}
          </TooltipContent>
        </Tooltip>
      </div>
    </TooltipProvider>
  );
}
