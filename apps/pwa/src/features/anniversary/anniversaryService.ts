import type { Anniversary, AnniversaryRow } from '../moments/momentTypes';

export function normalizeAnniversary(row: AnniversaryRow): Anniversary {
  return {
    id: row.id,
    coupleSpaceId: row.couple_space_id,
    title: row.title,
    date: row.date,
    repeatType: row.repeat_type,
    reminderEnabled: row.reminder_enabled,
    coverMediaUrl: row.cover_media_url ?? ''
  };
}

/** 距离下一个「每年」纪念日还有多少天（今天即纪念日返回 0；非法日期返回 -1）。 */
export function daysUntilNextAnniversary(date: string, today: Date): number {
  const target = new Date(date);
  if (Number.isNaN(target.getTime())) {
    return -1;
  }

  const month = target.getMonth();
  const day = target.getDate();
  const todayMidnight = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  let next = new Date(today.getFullYear(), month, day);
  if (next.getTime() < todayMidnight.getTime()) {
    next = new Date(today.getFullYear() + 1, month, day);
  }

  const msPerDay = 1000 * 60 * 60 * 24;
  return Math.round((next.getTime() - todayMidnight.getTime()) / msPerDay);
}

export function countdownLabel(days: number): string {
  if (days < 0) {
    return '日期待确认';
  }
  if (days === 0) {
    return '就是今天';
  }
  return `还有 ${days} 天`;
}

export function formatAnniversaryDate(date: string): string {
  const parsed = new Date(date);
  if (Number.isNaN(parsed.getTime())) {
    return date;
  }
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    timeZone: 'Asia/Shanghai'
  }).format(parsed);
}
