import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Timeline } from './Timeline';
import type { MomentRow } from './momentTypes';

const supabaseMock = vi.hoisted(() => ({
  momentRows: [] as MomentRow[],
  loadError: null as null | { message: string },
  signedUrl: 'https://example.test/photo.jpg',
  update: vi.fn()
}));

vi.mock('../../lib/supabase', () => ({
  supabase: {
    from: vi.fn(() => ({
      select: vi.fn(() => ({
        eq: vi.fn(() => ({
          order: vi.fn(() => Promise.resolve({ data: supabaseMock.momentRows, error: supabaseMock.loadError }))
        }))
      })),
      update: supabaseMock.update
    })),
    storage: {
      from: vi.fn(() => ({
        createSignedUrl: vi.fn(() => Promise.resolve({ data: { signedUrl: supabaseMock.signedUrl }, error: null }))
      }))
    }
  }
}));

describe('Timeline', () => {
  beforeEach(() => {
    supabaseMock.momentRows = [];
    supabaseMock.loadError = null;
    supabaseMock.signedUrl = 'https://example.test/photo.jpg';
    supabaseMock.update.mockReset();
    supabaseMock.update.mockReturnValue({
      eq: vi.fn(() => Promise.resolve({ error: null }))
    });
  });

  it('shows an actionable empty state when there are no moments', async () => {
    render(
      <>
        <section id="moment-composer" />
        <Timeline coupleSpaceId="space-1" refreshKey={0} />
      </>
    );

    expect(await screen.findByText('还没有共同瞬间。')).toBeTruthy();
    expect(screen.getByText('下一步')).toBeTruthy();
    expect(screen.getByText('添加照片或一句话')).toBeTruthy();
    expect(screen.getByText('保存后自动出现在时间线')).toBeTruthy();

    const action = screen.getByRole('link', { name: '记录第一个瞬间' });
    expect(action.getAttribute('href')).toBe('#moment-composer');
  });

  it('shows a retry action instead of the empty state when loading fails', async () => {
    supabaseMock.loadError = { message: '网络暂时不可用' };

    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    expect(await screen.findByText('网络暂时不可用')).toBeTruthy();
    expect(screen.getByText('加载失败').className).toContain('count-pill-error');
    expect(screen.queryByText('还没有共同瞬间。')).toBeNull();

    supabaseMock.loadError = null;
    fireEvent.click(screen.getByRole('button', { name: '重新加载时间线' }));

    expect(await screen.findByText('还没有共同瞬间。')).toBeTruthy();
  });

  it('describes moment photos with date and location context', async () => {
    supabaseMock.momentRows = [
      {
        id: 'moment-1',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: ['space-1/user-1/walk.jpg'],
        text: '今天一起散步',
        partner_text: '',
        mood: 'happy',
        response: '',
        location_name: '湖边',
        occurred_at: '2026-06-08T11:00:00.000Z',
        created_at: '2026-06-08T11:01:00.000Z',
        updated_at: '2026-06-08T11:02:00.000Z',
        is_favorite: false
      }
    ];

    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    const photo = await screen.findByAltText('2026年6月8日，湖边的共同瞬间照片');

    expect(photo.getAttribute('src')).toBe('https://example.test/photo.jpg');
  });

  it('shows a compact media count when a moment has multiple photos', async () => {
    supabaseMock.momentRows = [
      {
        id: 'moment-1',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: ['space-1/user-1/walk-1.jpg', 'space-1/user-1/walk-2.jpg'],
        text: '今天一起散步',
        partner_text: '',
        mood: 'happy',
        response: '',
        location_name: '湖边',
        occurred_at: '2026-06-08T11:00:00.000Z',
        created_at: '2026-06-08T11:01:00.000Z',
        updated_at: '2026-06-08T11:02:00.000Z',
        is_favorite: false
      }
    ];

    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    expect(await screen.findByAltText('2026年6月8日，湖边的共同瞬间照片')).toBeTruthy();
    expect(screen.getByText('2 张照片')).toBeTruthy();
  });

  it('gives repeated response buttons moment context for assistive tech', async () => {
    supabaseMock.momentRows = [
      {
        id: 'moment-1',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '今天一起散步',
        partner_text: '',
        mood: 'happy',
        response: '',
        location_name: '湖边',
        occurred_at: '2026-06-08T11:00:00.000Z',
        created_at: '2026-06-08T11:01:00.000Z',
        updated_at: '2026-06-08T11:02:00.000Z',
        is_favorite: false
      }
    ];

    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    const likeButton = await screen.findByRole('button', {
      name: '用喜欢回应 2026年6月8日，湖边的共同瞬间'
    });

    expect(likeButton.getAttribute('aria-pressed')).toBe('false');
  });

  it('renders response status as pending or success chips', async () => {
    supabaseMock.momentRows = [
      {
        id: 'moment-1',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '今天一起散步',
        partner_text: '',
        mood: 'happy',
        response: '',
        location_name: '湖边',
        occurred_at: '2026-06-08T11:00:00.000Z',
        created_at: '2026-06-08T11:01:00.000Z',
        updated_at: '2026-06-08T11:02:00.000Z',
        is_favorite: false
      },
      {
        id: 'moment-2',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '晚上一起做饭',
        partner_text: '',
        mood: 'calm',
        response: 'hug',
        location_name: '',
        occurred_at: '2026-06-07T11:00:00.000Z',
        created_at: '2026-06-07T11:01:00.000Z',
        updated_at: '2026-06-07T11:02:00.000Z',
        is_favorite: false
      }
    ];

    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    const pendingState = await screen.findByText('等待回应');
    const successState = await screen.findByText('已回应：抱抱');

    expect(pendingState.className).toContain('response-state-pending');
    expect(successState.className).toContain('response-state-success');
  });

  it('shows the selected response as explicit confirmation copy', async () => {
    supabaseMock.momentRows = [
      {
        id: 'moment-1',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '晚上一起做饭',
        partner_text: '',
        mood: 'calm',
        response: 'hug',
        location_name: '',
        occurred_at: '2026-06-07T11:00:00.000Z',
        created_at: '2026-06-07T11:01:00.000Z',
        updated_at: '2026-06-07T11:02:00.000Z',
        is_favorite: false
      }
    ];

    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    expect(await screen.findByText('你的回应：抱抱')).toBeTruthy();
  });

  it('summarizes timeline activity for quick scanning', async () => {
    supabaseMock.momentRows = [
      {
        id: 'moment-1',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '今天一起散步',
        partner_text: '',
        mood: 'happy',
        response: '',
        location_name: '湖边',
        occurred_at: '2026-06-08T11:00:00.000Z',
        created_at: '2026-06-08T11:01:00.000Z',
        updated_at: '2026-06-08T11:02:00.000Z',
        is_favorite: false
      },
      {
        id: 'moment-2',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '晚上一起做饭',
        partner_text: '',
        mood: 'calm',
        response: 'hug',
        location_name: '',
        occurred_at: '2026-06-07T11:00:00.000Z',
        created_at: '2026-06-07T11:01:00.000Z',
        updated_at: '2026-06-07T11:02:00.000Z',
        is_favorite: false
      }
    ];

    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    expect(await screen.findByText('2 条瞬间')).toBeTruthy();
    expect(screen.getByText('1 条已回应')).toBeTruthy();
    expect(screen.getByText('最新 2026年6月8日')).toBeTruthy();
  });

  it('surfaces favorite moments in the summary and moment header', async () => {
    supabaseMock.momentRows = [
      {
        id: 'moment-1',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '今天一起散步',
        partner_text: '',
        mood: 'happy',
        response: '',
        location_name: '湖边',
        occurred_at: '2026-06-08T11:00:00.000Z',
        created_at: '2026-06-08T11:01:00.000Z',
        updated_at: '2026-06-08T11:02:00.000Z',
        is_favorite: true
      },
      {
        id: 'moment-2',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '晚上一起做饭',
        partner_text: '',
        mood: 'calm',
        response: 'hug',
        location_name: '',
        occurred_at: '2026-06-07T11:00:00.000Z',
        created_at: '2026-06-07T11:01:00.000Z',
        updated_at: '2026-06-07T11:02:00.000Z',
        is_favorite: false
      }
    ];

    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    expect(await screen.findByText('1 条珍藏')).toBeTruthy();
    expect(screen.getAllByText('珍藏')).toHaveLength(1);
  });

  it('groups moments with month dividers for long timeline scanning', async () => {
    supabaseMock.momentRows = [
      {
        id: 'moment-1',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '六月散步',
        partner_text: '',
        mood: 'happy',
        response: '',
        location_name: '湖边',
        occurred_at: '2026-06-08T11:00:00.000Z',
        created_at: '2026-06-08T11:01:00.000Z',
        updated_at: '2026-06-08T11:02:00.000Z',
        is_favorite: false
      },
      {
        id: 'moment-2',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '六月晚饭',
        partner_text: '',
        mood: 'calm',
        response: 'hug',
        location_name: '',
        occurred_at: '2026-06-07T11:00:00.000Z',
        created_at: '2026-06-07T11:01:00.000Z',
        updated_at: '2026-06-07T11:02:00.000Z',
        is_favorite: false
      },
      {
        id: 'moment-3',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '五月电影',
        partner_text: '',
        mood: 'miss',
        response: '',
        location_name: '影院',
        occurred_at: '2026-05-18T11:00:00.000Z',
        created_at: '2026-05-18T11:01:00.000Z',
        updated_at: '2026-05-18T11:02:00.000Z',
        is_favorite: false
      }
    ];

    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    expect(await screen.findByRole('heading', { name: '2026年6月' })).toBeTruthy();
    expect(screen.getByRole('heading', { name: '2026年5月' })).toBeTruthy();
    expect(screen.getAllByText('2026年6月')).toHaveLength(1);
  });

  it('shows pending feedback while saving a response', async () => {
    let resolveUpdate: (value: { error: null }) => void = () => undefined;
    supabaseMock.update.mockReturnValue({
      eq: vi.fn(
        () =>
          new Promise((resolve) => {
            resolveUpdate = resolve;
          })
      )
    });
    supabaseMock.momentRows = [
      {
        id: 'moment-1',
        couple_space_id: 'space-1',
        creator_id: 'user-1',
        media_urls: [],
        text: '今天一起散步',
        partner_text: '',
        mood: 'happy',
        response: '',
        location_name: '湖边',
        occurred_at: '2026-06-08T11:00:00.000Z',
        created_at: '2026-06-08T11:01:00.000Z',
        updated_at: '2026-06-08T11:02:00.000Z',
        is_favorite: false
      }
    ];

    render(<Timeline coupleSpaceId="space-1" refreshKey={0} />);

    fireEvent.click(
      await screen.findByRole('button', {
        name: '用喜欢回应 2026年6月8日，湖边的共同瞬间'
      })
    );

    const pendingButton = await screen.findByRole('button', {
      name: '正在用喜欢回应 2026年6月8日，湖边的共同瞬间'
    });

    expect(pendingButton.textContent).toBe('回应中...');
    expect(pendingButton.hasAttribute('disabled')).toBe(true);
    expect(pendingButton.getAttribute('aria-busy')).toBe('true');

    resolveUpdate({ error: null });
    await waitFor(() => {
      expect(
        screen.getByRole('button', {
          name: '用喜欢回应 2026年6月8日，湖边的共同瞬间'
        }).getAttribute('aria-pressed')
      ).toBe('true');
    });
  });
});
