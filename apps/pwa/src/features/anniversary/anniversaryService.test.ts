import { describe, expect, it } from 'vitest';
import {
  countdownLabel,
  daysUntilNextAnniversary,
  formatAnniversaryDate,
  normalizeAnniversary
} from './anniversaryService';

describe('anniversaryService', () => {
  it('normalizes database fields for UI usage', () => {
    const anniversary = normalizeAnniversary({
      id: 'anniversary-1',
      couple_space_id: 'space-1',
      title: '第一次见面',
      date: '2025-03-09',
      repeat_type: 'yearly',
      reminder_enabled: true,
      cover_media_url: null
    });

    expect(anniversary).toEqual({
      id: 'anniversary-1',
      coupleSpaceId: 'space-1',
      title: '第一次见面',
      date: '2025-03-09',
      repeatType: 'yearly',
      reminderEnabled: true,
      coverMediaUrl: ''
    });
  });

  it('returns 0 when the anniversary month-day is today', () => {
    const today = new Date(2026, 5, 14);
    expect(daysUntilNextAnniversary('2020-06-14', today)).toBe(0);
  });

  it('counts days to the next occurrence later this year', () => {
    const today = new Date(2026, 5, 14);
    expect(daysUntilNextAnniversary('2020-06-15', today)).toBe(1);
  });

  it('wraps to next year when this year has passed', () => {
    const today = new Date(2026, 5, 14);
    expect(daysUntilNextAnniversary('2020-06-13', today)).toBeGreaterThan(360);
  });

  it('returns -1 for an unparseable date', () => {
    const today = new Date(2026, 5, 14);
    expect(daysUntilNextAnniversary('', today)).toBe(-1);
  });

  it('builds friendly countdown copy', () => {
    expect(countdownLabel(0)).toBe('就是今天');
    expect(countdownLabel(1)).toBe('还有 1 天');
    expect(countdownLabel(-1)).toBe('日期待确认');
  });

  it('formats anniversary dates in zh-CN', () => {
    expect(formatAnniversaryDate('2025-03-09')).toContain('2025');
  });
});
