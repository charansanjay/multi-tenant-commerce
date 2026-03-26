'use client';

interface ErrorProps {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function RootError({ error, reset }: ErrorProps) {
  return (
    <div className="bg-background flex min-h-screen flex-col items-center justify-center gap-4 p-8">
      <h2 className="text-foreground text-lg font-semibold">Something went wrong</h2>
      <p className="text-foreground-muted text-sm">
        {error.message ?? 'An unexpected error occurred'}
      </p>
      <button
        onClick={reset}
        className="bg-primary text-primary-foreground hover:bg-primary-hover rounded-[--radius-md] px-4 py-2 text-sm"
      >
        Try again
      </button>
    </div>
  );
}
