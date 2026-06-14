import { render } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { InviteQr } from './InviteQr';

describe('InviteQr', () => {
  it('renders an accessible svg qr code for an invite code', () => {
    const { container } = render(<InviteQr code="LOVE42" origin="https://memorybox.example.com" />);

    const svg = container.querySelector('svg');
    expect(svg).not.toBeNull();
    expect(svg?.getAttribute('role')).toBe('img');
    expect(svg?.getAttribute('aria-label')).toContain('二维码');
    // QR 矩阵被绘制成若干暗模块
    expect(container.querySelectorAll('rect').length).toBeGreaterThan(1);
  });

  it('renders nothing when the code is empty', () => {
    const { container } = render(<InviteQr code="" origin="https://memorybox.example.com" />);
    expect(container.querySelector('svg')).toBeNull();
  });
});
