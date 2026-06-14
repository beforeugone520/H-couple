import {
  AnniversaryModel,
  CloudConfig,
  MemberModel,
  MemberRole,
  MomentModel,
  MomentResponse,
  MomentSyncState,
  Mood,
  RepeatType,
  SpaceModel,
  SpaceStatus
} from './MemoryModels';
import {
  readBoolean,
  readNumber,
  readRecord,
  readRecordArray,
  readString,
  readStringArray
} from '../util/MemoryUtil';

/**
 * ArkTS 是名义类型：JSON.parse 返回的是普通对象，不能直接当作 class 实例使用。
 * 这里集中负责 Record<string, Object> -> 模型类的安全映射，本地持久化与云端 REST 复用同一套。
 */

export const SNAPSHOT_VERSION: number = 1;

export interface AppSnapshot {
  version: number;
  space: SpaceModel;
  activeMemberId: string;
  moments: MomentModel[];
  anniversaries: AnniversaryModel[];
  cloud: CloudConfig;
}

// 联合字面量类型守卫：parse 出来的字符串可能非法，校验后再赋值，避免坏数据进入 UI 比较逻辑。
function toMood(value: string): Mood {
  return value === 'happy' || value === 'miss' || value === 'calm' || value === 'sad' || value === 'surprise'
    ? value as Mood
    : 'calm';
}

function toResponse(value: string): MomentResponse {
  return value === 'like' || value === 'hug' || value === 'miss_you' ? value as MomentResponse : '';
}

function toSyncState(value: string): MomentSyncState {
  return value === 'pending' || value === 'synced' || value === 'failed' ? value as MomentSyncState : 'local';
}

function toRepeatType(value: string): RepeatType {
  return value === 'none' || value === 'yearly' ? value as RepeatType : 'yearly';
}

function toSpaceStatus(value: string): SpaceStatus {
  return value === 'closed' ? 'closed' : 'active';
}

function toMemberRole(value: string): MemberRole {
  return value === 'owner' ? 'owner' : 'member';
}

function pickStringArray(row: Record<string, Object>, snakeKey: string, camelKey: string): string[] {
  const snake: string[] = readStringArray(row, snakeKey);
  return snake.length > 0 ? snake : readStringArray(row, camelKey);
}

export function momentFromRecord(row: Record<string, Object>): MomentModel {
  const moment: MomentModel = new MomentModel();
  moment.id = readString(row, 'id');
  moment.coupleSpaceId = readString(row, 'couple_space_id', readString(row, 'coupleSpaceId'));
  moment.creatorId = readString(row, 'creator_id', readString(row, 'creatorId'));
  moment.mediaUrls = pickStringArray(row, 'media_urls', 'mediaUrls');
  moment.text = readString(row, 'text');
  moment.partnerText = readString(row, 'partner_text', readString(row, 'partnerText'));
  moment.mood = toMood(readString(row, 'mood', 'calm'));
  moment.response = toResponse(readString(row, 'response'));
  moment.locationName = readString(row, 'location_name', readString(row, 'locationName'));
  moment.occurredAt = readString(row, 'occurred_at', readString(row, 'occurredAt'));
  moment.createdAt = readString(row, 'created_at', readString(row, 'createdAt'));
  moment.updatedAt = readString(row, 'updated_at', readString(row, 'updatedAt'));
  moment.isFavorite = readBoolean(row, 'is_favorite', readBoolean(row, 'isFavorite'));
  moment.deletedForUserIds = pickStringArray(row, 'deleted_for_user_ids', 'deletedForUserIds');
  // 本地专属字段：云端 row 不含这些 key 时自然回退默认（云端拉取项的 syncState 由 mergePulledMoments 置 synced）。
  moment.localMediaPaths = pickStringArray(row, 'local_media_paths', 'localMediaPaths');
  moment.syncState = toSyncState(readString(row, 'syncState', 'local'));
  moment.lastSyncError = readString(row, 'lastSyncError');
  return moment;
}

export function anniversaryFromRecord(row: Record<string, Object>): AnniversaryModel {
  const anniversary: AnniversaryModel = new AnniversaryModel();
  anniversary.id = readString(row, 'id');
  anniversary.coupleSpaceId = readString(row, 'couple_space_id', readString(row, 'coupleSpaceId'));
  anniversary.title = readString(row, 'title');
  anniversary.date = readString(row, 'date');
  anniversary.repeatType = toRepeatType(readString(row, 'repeat_type', readString(row, 'repeatType', 'yearly')));
  anniversary.reminderEnabled = readBoolean(row, 'reminder_enabled', readBoolean(row, 'reminderEnabled', true));
  anniversary.coverMediaUrl = readString(row, 'cover_media_url', readString(row, 'coverMediaUrl'));
  anniversary.createdAt = readString(row, 'created_at', readString(row, 'createdAt'));
  // 本地专属：系统提醒 id（云端不含此列）。
  anniversary.reminderId = readNumber(row, 'reminderId', -1);
  return anniversary;
}

export function memberFromRecord(row: Record<string, Object>): MemberModel {
  const member: MemberModel = new MemberModel();
  member.id = readString(row, 'id', readString(row, 'user_id'));
  member.displayName = readString(row, 'displayName', readString(row, 'display_name'));
  member.role = toMemberRole(readString(row, 'role', 'member'));
  return member;
}

export function spaceFromRecord(row: Record<string, Object>): SpaceModel {
  const space: SpaceModel = new SpaceModel();
  space.id = readString(row, 'id');
  space.inviteCode = readString(row, 'inviteCode', readString(row, 'invite_code'));
  space.status = toSpaceStatus(readString(row, 'status', 'active'));
  space.startDate = readString(row, 'startDate', readString(row, 'start_date'));
  space.createdAt = readString(row, 'createdAt', readString(row, 'created_at'));
  const memberRows: Array<Record<string, Object>> = readRecordArray(row, 'members');
  space.members = memberRows.map((memberRow: Record<string, Object>) => memberFromRecord(memberRow));
  return space;
}

export function cloudFromRecord(row: Record<string, Object>): CloudConfig {
  const cloud: CloudConfig = new CloudConfig();
  cloud.enabled = readBoolean(row, 'enabled');
  cloud.supabaseUrl = readString(row, 'supabaseUrl');
  cloud.anonKey = readString(row, 'anonKey');
  cloud.accessToken = readString(row, 'accessToken');
  cloud.userId = readString(row, 'userId');
  cloud.email = readString(row, 'email');
  cloud.coupleSpaceId = readString(row, 'coupleSpaceId');
  cloud.lastSyncAt = readString(row, 'lastSyncAt');
  return cloud;
}

export function createEmptySnapshot(): AppSnapshot {
  return {
    version: SNAPSHOT_VERSION,
    space: new SpaceModel(),
    activeMemberId: '',
    moments: [],
    anniversaries: [],
    cloud: new CloudConfig()
  };
}

// ---------- 克隆（@ObjectLink 只观察一层，修改嵌套对象需整体替换属性，故克隆出新实例）----------

function toRecord(value: Object): Record<string, Object> {
  return JSON.parse(JSON.stringify(value)) as Record<string, Object>;
}

export function cloneMoment(moment: MomentModel): MomentModel {
  return momentFromRecord(toRecord(moment));
}

export function cloneAnniversary(anniversary: AnniversaryModel): AnniversaryModel {
  return anniversaryFromRecord(toRecord(anniversary));
}

export function cloneSpace(space: SpaceModel): SpaceModel {
  return spaceFromRecord(toRecord(space));
}

export function cloneCloud(cloud: CloudConfig): CloudConfig {
  return cloudFromRecord(toRecord(cloud));
}

export function snapshotToJson(snapshot: AppSnapshot): string {
  return JSON.stringify(snapshot);
}

export function snapshotFromJson(json: string): AppSnapshot {
  const root: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
  const snapshot: AppSnapshot = createEmptySnapshot();
  snapshot.version = readNumber(root, 'version', SNAPSHOT_VERSION);
  snapshot.activeMemberId = readString(root, 'activeMemberId');
  snapshot.space = spaceFromRecord(readRecord(root, 'space'));
  snapshot.cloud = cloudFromRecord(readRecord(root, 'cloud'));
  snapshot.moments = readRecordArray(root, 'moments').map(
    (row: Record<string, Object>) => momentFromRecord(row)
  );
  snapshot.anniversaries = readRecordArray(root, 'anniversaries').map(
    (row: Record<string, Object>) => anniversaryFromRecord(row)
  );
  return snapshot;
}
