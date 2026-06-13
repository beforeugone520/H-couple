import type { Moment, MomentResponse, MomentRow, Mood, NewMomentInput } from './momentTypes';

export const moodLabels: Record<Mood, string> = {
  happy: '开心',
  miss: '想念',
  calm: '平静',
  sad: '委屈',
  surprise: '惊喜'
};

export const responseLabels: Record<Exclude<MomentResponse, ''>, string> = {
  like: '喜欢',
  hug: '抱抱',
  miss_you: '想你'
};

export function buildMomentInsert(input: NewMomentInput) {
  return {
    couple_space_id: input.coupleSpaceId,
    creator_id: input.creatorId,
    media_urls: input.mediaUrls,
    text: input.text,
    mood: input.mood,
    location_name: input.locationName,
    occurred_at: input.occurredAt
  };
}

export function normalizeMoment(row: MomentRow): Moment {
  return {
    id: row.id,
    coupleSpaceId: row.couple_space_id,
    creatorId: row.creator_id,
    mediaUrls: row.media_urls,
    text: row.text,
    partnerText: row.partner_text,
    mood: row.mood,
    response: row.response,
    locationName: row.location_name,
    occurredAt: row.occurred_at,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
    isFavorite: row.is_favorite
  };
}

export function getMomentDisplayMeta(moment: Moment) {
  const dateLabel = new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    timeZone: 'Asia/Shanghai'
  }).format(new Date(moment.occurredAt));
  const responseLabel = moment.response ? `已回应：${responseLabels[moment.response]}` : '等待回应';

  return {
    dateLabel,
    locationLabel: moment.locationName || '未记录地点',
    moodLabel: moodLabels[moment.mood],
    responseLabel
  };
}

export function getMomentMonthLabel(moment: Pick<Moment, 'occurredAt'>) {
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: 'long',
    timeZone: 'Asia/Shanghai'
  }).format(new Date(moment.occurredAt));
}
