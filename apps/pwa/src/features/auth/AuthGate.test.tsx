import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import type { Session } from '@supabase/supabase-js';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { AuthGate } from './AuthGate';

const supabaseMock = vi.hoisted(() => ({
  signInWithOtp: vi.fn()
}));

vi.mock('../../lib/supabase', () => ({
  supabase: {
    auth: {
      getSession: vi.fn(() => Promise.resolve({ data: { session: null } })),
      onAuthStateChange: vi.fn(() => ({
        data: {
          subscription: {
            unsubscribe: vi.fn()
          }
        }
      })),
      signInWithOtp: supabaseMock.signInWithOtp
    }
  }
}));

describe('AuthGate', () => {
  beforeEach(() => {
    supabaseMock.signInWithOtp.mockReset();
    supabaseMock.signInWithOtp.mockResolvedValue({ error: null });
  });

  it('prevents duplicate magic-link requests while sending', async () => {
    let resolveSignIn: (value: { error: null }) => void = () => undefined;
    supabaseMock.signInWithOtp.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveSignIn = resolve;
        })
    );

    render(<AuthGate>{(_session: Session) => <div>已登录</div>}</AuthGate>);

    fireEvent.change(screen.getByLabelText('邮箱'), { target: { value: 'person@example.com' } });
    fireEvent.click(screen.getByRole('button', { name: '发送登录链接' }));

    const sendingButton = await screen.findByRole('button', { name: '发送中...' });

    expect(sendingButton.hasAttribute('disabled')).toBe(true);
    expect(sendingButton.getAttribute('aria-busy')).toBe('true');
    expect(screen.getByRole('status').textContent).toContain('正在发送登录链接...');

    fireEvent.click(sendingButton);
    expect(supabaseMock.signInWithOtp).toHaveBeenCalledTimes(1);

    resolveSignIn({ error: null });
    await waitFor(() => {
      expect(screen.getByRole('button', { name: '发送登录链接' }).hasAttribute('disabled')).toBe(false);
    });
  });

  it('uses email input semantics and helper copy for login', () => {
    render(<AuthGate>{(_session: Session) => <div>已登录</div>}</AuthGate>);

    const emailInput = screen.getByLabelText('邮箱');

    expect(emailInput.getAttribute('type')).toBe('email');
    expect(emailInput.getAttribute('inputmode')).toBe('email');
    expect(emailInput.getAttribute('autocomplete')).toBe('email');
    expect(emailInput.getAttribute('aria-describedby')).toBe('email-login-helper');
    expect(screen.getByText('我们会发送一次性登录链接到这个邮箱。')).toBeTruthy();
  });

  it('shows email readiness before enabling magic-link login', async () => {
    render(<AuthGate>{(_session: Session) => <div>已登录</div>}</AuthGate>);

    expect(await screen.findByText('邮箱状态')).toBeTruthy();
    expect(screen.getByText('邮箱待输入')).toBeTruthy();

    fireEvent.change(screen.getByLabelText('邮箱'), { target: { value: 'person' } });

    expect(screen.getByText('请输入完整邮箱地址')).toBeTruthy();
    expect(screen.getByRole('button', { name: '发送登录链接' }).hasAttribute('disabled')).toBe(true);

    fireEvent.change(screen.getByLabelText('邮箱'), { target: { value: 'person@example.com' } });

    expect(screen.getByText('邮箱格式可用，可以发送链接')).toBeTruthy();
    expect(screen.getByRole('button', { name: '发送登录链接' }).hasAttribute('disabled')).toBe(false);
  });

  it('does not send a magic link for incomplete email-like input', async () => {
    render(<AuthGate>{(_session: Session) => <div>已登录</div>}</AuthGate>);

    expect(await screen.findByText('邮箱状态')).toBeTruthy();
    fireEvent.change(screen.getByLabelText('邮箱'), { target: { value: 'person@' } });
    fireEvent.click(screen.getByRole('button', { name: '发送登录链接' }));

    expect(screen.getByRole('button', { name: '发送登录链接' }).hasAttribute('disabled')).toBe(true);
    expect(supabaseMock.signInWithOtp).not.toHaveBeenCalled();
  });

  it('shows next steps after a magic link is sent', async () => {
    render(<AuthGate>{(_session: Session) => <div>已登录</div>}</AuthGate>);

    fireEvent.change(screen.getByLabelText('邮箱'), { target: { value: 'person@example.com' } });
    fireEvent.click(screen.getByRole('button', { name: '发送登录链接' }));

    expect(await screen.findByText('下一步')).toBeTruthy();
    expect(screen.getByText('检查邮箱')).toBeTruthy();
    expect(screen.getByText('点击登录链接')).toBeTruthy();
    expect(screen.getByText('回到时光盒')).toBeTruthy();
  });

  it('surfaces lightweight privacy expectations before login', () => {
    render(<AuthGate>{(_session: Session) => <div>已登录</div>}</AuthGate>);

    expect(screen.getByText('登录方式')).toBeTruthy();
    expect(screen.getByText('一次性链接')).toBeTruthy();
    expect(screen.getByText('不需要密码')).toBeTruthy();
    expect(screen.getByText('仅用于确认身份')).toBeTruthy();
  });
});
