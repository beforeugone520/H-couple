import { fireEvent, render, screen, waitFor, within } from '@testing-library/react';
import { describe, expect, it, vi } from 'vitest';
import { WorkspaceHeader } from './WorkspaceHeader';

describe('WorkspaceHeader', () => {
  it('summarizes the connected workspace state', () => {
    render(<WorkspaceHeader />);

    expect(screen.getByRole('heading', { name: '双人空间已连接' })).toBeTruthy();
    expect(screen.getByText('记录、回应和回看都会同步到这个私密空间。')).toBeTruthy();

    const status = within(screen.getByLabelText('工作区状态'));
    expect(status.getByText('已连接')).toBeTruthy();
    expect(status.getByText('私密空间')).toBeTruthy();
    expect(status.getByText('时间线同步')).toBeTruthy();
  });

  it('links to the primary workspace sections', () => {
    render(<WorkspaceHeader />);

    const recordLink = screen.getByRole('link', { name: '主操作：记录瞬间' });
    const timelineLink = screen.getByRole('link', { name: '查看时间线' });

    expect(recordLink.getAttribute('href')).toBe('#moment-composer');
    expect(recordLink.className).toContain('workspace-link-primary');
    expect(timelineLink.getAttribute('href')).toBe('#timeline-panel');
    expect(timelineLink.className).toContain('workspace-link-secondary');
  });

  it('surfaces a newly created invite code inside the connected workspace', () => {
    render(<WorkspaceHeader inviteCode="LOVE42" />);

    expect(screen.getByText('邀请对方加入')).toBeTruthy();
    expect(screen.getByText('LOVE42')).toBeTruthy();
    expect(screen.getByText('复制后发给对方，对方加入后即可共同记录。')).toBeTruthy();
  });

  it('copies the newly created invite code with visible feedback', async () => {
    const writeText = vi.fn(() => Promise.resolve());
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText }
    });

    render(<WorkspaceHeader inviteCode="LOVE42" />);

    fireEvent.click(screen.getByRole('button', { name: '复制邀请码 LOVE42' }));

    await waitFor(() => expect(writeText).toHaveBeenCalledWith('LOVE42'));
    expect(screen.getByText('已复制邀请码').className).toContain('workspace-copy-status-success');
  });

  it('keeps the invite code in the fallback message when clipboard copy fails', async () => {
    const writeText = vi.fn(() => Promise.reject(new Error('clipboard blocked')));
    Object.defineProperty(navigator, 'clipboard', {
      configurable: true,
      value: { writeText }
    });

    render(<WorkspaceHeader inviteCode="LOVE42" />);

    fireEvent.click(screen.getByRole('button', { name: '复制邀请码 LOVE42' }));

    await waitFor(() => expect(writeText).toHaveBeenCalledWith('LOVE42'));
    expect(screen.getByText('复制失败，请手动复制 LOVE42').className).toContain('workspace-copy-status-error');
  });

  it('reveals a scannable invite QR code on demand', () => {
    const { container } = render(<WorkspaceHeader inviteCode="LOVE42" />);

    // 默认折叠，保持头部紧凑
    expect(container.querySelector('svg.invite-qr')).toBeNull();
    const toggle = screen.getByRole('button', { name: '显示二维码' });
    expect(toggle.getAttribute('aria-expanded')).toBe('false');

    fireEvent.click(toggle);

    expect(container.querySelector('svg.invite-qr')).not.toBeNull();
    expect(screen.getByRole('button', { name: '收起二维码' }).getAttribute('aria-expanded')).toBe('true');
  });

  it('does not offer a QR code when there is no invite code', () => {
    render(<WorkspaceHeader />);
    expect(screen.queryByRole('button', { name: '显示二维码' })).toBeNull();
  });
});
