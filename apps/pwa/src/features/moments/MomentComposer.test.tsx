import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import type { Session } from '@supabase/supabase-js';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { MomentComposer } from './MomentComposer';

const supabaseMock = vi.hoisted(() => ({
  insert: vi.fn()
}));

vi.mock('../../lib/supabase', () => ({
  supabase: {
    storage: {
      from: vi.fn(() => ({
        upload: vi.fn()
      }))
    },
    from: vi.fn(() => ({
      insert: supabaseMock.insert
    }))
  }
}));

const session = {
  user: {
    id: 'user-1'
  }
} as Session;

beforeEach(() => {
  supabaseMock.insert.mockReset();
  supabaseMock.insert.mockResolvedValue({ error: null });
  vi.stubGlobal(
    'URL',
    Object.assign(URL, {
      createObjectURL: vi.fn(() => 'blob:photo-preview'),
      revokeObjectURL: vi.fn()
    })
  );
});

describe('MomentComposer', () => {
  it('explains save requirements and readiness to assistive tech', () => {
    render(<MomentComposer session={session} coupleSpaceId="space-1" onCreated={() => undefined} />);

    const saveButton = screen.getByRole('button', { name: '保存' });
    const helper = screen.getByText('添加照片或输入一句话后可保存。');

    expect(saveButton.hasAttribute('disabled')).toBe(true);
    expect(saveButton.getAttribute('aria-describedby')).toBe('moment-save-hint');
    expect(helper.getAttribute('id')).toBe('moment-save-hint');

    fireEvent.change(screen.getByLabelText('一句话'), { target: { value: '今天一起散步' } });

    expect(screen.getByText('可以保存这个瞬间。')).toBeTruthy();
    expect(saveButton.hasAttribute('disabled')).toBe(false);
  });

  it('shows a bounded visual preview after selecting a photo', () => {
    render(<MomentComposer session={session} coupleSpaceId="space-1" onCreated={() => undefined} />);

    const photo = new File(['photo'], 'walk.jpg', { type: 'image/jpeg' });

    fireEvent.change(screen.getByLabelText('照片'), { target: { files: [photo] } });

    const preview = screen.getByAltText('已选择照片预览：walk.jpg') as HTMLImageElement;

    expect(URL.createObjectURL).toHaveBeenCalledWith(photo);
    expect(preview.getAttribute('src')).toBe('blob:photo-preview');
    expect(screen.getByText('已选择照片')).toBeTruthy();
    expect(screen.getByText('点击可更换：walk.jpg')).toBeTruthy();
  });

  it('lets people remove a selected photo before saving', () => {
    render(<MomentComposer session={session} coupleSpaceId="space-1" onCreated={() => undefined} />);

    const photo = new File(['photo'], 'walk.jpg', { type: 'image/jpeg' });
    fireEvent.change(screen.getByLabelText('照片'), { target: { files: [photo] } });

    expect(screen.getByAltText('已选择照片预览：walk.jpg')).toBeTruthy();
    expect(screen.getByRole('button', { name: '保存' }).hasAttribute('disabled')).toBe(false);

    fireEvent.click(screen.getByRole('button', { name: '移除已选择照片 walk.jpg' }));

    expect(screen.queryByAltText('已选择照片预览：walk.jpg')).toBeNull();
    expect(screen.queryByRole('button', { name: '移除已选择照片 walk.jpg' })).toBeNull();
    expect(screen.getByText('没有照片')).toBeTruthy();
    expect(screen.getByRole('button', { name: '保存' }).hasAttribute('disabled')).toBe(true);
  });

  it('summarizes the current draft before saving', () => {
    render(<MomentComposer session={session} coupleSpaceId="space-1" onCreated={() => undefined} />);

    expect(screen.getByText('草稿概况')).toBeTruthy();
    expect(screen.getByText('没有照片')).toBeTruthy();
    expect(screen.getByText('0 字')).toBeTruthy();
    expect(screen.getAllByText('平静').length).toBeGreaterThan(0);
    expect(screen.getByText('未记录地点')).toBeTruthy();

    fireEvent.change(screen.getByLabelText('一句话'), { target: { value: '今天一起散步' } });
    fireEvent.change(screen.getByLabelText('地点'), { target: { value: '湖边' } });
    fireEvent.click(screen.getByRole('radio', { name: '想念' }));

    const photo = new File(['photo'], 'walk.jpg', { type: 'image/jpeg' });
    fireEvent.change(screen.getByLabelText('照片'), { target: { files: [photo] } });

    expect(screen.getByText('已选照片')).toBeTruthy();
    expect(screen.getByText('6 字')).toBeTruthy();
    expect(screen.getAllByText('想念').length).toBeGreaterThan(0);
    expect(screen.getByText('湖边')).toBeTruthy();
  });

  it('tracks draft completeness without changing save requirements', () => {
    render(<MomentComposer session={session} coupleSpaceId="space-1" onCreated={() => undefined} />);

    const progress = screen.getByRole('progressbar', { name: '记录完整度' });

    expect(screen.getByText('记录完整度 0/3')).toBeTruthy();
    expect(progress.getAttribute('aria-valuenow')).toBe('0');
    expect(screen.getByText('照片待补')).toBeTruthy();
    expect(screen.getByText('文字待写')).toBeTruthy();
    expect(screen.getByText('地点待填')).toBeTruthy();

    fireEvent.change(screen.getByLabelText('一句话'), { target: { value: '今天一起散步' } });
    fireEvent.change(screen.getByLabelText('地点'), { target: { value: '湖边' } });

    expect(screen.getByText('记录完整度 2/3')).toBeTruthy();
    expect(progress.getAttribute('aria-valuenow')).toBe('2');
    expect(screen.getByText('文字已写')).toBeTruthy();
    expect(screen.getByText('地点已填')).toBeTruthy();
    expect(screen.getByRole('button', { name: '保存' }).hasAttribute('disabled')).toBe(false);

    const photo = new File(['photo'], 'walk.jpg', { type: 'image/jpeg' });
    fireEvent.change(screen.getByLabelText('照片'), { target: { files: [photo] } });

    expect(screen.getByText('记录完整度 3/3')).toBeTruthy();
    expect(progress.getAttribute('aria-valuenow')).toBe('3');
    expect(screen.getByText('照片已添加')).toBeTruthy();
  });

  it('prevents double submission while saving', async () => {
    let resolveInsert: (value: { error: null }) => void = () => undefined;
    supabaseMock.insert.mockImplementation(
      () =>
        new Promise((resolve) => {
          resolveInsert = resolve;
        })
    );
    const onCreated = vi.fn();

    render(<MomentComposer session={session} coupleSpaceId="space-1" onCreated={onCreated} />);

    fireEvent.change(screen.getByLabelText('一句话'), { target: { value: '今天一起散步' } });
    fireEvent.click(screen.getByRole('button', { name: '保存' }));

    const savingButton = await screen.findByRole('button', { name: '保存中...' });

    expect(savingButton.hasAttribute('disabled')).toBe(true);
    expect(screen.getByRole('status').textContent).toContain('正在保存...');

    resolveInsert({ error: null });
    await waitFor(() => expect(onCreated).toHaveBeenCalledTimes(1));
  });

  it('shows next actions after saving a moment', async () => {
    render(<MomentComposer session={session} coupleSpaceId="space-1" onCreated={() => undefined} />);

    fireEvent.change(screen.getByLabelText('一句话'), { target: { value: '今天一起散步' } });
    fireEvent.click(screen.getByRole('button', { name: '保存' }));

    expect(await screen.findByText('已加入时间线')).toBeTruthy();

    const timelineLink = screen.getByRole('link', { name: '查看时间线' });
    expect(timelineLink.getAttribute('href')).toBe('#timeline-panel');

    fireEvent.click(screen.getByRole('button', { name: '继续记录' }));

    expect(screen.queryByText('已加入时间线')).toBeNull();
    expect(document.activeElement).toBe(screen.getByLabelText('一句话'));
  });
});
