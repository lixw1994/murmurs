import { cloudflare } from "@cloudflare/vite-plugin";
import babel from "@rolldown/plugin-babel";
import tailwindcss from "@tailwindcss/vite";
import { tanstackStart } from "@tanstack/react-start/plugin/vite";
import viteReact, { reactCompilerPreset } from "@vitejs/plugin-react";
import { defineConfig } from "vite";

import { version } from "./package.json";

export default defineConfig({
  define: {
    __APP_VERSION__: JSON.stringify(version),
  },
  resolve: {
    // vite 8 resolves tsconfig `paths` natively (replaces vite-tsconfig-paths).
    tsconfigPaths: true,
  },
  server: {
    port: 3000,
  },
  plugins: [
    cloudflare({ viteEnvironment: { name: "ssr" } }),
    tanstackStart(),
    viteReact(),
    // React Compiler via babel preset (vite 8 / @vitejs/plugin-react v6).
    // https://react.dev/learn/react-compiler/installation
    babel({
      presets: [reactCompilerPreset()],
    }),
    tailwindcss(),
  ],
});
