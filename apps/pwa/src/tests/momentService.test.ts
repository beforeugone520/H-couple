import { describe, expect, it } from 'vitest';
import {
  buildMomentInsert,
  getMomentDisplayMeta,
  getMomentMonthLabel,
  normalizeMoment
} from '../features/moments/momentService';

describe('momentService', () => {
  it('builds a valid moment insert payload', () => {
    const payload = buildMomentInsert({
      coupleSpaceId: 'space-1',
      creatorId: 'user-1',
      mediaUrls: ['space-1/user-1/a.jpg'],
      text: '今天一起散步',
      mood: 'happy',
      locationName: '湖边',
      occurredAt: '2026-06-08T10:00:00.000Z'
    });

    expect(payload).toEqual({
      couple_space_id: 'space-1',
      creator_id: 'user-1',
      media_urls: ['space-1/user-1/a.jpg'],
      text: '今天一起散步',
      mood: 'happy',
      location_name: '湖边',
      occurred_at: '2026-06-08T10:00:00.000Z'
    });
  });

  it('normalizes database fields for UI usage', () => {
    const moment = normalizeMoment({
      id: 'moment-1',
      couple_space_id: 'space-1',
      creator_id: 'user-1',
      media_urls: ['space-1/user-1/a.jpg'],
      text: '晚饭很好吃',
      partner_text: '下次还去',
      mood: 'calm',
      response: 'like',
      location_name: '小店',
      occurred_at: '2026-06-08T11:00:00.000Z',
      created_at: '2026-06-08T11:01:00.000Z',
      updated_at: '2026-06-08T11:02:00.000Z',
      is_favorite: true
    });

    expect(moment).toEqual({
      id: 'moment-1',
      coupleSpaceId: 'space-1',
      creatorId: 'user-1',
      mediaUrls: ['space-1/user-1/a.jpg'],
      text: '晚饭很好吃',
      partnerText: '下次还去',
      mood: 'calm',
      response: 'like',
      locationName: '小店',
      occurredAt: '2026-06-08T11:00:00.000Z',
      createdAt: '2026-06-08T11:01:00.000Z',
      updatedAt: '2026-06-08T11:02:00.000Z',
      isFavorite: true
    });
  });

  it('builds stable display metadata for a moment card', () => {
    const meta = getMomentDisplayMeta({
      id: 'moment-1',
      coupleSpaceId: 'space-1',
      creatorId: 'user-1',
      mediaUrls: [],
      text: '晚饭很好吃',
      partnerText: '',
      mood: 'miss',
      response: 'hug',
      locationName: '',
      occurredAt: '2026-06-08T11:00:00.000Z',
      createdAt: '2026-06-08T11:01:00.000Z',
      updatedAt: '2026-06-08T11:02:00.000Z',
      isFavorite: false
    });

    expect(meta).toEqual({
      dateLabel: '2026年6月8日',
      locationLabel: '未记录地点',
      moodLabel: '想念',
      responseLabel: '已回应：抱抱'
    });
  });

  it('builds a stable month label for timeline grouping', () => {
    expect(getMomentMonthLabel({ occurredAt: '2026-06-08T11:00:00.000Z' })).toBe('2026年6月');
  });
});
