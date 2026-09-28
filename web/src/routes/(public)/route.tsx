import { createFileRoute, Outlet } from "@tanstack/react-router";

import { PublicLayout } from "~/components/layout/public/PublicLayout";

export const Route = createFileRoute("/(public)")({
  component: PublicRouteLayout,
});

function PublicRouteLayout() {
  return (
    <PublicLayout>
      <Outlet />
    </PublicLayout>
  );
}
