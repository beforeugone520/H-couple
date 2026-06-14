import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { AnniversaryModel } from '../models/MemoryModels';

/**
 * 纪念日通知提醒（纯本地系统能力，不依赖云同步）。
 * 用 reminderAgentManager 发布日历提醒：repeatType==='yearly' 时用 repeatMonths/repeatDays 实现年度重复。
 * 发布失败一律降级（返回 -1 / 静默），不阻塞纪念日的本地保存。
 * 需要 module.json5 声明 ohos.permission.PUBLISH_AGENT_REMINDER（system_grant，免运行时弹窗）。
 */

const REMINDER_HOUR: number = 9;

function hashToId(id: string): number {
  let hash: number = 0;
  for (let index = 0; index < id.length; index++) {
    hash = (hash * 31 + id.charCodeAt(index)) | 0;
  }
  return Math.abs(hash);
}

/** 年度重复时，取今年或明年（若今年该日已过）作为首次触发年份。 */
function firstTriggerYear(month: number, day: number): number {
  const today: Date = new Date();
  const candidate: Date = new Date(today.getFullYear(), month - 1, day, REMINDER_HOUR, 0, 0);
  return candidate.getTime() >= today.getTime() ? today.getFullYear() : today.getFullYear() + 1;
}

/** 发布纪念日提醒，返回系统分配的 reminderId（用于后续 cancel）。失败返回 -1。 */
export async function scheduleAnniversaryReminder(anniversary: AnniversaryModel): Promise<number> {
  const ymd: string = anniversary.date.length >= 10 ? anniversary.date.substring(0, 10) : anniversary.date;
  const parts: string[] = ymd.split('-');
  if (parts.length !== 3) {
    return -1;
  }
  const year: number = Number(parts[0]);
  const month: number = Number(parts[1]);
  const day: number = Number(parts[2]);
  if (isNaN(year) || isNaN(month) || isNaN(day) || month < 1 || month > 12 || day < 1 || day > 31) {
    return -1;
  }
  const isYearly: boolean = anniversary.repeatType === 'yearly';
  const triggerYear: number = isYearly ? firstTriggerYear(month, day) : year;

  const request: reminderAgentManager.ReminderRequestCalendar = {
    reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
    dateTime: { year: triggerYear, month: month, day: day, hour: REMINDER_HOUR, minute: 0, second: 0 },
    repeatMonths: isYearly ? [month] : [],
    repeatDays: isYearly ? [day] : [],
    title: anniversary.title,
    content: '今天是你们的纪念日',
    notificationId: hashToId(anniversary.id),
    slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION
  };

  try {
    return await reminderAgentManager.publishReminder(request);
  } catch (err) {
    return -1;
  }
}

/** 取消已发布的提醒；reminderId<0 或失败时静默。 */
export async function cancelAnniversaryReminder(reminderId: number): Promise<void> {
  if (reminderId < 0) {
    return;
  }
  try {
    await reminderAgentManager.cancelReminder(reminderId);
  } catch (err) {
    // 已取消或无效 id，忽略。
  }
}
