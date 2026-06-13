import { render, screen } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { StatusMessage } from './StatusMessage';

describe('StatusMessage', () => {
  it('announces neutral progress without alerting', () => {
    render(<StatusMessage tone="pending" message="正在保存..." />);

    const status = screen.getByRole('status');
    expect(screen.getByText('处理中')).toBeTruthy();
    expect(status.textContent).toContain('正在保存...');
    expect(status.getAttribute('aria-live')).toBe('polite');
  });

  it('announces errors as alerts', () => {
    render(<StatusMessage tone="error" message="保存失败" />);

    const alert = screen.getByRole('alert');
    expect(screen.getByText('需要处理')).toBeTruthy();
    expect(alert.textContent).toContain('保存失败');
    expect(alert.getAttribute('aria-live')).toBe('assertive');
  });

  it('labels success and neutral messages for quick scanning', () => {
    const { rerender } = render(<StatusMessage tone="success" message="已保存。" />);

    expect(screen.getByRole('status').textContent).toContain('已完成');
    expect(screen.getByRole('status').textContent).toContain('已保存。');

    rerender(<StatusMessage message="请输入邮箱登录。" />);

    expect(screen.getByRole('status').textContent).toContain('提示');
    expect(screen.getByRole('status').textContent).toContain('请输入邮箱登录。');
  });

  it('renders nothing when there is no message', () => {
    const { container } = render(<StatusMessage tone="neutral" message="" />);

    expect(container.firstChild).toBeNull();
  });
});
