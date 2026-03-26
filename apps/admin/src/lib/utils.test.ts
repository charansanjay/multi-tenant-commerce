import { describe, it, expect } from 'vitest';
import { cn } from './utils';

describe('cn', () => {
  it('merges class names', () => {
    expect(cn('px-4', 'py-2')).toBe('px-4 py-2');
  });

  it('resolves tailwind conflicts — last one wins', () => {
    expect(cn('px-4', 'px-2')).toBe('px-2');
  });

  it('handles conditional classes', () => {
    const isActive = true;
    const isInactive = false;
    expect(cn('base', isActive && 'active', isInactive && 'inactive')).toBe('base active');
  });
});
