import { util } from '@kit.ArkTS';
import { Mood, MomentResponse } from '../models/MemoryModels';

/**
 * 共享纯函数工具：ID/邀请码生成、日期计算、JSON 安全读取、文案映射。
 * 这些函数不依赖 UI，可被状态层、服务层和页面层复用，避免逻辑散落。
 */

// ---------- ID / 邀请码 ----------

export function generateId(): string {
  return util.generateRandomUUID(true);
}

export function generateInviteCode(): string {
  const raw: string = util.generateRandomUUID(false).replace(/-/g, '');
  return raw.substring(0, 6).toUpperCase();
}

export function normalizeInviteCode(input: string): string {
  return input.replace(/\s/g, '').toUpperCase();
}

// ---------- JSON 安全读取（ArkTS 名义类型：parse 得到普通对象，按字段安全取值）----------

export function readString(row: Record<string, Object>, key: string, fallback: string = ''): string {
  const value: Object | undefined = row[key];
  return typeof value === 'string' ? value as string : fallback;
}

export function readBoolean(row: Record<string, Object>, key: string, fallback: boolean = false): boolean {
  const value: Object | undefined = row[key];
  return typeof value === 'boolean' ? value as boolean : fallback;
}

export function readNumber(row: Record<string, Object>, key: string, fallback: number = 0): number {
  const value: Object | undefined = row[key];
  return typeof value === 'number' ? value as number : fallback;
}

export function readStringArray(row: Record<string, Object>, key: string): string[] {
  const value: Object | undefined = row[key];
  const out: string[] = [];
  if (Array.isArray(value)) {
    (value as Object[]).forEach((item: Object) => {
      if (typeof item === 'string') {
        out.push(item as string);
      }
    });
  }
  return out;
}

export function readRecordArray(row: Record<string, Object>, key: string): Array<Record<string, Object>> {
  const value: Object | undefined = row[key];
  if (Array.isArray(value)) {
    return value as Array<Record<string, Object>>;
  }
  return [];
}

export function readRecord(row: Record<string, Object>, key: string): Record<string, Object> {
  const value: Object | undefined = row[key];
  if (value !== undefined && value !== null && typeof value === 'object' && !Array.isArray(value)) {
    return value as Record<string, Object>;
  }
  return {};
}

// ---------- 日期 ----------

export function nowIso(): string {
  return new Date().toISOString();
}

export function todayYmd(): string {
  return formatYmd(new Date());
}

export function formatYmd(date: Date): string {
  const year: number = date.getFullYear();
  const month: string = String(date.getMonth() + 1).padStart(2, '0');
  const day: string = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/** 把任意 ISO/YMD 字符串截断成 YYYY-MM-DD 展示。 */
export function ymdOf(iso: string): string {
  if (iso.length >= 10) {
    return iso.substring(0, 10);
  }
  return iso;
}

/** 返回 'MM-DD'，用于纪念日/某年今日匹配。 */
export function monthDayOf(iso: string): string {
  const ymd: string = ymdOf(iso);
  if (ymd.length >= 10) {
    return ymd.substring(5, 10);
  }
  return '';
}

/** B 减 A 的整天数，可为负。基于本地午夜对齐，避免时区误差。 */
export function daysBetween(isoA: string, isoB: string): number {
  const a: Date = atLocalMidnight(isoA);
  const b: Date = atLocalMidnight(isoB);
  const msPerDay: number = 1000 * 60 * 60 * 24;
  return Math.round((b.getTime() - a.getTime()) / msPerDay);
}

/** 在一起第 N 天：起始日当天记为第 1 天。 */
export function togetherDayCount(startIso: string, todayIso: string): number {
  const diff: number = daysBetween(startIso, todayIso);
  return diff >= 0 ? diff + 1 : 0;
}

/** 距离下一个「每年」纪念日还有多少天（今天即纪念日返回 0）。 */
export function daysUntilNextAnniversary(monthDay: string, todayIso: string): number {
  const parts: string[] = monthDay.split('-');
  if (parts.length !== 2) {
    return -1;
  }
  const month: number = Number(parts[0]);
  const day: number = Number(parts[1]);
  const today: Date = atLocalMidnight(todayIso);
  const thisYear: Date = new Date(today.getFullYear(), month - 1, day);
  const msPerDay: number = 1000 * 60 * 60 * 24;
  if (thisYear.getTime() >= today.getTime()) {
    return Math.round((thisYear.getTime() - today.getTime()) / msPerDay);
  }
  const nextYear: Date = new Date(today.getFullYear() + 1, month - 1, day);
  return Math.round((nextYear.getTime() - today.getTime()) / msPerDay);
}

export function isSameMonthDay(isoA: string, isoB: string): boolean {
  return monthDayOf(isoA) === monthDayOf(isoB) && monthDayOf(isoA).length > 0;
}

export function isValidYmd(value: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }
  const date: Date = new Date(value);
  return !isNaN(date.getTime());
}

export function coerceYmd(value: string, fallback: string): string {
  const trimmed: string = value.trim();
  return isValidYmd(trimmed) ? trimmed : fallback;
}

export function yearOf(iso: string): number {
  const ymd: string = ymdOf(iso);
  if (ymd.length >= 4) {
    return Number(ymd.substring(0, 4));
  }
  return 0;
}

function atLocalMidnight(iso: string): Date {
  const source: Date = new Date(iso);
  return new Date(source.getFullYear(), source.getMonth(), source.getDate());
}

// ---------- 文案映射 ----------

export function moodLabel(mood: Mood): string {
  if (mood === 'happy') {
    return '开心';
  }
  if (mood === 'miss') {
    return '想念';
  }
  if (mood === 'sad') {
    return '委屈';
  }
  if (mood === 'surprise') {
    return '惊喜';
  }
  return '平静';
}

export function responseLabel(response: MomentResponse): string {
  if (response === 'like') {
    return '喜欢';
  }
  if (response === 'hug') {
    return '抱抱';
  }
  if (response === 'miss_you') {
    return '想你';
  }
  return '已回应';
}

/** YYYY年M月，用于时间线月份分组和相册聚合。 */
export function monthLabelOf(iso: string): string {
  const ymd: string = ymdOf(iso);
  if (ymd.length < 7) {
    return '未知月份';
  }
  const year: string = ymd.substring(0, 4);
  const monthText: string = ymd.substring(5, 7);
  const month: string = monthText.startsWith('0') ? monthText.substring(1, 2) : monthText;
  return `${year}年${month}月`;
}
