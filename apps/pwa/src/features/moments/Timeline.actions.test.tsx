import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Timeline } from './Timeline';
import type { MomentRow } from './momentTypes';

const supabaseMock = vi.hoisted(() => ({
  momentRows: [] as MomentRow[],
  update: vi.fn()
}));

vi.mock('../../lib/supabase', () => ({
  supabase: {
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          order: vi.fn(() => Promise.resolve({ data: supabaseMock.momentRows, error: null }))
        }))
      })),
      update: supabaseMock.update
    })),
    storage: {
      from: vi.fn(() => ({
        createSignedUrl: vi.fn(() => Promise.resolve({ data: { signedUrl: '' }, error: null }))
      }))
    }
  }
}));

function partnerMoment(): MomentRow {
  return {
    id: 'moment-1',
    couple_space_id: 'space-1',
    creator_id: 'user-2',
    media_urls: [],
    text: '今天一起散步',
    partner_text: '',
    mood: 'happy',
    response: '',
    location_name: '湖边',
    occurred_at: '2026-06-08T11:00:00.000Z',
    created_at: '2026-06-08T11:01:00.000Z',
    updated_at: '2026-06-08T11:02:00.000Z',
    is_favorite: false,
    deleted_for_user_ids: []
  };
}

describe('Timeline actions', () => {
  beforeEach(() => {
    supabaseMock.momentRows = [partnerMoment()];
    supabaseMock.update.mockReset();
    supabaseMock.update.mockReturnValue({
      eq: vi.fn(() => Promise.resolve({ error: null }))
    });
  });

  it('toggles favorite and persists the change', async () => {
    render(<Timeline coupleSpaceId="space-1" refreshKey={0} currentUserId="user-1" />);

    const favoriteButton = await screen.findByRole('button', { name: /珍藏/ });
    expect(favoriteButton.textContent).toBe('收藏');

    fireEvent.click(favoriteButton);

    await waitFor(() => {
      expect(supabaseMock.update).toHaveBeenCalledWith({ is_favorite: true });
    });
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /珍藏/ }).textContent).toBe('珍藏');
    });
  });

  it('lets the non-creator add a partner reply', async () => {
    render(<Timeline coupleSpaceId="space-1" refreshKey={0} currentUserId="user-1" />);

    const addButton = await screen.findByRole('button', { name: '补一句话' });
    fireEvent.click(addButton);

    const input = screen.getByPlaceholderText('补一句话');
    fireEvent.change(input, { target: { value: '下次还一起去' } });
    fireEvent.click(screen.getByRole('button', { name: '保存' }));

    await waitFor(() => {
      expect(supabaseMock.update).toHaveBeenCalledWith({ partner_text: '下次还一起去' });
    });
    expect(await screen.findByText('下次还一起去')).toBeTruthy();
  });

  it('hides a moment for the current user only', async () => {
    render(<Timeline coupleSpaceId="space-1" refreshKey={0} currentUserId="user-1" />);

    const hideButton = await screen.findByRole('button', { name: '对我隐藏' });
    fireEvent.click(hideButton);

    await waitFor(() => {
      expect(supabaseMock.update).toHaveBeenCalledWith({ deleted_for_user_ids: ['user-1'] });
    });
    await waitFor(() => {
      expect(screen.queryByText('今天一起散步')).toBeNull();
    });
  });

  it('hides partner and hide controls when no current user is known', async () => {
    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    await screen.findByText('今天一起散步');
    expect(screen.queryByRole('button', { name: '补一句话' })).toBeNull();
    expect(screen.queryByRole('button', { name: '对我隐藏' })).toBeNull();
  });
});
