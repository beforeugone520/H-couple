import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { CoupleJoin } from './CoupleJoin';

const supabaseMock = vi.hoisted(() => ({
  rpc: vi.fn()
}));

vi.mock('../../lib/supabase', () => ({
  supabase: {
    rpc: supabaseMock.rpc
  }
}));

describe('CoupleJoin', () => {
  beforeEach(() => {
    supabaseMock.rpc.mockReset();
    supabaseMock.rpc.mockResolvedValue({ data: 'space-1', error: null });
  });

  it('prevents duplicate space creation while creating', async () => {
    let resolveCreate: (value: { data: Array<{ couple_space_id: string; invite_code: string }>; error: null }) => void =
      () => undefined;
    supabaseMock.rpc.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveCreate = resolve;
        })
    );
    const onJoined = vi.fn();

    render(<CoupleJoin onJoined={onJoined} />);

    fireEvent.click(screen.getByRole('button', { name: '创建双人空间' }));

    const creatingButton = await screen.findByRole('button', { name: '创建中...' });

    expect(creatingButton.hasAttribute('disabled')).toBe(true);
    expect(creatingButton.getAttribute('aria-busy')).toBe('true');
    expect(screen.getByRole('status').textContent).toContain('正在创建双人空间...');

    fireEvent.click(creatingButton);
    expect(supabaseMock.rpc).toHaveBeenCalledTimes(1);

    resolveCreate({ data: [{ couple_space_id: 'space-1', invite_code: 'LOVE42' }], error: null });
    await waitFor(() => expect(onJoined).toHaveBeenCalledWith('space-1', 'LOVE42'));
  });

  it('prevents duplicate joins while joining with an invite code', async () => {
    let resolveJoin: (value: { data: string; error: null }) => void = () => undefined;
    supabaseMock.rpc.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveJoin = resolve;
        })
    );
    const onJoined = vi.fn();

    render(<CoupleJoin onJoined={onJoined} />);

    fireEvent.change(screen.getByLabelText('邀请码'), { target: { value: 'love42' } });
    fireEvent.click(screen.getByRole('button', { name: '加入' }));

    const joiningButton = await screen.findByRole('button', { name: '加入中...' });

    expect(joiningButton.hasAttribute('disabled')).toBe(true);
    expect(joiningButton.getAttribute('aria-busy')).toBe('true');
    expect(screen.getByRole('status').textContent).toContain('正在加入双人空间...');

    fireEvent.click(joiningButton);
    expect(supabaseMock.rpc).toHaveBeenCalledTimes(1);
    expect(supabaseMock.rpc).toHaveBeenCalledWith('join_couple_space', { join_code: 'LOVE42' });

    resolveJoin({ data: 'space-1', error: null });
    await waitFor(() => expect(onJoined).toHaveBeenCalledWith('space-1'));
  });

  it('normalizes pasted invite codes before joining', () => {
    render(<CoupleJoin onJoined={vi.fn()} />);

    const inviteInput = screen.getByLabelText('邀请码') as HTMLInputElement;
    fireEvent.change(inviteInput, { target: { value: ' love 42 ' } });

    expect(inviteInput.value).toBe('LOVE42');
    expect(inviteInput.getAttribute('aria-describedby')).toBe('invite-code-helper');
    expect(screen.getByText('邀请码会自动转为大写并移除空格。')).toBeTruthy();
    expect(screen.getByRole('button', { name: '加入' }).hasAttribute('disabled')).toBe(false);
  });

  it('shows invite-code readiness before enabling join', () => {
    render(<CoupleJoin onJoined={vi.fn()} />);

    expect(screen.getByText('邀请码状态')).toBeTruthy();
    expect(screen.getByText('邀请码待输入')).toBeTruthy();

    fireEvent.change(screen.getByLabelText('邀请码'), { target: { value: 'lov' } });

    expect(screen.getByText('至少 4 位后可以加入')).toBeTruthy();
    expect(screen.getByRole('button', { name: '加入' }).hasAttribute('disabled')).toBe(true);

    fireEvent.change(screen.getByLabelText('邀请码'), { target: { value: 'love' } });

    expect(screen.getByText('邀请码已整理，可以加入')).toBeTruthy();
    expect(screen.getByRole('button', { name: '加入' }).hasAttribute('disabled')).toBe(false);
  });

  it('explains the two-person setup flow before creating or joining', () => {
    render(<CoupleJoin onJoined={vi.fn()} />);

    expect(screen.getByText('空间准备')).toBeTruthy();
    expect(screen.getByText('1. 创建空间')).toBeTruthy();
    expect(screen.getByText('2. 复制邀请码')).toBeTruthy();
    expect(screen.getByText('3. 对方加入')).toBeTruthy();
    expect(screen.getByText('已有邀请码')).toBeTruthy();
  });
});
