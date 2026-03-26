export default function NotFound() {
  return (
    <div className="bg-background flex min-h-screen flex-col items-center justify-center gap-4 p-8">
      <h2 className="text-foreground text-2xl font-semibold">404</h2>
      <p className="text-foreground-muted text-sm">The page you are looking for does not exist.</p>

      <a
        href="/dashboard"
        className="bg-primary text-primary-foreground hover:bg-primary-hover rounded-[--radius-md] px-4 py-2 text-sm"
      >
        Go to Dashboard
      </a>
    </div>
  );
}
