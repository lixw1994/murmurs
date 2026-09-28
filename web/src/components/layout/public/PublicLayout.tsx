import { cn } from "~/lib/utils";

interface PublicLayoutProps {
  children: React.ReactNode;
  className?: string;
}

export function PublicLayout({ children, className }: PublicLayoutProps) {
  return (
    <div className={cn("min-h-screen bg-background text-foreground", className)}>
      {children}
    </div>
  );
}
