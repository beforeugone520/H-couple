import { fireEvent, render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Anniversaries } from './Anniversaries';
import type { AnniversaryRow } from '../moments/momentTypes';

const supabaseMock = vi.hoisted(() => ({
  rows: [] as AnniversaryRow[],
  loadError: null as null | { message: string }
}));

vi.mock('../../lib/supabase', () => ({
  supabase: {
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          order: vi.fn(() => Promise.resolve({ data: supabaseMock.rows, error: supabaseMock.loadError }))
        }))
      }))
    }))
  }
}));

describe('Anniversaries', () => {
  beforeEach(() => {
    supabaseMock.rows = [];
    supabaseMock.loadError = null;
  });

  it('shows an empty hint when there are no anniversaries', async () => {
    render(<Anniversaries coupleSpaceId="space-1" />);

    expect(
      await screen.findByText('还没有纪念日。可在 HarmonyOS 端「我们」里添加第一次见面、生日或旅行纪念日。')
    ).toBeTruthy();
  });

  it('lists anniversaries with a countdown', async () => {
    supabaseMock.rows = [
      {
        id: 'anniversary-1',
        couple_space_id: 'space-1',
        title: '第一次见面',
        date: '2025-03-09',
        repeat_type: 'yearly',
        reminder_enabled: true,
        cover_media_url: null
      }
    ];

    render(<Anniversaries coupleSpaceId="space-1" />);

    expect(await screen.findByText('第一次见面')).toBeTruthy();
    expect(screen.getByText((content) => content.startsWith('还有') || content === '就是今天')).toBeTruthy();
  });

  it('surfaces a load error message', async () => {
    supabaseMock.loadError = { message: '网络暂时不可用' };

    render(<Anniversaries coupleSpaceId="space-1" />);

    expect(await screen.findByText('网络暂时不可用')).toBeTruthy();
    expect(screen.getByText('纪念日暂时无法加载，请稍后再试。')).toBeTruthy();
  });
});
