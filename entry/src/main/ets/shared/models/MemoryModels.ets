export type Mood = 'happy' | 'miss' | 'calm' | 'sad' | 'surprise';
export type MomentResponse = '' | 'like' | 'hug' | 'miss_you';
export type MemberRole = 'owner' | 'member';
export type RepeatType = 'none' | 'yearly';
export type SpaceStatus = 'active' | 'closed';

/** 共同记忆瞬间。字段与 docs/api/supabase-schema.sql 的 moments 表对齐。 */
export class MomentModel {
  id: string = '';
  coupleSpaceId: string = '';
  creatorId: string = '';
  mediaUrls: string[] = [];
  text: string = '';
  partnerText: string = '';
  mood: Mood = 'calm';
  response: MomentResponse = '';
  locationName: string = '';
  occurredAt: string = '';
  createdAt: string = '';
  updatedAt: string = '';
  isFavorite: boolean = false;
  /** “对自己隐藏”语义：列表里包含某成员 id 时，对其隐藏，但不物理删除共同记忆。 */
  deletedForUserIds: string[] = [];
}

/** 纪念日 / 倒数日。字段与 anniversaries 表对齐。 */
export class AnniversaryModel {
  id: string = '';
  coupleSpaceId: string = '';
  title: string = '';
  date: string = '';
  repeatType: RepeatType = 'yearly';
  reminderEnabled: boolean = true;
  coverMediaUrl: string = '';
  createdAt: string = '';
}

/** 双人空间成员。第一版每个空间最多两个成员。 */
export class MemberModel {
  id: string = '';
  displayName: string = '';
  role: MemberRole = 'member';
}

/** 双人空间。本地优先：space.id 为空表示尚未建立空间。 */
export class SpaceModel {
  id: string = '';
  inviteCode: string = '';
  status: SpaceStatus = 'active';
  /** 在一起的起始日期（YYYY-MM-DD），用于“在一起第 N 天”。 */
  startDate: string = '';
  createdAt: string = '';
  members: MemberModel[] = [];
}

/**
 * 可选云同步配置。真实 Supabase URL / anon key / access token 只能在运行时注入，
 * 不在源码中硬编码（见 AGENTS.md）。enabled 为 false 时应用以纯本地模式运行。
 */
export class CloudConfig {
  enabled: boolean = false;
  supabaseUrl: string = '';
  anonKey: string = '';
  accessToken: string = '';
  userId: string = '';
  email: string = '';
  coupleSpaceId: string = '';
  lastSyncAt: string = '';
}
