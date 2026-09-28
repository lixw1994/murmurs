import { Toaster } from "~/components/ui/sonner";

interface RootShellProps {
  children: React.ReactNode;
}

export function RootShell({ children }: RootShellProps) {
  return (
    <div className="flex min-h-screen flex-col bg-background text-foreground">
      {children}
      <Toaster />
    </div>
  );
}
