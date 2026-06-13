import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { TimelineSkeleton } from './TimelineSkeleton';

describe('TimelineSkeleton', () => {
  it('announces the loading state without exposing decorative placeholders', () => {
    render(<TimelineSkeleton label="正在加载时间线" rows={2} />);

    const status = screen.getByRole('status');

    expect(status.getAttribute('aria-live')).toBe('polite');
    expect(status.getAttribute('aria-busy')).toBe('true');
    expect(status.textContent).toContain('正在加载时间线');
    expect(screen.getAllByTestId('skeleton-row')).toHaveLength(2);
    expect(screen.getAllByTestId('skeleton-row').every((row) => row.getAttribute('aria-hidden') === 'true')).toBe(
      true
    );
  });
});
