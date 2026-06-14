import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import {
  AnniversaryModel,
  CloudConfig,
  MemberModel,
  MomentModel,
  MomentResponse,
  MomentSyncState,
  Mood,
  RepeatType,
  SpaceModel
} from '../models/MemoryModels';
import {
  AppSnapshot,
  cloneAnniversary,
  cloneCloud,
  cloneMoment,
  cloneSpace,
  SNAPSHOT_VERSION
} from '../models/MemorySerde';
import { MemoryRepository } from '../services/MemoryRepository';
import { MemoryApi, MemoryApiConfig } from '../services/MemoryApi';
import { MemoryStorage } from '../services/MemoryStorage';
import { isLocalAbsolutePath, resolveStoragePath } from '../services/MediaResolver';
import { cancelAnniversaryReminder, scheduleAnniversaryReminder } from '../services/AnniversaryReminderService';
import {
  daysUntilNextAnniversary,
  generateId,
  generateInviteCode,
  monthDayOf,
  nowIso,
  todayYmd,
  togetherDayCount,
  yearOf
} from '../util/MemoryUtil';

export type TimelineFilter = 'all' | 'mine' | 'partner' | 'favorite' | 'located';

/** 下一个纪念日视图模型，避免在 UI 层处理 null。 */
export class NextAnniversaryView {
  has: boolean = false;
  title: string = '';
  date: string = '';
  daysLeft: number = -1;
}

/**
 * 应用中枢状态。@Observed + @ObjectLink 在四个 Tab 间共享同一份数据。
 * 注意：@ObjectLink 只观察一层属性，所有修改都通过“整体替换数组/对象属性”触发刷新，
 * 并在每次变更后写入本地持久化（本地优先）。云同步为可选增强。
 */
@Observed
export class AppState {
  ready: boolean = false;
  space: SpaceModel = new SpaceModel();
  activeMemberId: string = '';
  moments: MomentModel[] = [];
  anniversaries: AnniversaryModel[] = [];
  cloud: CloudConfig = new CloudConfig();
  /** storage path -> 沙箱缓存绝对路径，渲染层据此显示已上传照片。整体替换以触发刷新；不进持久化。 */
  resolvedMedia: Map<string, string> = new Map<string, string>();

  private repo: MemoryRepository | null = null;
  private context: common.Context | null = null;
  private resolving: Set<string> = new Set<string>();
  private syncing: boolean = false;

  // ---------- 生命周期 ----------

  init(context: common.Context): void {
    this.context = context;
    this.repo = new MemoryRepository(context);
    const snapshot: AppSnapshot = this.repo.load();
    this.space = snapshot.space;
    this.moments = snapshot.moments;
    this.anniversaries = snapshot.anniversaries;
    this.cloud = snapshot.cloud;
    this.activeMemberId = snapshot.activeMemberId;
    if (this.activeMemberId.length === 0 && this.space.members.length > 0) {
      this.activeMemberId = this.space.members[0].id;
    }
    this.ready = true;
  }

  private persist(): void {
    if (this.repo === null) {
      return;
    }
    const snapshot: AppSnapshot = {
      version: SNAPSHOT_VERSION,
      space: this.space,
      activeMemberId: this.activeMemberId,
      moments: this.moments,
      anniversaries: this.anniversaries,
      cloud: this.cloud
    };
    this.repo.save(snapshot);
  }

  // ---------- 空间与成员 ----------

  isSetup(): boolean {
    return this.space.id.length > 0;
  }

  setupSpace(yourName: string, partnerName: string, startDate: string): void {
    const you: MemberModel = new MemberModel();
    you.id = generateId();
    you.displayName = yourName.trim().length > 0 ? yourName.trim() : '我';
    you.role = 'owner';

    const partner: MemberModel = new MemberModel();
    partner.id = generateId();
    partner.displayName = partnerName.trim().length > 0 ? partnerName.trim() : '对方';
    partner.role = 'member';

    const space: SpaceModel = new SpaceModel();
    space.id = generateId();
    space.inviteCode = generateInviteCode();
    space.status = 'active';
    space.startDate = startDate.length > 0 ? startDate : todayYmd();
    space.createdAt = nowIso();
    space.members = [you, partner];

    this.space = space;
    this.activeMemberId = you.id;
    this.persist();
  }

  memberById(id: string): MemberModel {
    const found: MemberModel | undefined = this.space.members.find(
      (member: MemberModel) => member.id === id
    );
    return found !== undefined ? found : new MemberModel();
  }

  memberName(id: string): string {
    const member: MemberModel = this.memberById(id);
    return member.displayName.length > 0 ? member.displayName : '成员';
  }

  activeMember(): MemberModel {
    return this.memberById(this.activeMemberId);
  }

  otherMember(): MemberModel {
    const other: MemberModel | undefined = this.space.members.find(
      (member: MemberModel) => member.id !== this.activeMemberId
    );
    return other !== undefined ? other : new MemberModel();
  }

  setActiveMember(id: string): void {
    this.activeMemberId = id;
    this.persist();
  }

  renameMember(id: string, name: string): void {
    const trimmed: string = name.trim();
    if (trimmed.length === 0) {
      return;
    }
    const space: SpaceModel = cloneSpace(this.space);
    space.members = space.members.map((member: MemberModel) => {
      if (member.id === id) {
        member.displayName = trimmed;
      }
      return member;
    });
    this.space = space;
    this.persist();
  }

  setStartDate(date: string): void {
    if (date.length === 0) {
      return;
    }
    const space: SpaceModel = cloneSpace(this.space);
    space.startDate = date;
    this.space = space;
    this.persist();
  }

  regenerateInviteCode(): void {
    const space: SpaceModel = cloneSpace(this.space);
    space.inviteCode = generateInviteCode();
    this.space = space;
    this.persist();
  }

  // ---------- 瞬间 ----------

  /** 记录一个瞬间。照片以本地沙箱路径暂存于 localMediaPaths；云同步开启时标记为 pending 待上传。 */
  addMoment(text: string, mood: Mood, locationName: string, localMediaPaths: string[]): MomentModel {
    const now: string = nowIso();
    const moment: MomentModel = new MomentModel();
    moment.id = generateId();
    moment.coupleSpaceId = this.space.id;
    moment.creatorId = this.activeMemberId;
    moment.mediaUrls = [];
    moment.localMediaPaths = localMediaPaths;
    moment.text = text.trim();
    moment.mood = mood;
    moment.locationName = locationName.trim();
    moment.occurredAt = now;
    moment.createdAt = now;
    moment.updatedAt = now;
    moment.syncState = this.cloud.enabled ? 'pending' : 'local';
    this.moments = [moment, ...this.moments];
    this.persist();
    return moment;
  }

  toggleFavorite(id: string): void {
    this.moments = this.moments.map((moment: MomentModel) => {
      if (moment.id === id) {
        const next: MomentModel = cloneMoment(moment);
        next.isFavorite = !next.isFavorite;
        next.updatedAt = nowIso();
        return next;
      }
      return moment;
    });
    this.persist();
  }

  /** 设置轻回应；再次点击相同回应则取消。 */
  setResponse(id: string, response: MomentResponse): void {
    this.moments = this.moments.map((moment: MomentModel) => {
      if (moment.id === id) {
        const next: MomentModel = cloneMoment(moment);
        next.response = next.response === response ? '' : response;
        next.updatedAt = nowIso();
        return next;
      }
      return moment;
    });
    this.persist();
  }

  setPartnerText(id: string, text: string): void {
    const trimmed: string = text.trim();
    this.moments = this.moments.map((moment: MomentModel) => {
      if (moment.id === id) {
        const next: MomentModel = cloneMoment(moment);
        next.partnerText = trimmed;
        next.updatedAt = nowIso();
        return next;
      }
      return moment;
    });
    this.persist();
  }

  /** “对自己隐藏”：当前成员从时间线移除该瞬间，但不影响对方，也不物理删除。 */
  hideForActive(id: string): void {
    this.moments = this.moments.map((moment: MomentModel) => {
      if (moment.id === id && !moment.deletedForUserIds.includes(this.activeMemberId)) {
        const next: MomentModel = cloneMoment(moment);
        next.deletedForUserIds = [...next.deletedForUserIds, this.activeMemberId];
        next.updatedAt = nowIso();
        return next;
      }
      return moment;
    });
    this.persist();
  }

  // ---------- 媒体解析与离线上传队列 ----------

  buildApiConfig(): MemoryApiConfig {
    const config: MemoryApiConfig = new MemoryApiConfig();
    config.supabaseUrl = this.cloud.supabaseUrl;
    config.anonKey = this.cloud.anonKey;
    config.accessToken = this.cloud.accessToken;
    return config;
  }

  private mediaCacheDir(): string {
    return this.context !== null ? `${this.context.filesDir}/moments_cache` : '';
  }

  /** 渲染层查询已解析的缓存绝对路径；空串表示尚未就绪。 */
  resolvedMediaPath(storagePath: string): string {
    const hit: string | undefined = this.resolvedMedia.get(storagePath);
    return hit !== undefined ? hit : '';
  }

  private setResolvedMediaPath(storagePath: string, localPath: string): void {
    const next: Map<string, string> = new Map<string, string>();
    this.resolvedMedia.forEach((value: string, key: string) => next.set(key, value));
    next.set(storagePath, localPath);
    this.resolvedMedia = next;
  }

  /** 触发某个 storage path 的异步下载到缓存（命中或飞行中则跳过）。供渲染层按需调用。 */
  requestMediaResolve(storagePath: string): void {
    if (!this.cloud.enabled || this.context === null) {
      return;
    }
    if (this.resolvedMediaPath(storagePath).length > 0 || this.resolving.has(storagePath)) {
      return;
    }
    const cacheDir: string = this.mediaCacheDir();
    if (cacheDir.length === 0) {
      return;
    }
    this.resolving.add(storagePath);
    const config: MemoryApiConfig = this.buildApiConfig();
    resolveStoragePath(config, storagePath, cacheDir).then((localPath: string) => {
      this.resolving.delete(storagePath);
      if (localPath.length > 0) {
        this.setResolvedMediaPath(storagePath, localPath);
      }
    }).catch(() => {
      this.resolving.delete(storagePath);
    });
  }

  /** 渲染层用：本地路径直接显示；storage path 命中缓存返回缓存绝对路径，未命中触发下载并返回空串（占位）。 */
  photoPathFor(path: string): string {
    if (isLocalAbsolutePath(path)) {
      return path;
    }
    const resolved: string = this.resolvedMediaPath(path);
    if (resolved.length > 0) {
      return resolved;
    }
    this.requestMediaResolve(path);
    return '';
  }

  /** 一个瞬间用于显示的全部照片路径（本地未上传 + 已上传 storage path）。 */
  displayPhotoPaths(moment: MomentModel): string[] {
    const merged: string[] = [];
    moment.localMediaPaths.forEach((path: string) => merged.push(path));
    moment.mediaUrls.forEach((path: string) => merged.push(path));
    return merged;
  }

  photoCount(moment: MomentModel): number {
    return moment.localMediaPaths.length + moment.mediaUrls.length;
  }

  markMomentSync(id: string, state: MomentSyncState, error: string): void {
    this.moments = this.moments.map((moment: MomentModel) => {
      if (moment.id === id) {
        const next: MomentModel = cloneMoment(moment);
        next.syncState = state;
        next.lastSyncError = error;
        next.updatedAt = nowIso();
        return next;
      }
      return moment;
    });
    this.persist();
  }

  pendingMoments(): MomentModel[] {
    return this.moments.filter((moment: MomentModel) =>
      moment.syncState === 'pending' || moment.syncState === 'failed'
    );
  }

  pendingCount(): number {
    return this.pendingMoments().length;
  }

  /** 把所有未同步（非 synced）的瞬间标为 pending，供首次/手动全量推送走统一队列。 */
  markAllUnsyncedPending(): void {
    this.moments = this.moments.map((moment: MomentModel) => {
      if (moment.syncState !== 'synced') {
        const next: MomentModel = cloneMoment(moment);
        next.syncState = 'pending';
        return next;
      }
      return moment;
    });
    this.persist();
  }

  /** 把上传得到的 storage path 合入 mediaUrls、清空已上传的本地路径。 */
  private applyUpload(id: string, storagePaths: string[]): void {
    this.moments = this.moments.map((moment: MomentModel) => {
      if (moment.id === id) {
        const next: MomentModel = cloneMoment(moment);
        next.mediaUrls = [...next.mediaUrls, ...storagePaths];
        next.localMediaPaths = [];
        next.updatedAt = nowIso();
        return next;
      }
      return moment;
    });
    this.persist();
  }

  /**
   * 推送前把本地身份字段映射为云端身份，满足 Supabase RLS：creator_id 必须 = auth.uid()，
   * couple_space_id 必须与上传路径/用户所属空间一致，deleted_for_user_ids 存 auth.uid 列表。
   * 注：本地优先用 generateId() 的本地成员/空间 id 与云端 auth 身份是两套，这里以“本设备登录的 cloud.userId
   * 为推送者身份”做收敛——单设备本地优先 + 可选云增强下成立；真正双向双用户协作需进一步的身份映射设计。
   */
  private toCloudMoment(moment: MomentModel): MomentModel {
    const cloudMoment: MomentModel = cloneMoment(moment);
    cloudMoment.coupleSpaceId = this.cloud.coupleSpaceId;
    cloudMoment.creatorId = this.cloud.userId;
    cloudMoment.deletedForUserIds = moment.deletedForUserIds.map((id: string) =>
      id === this.activeMemberId ? this.cloud.userId : id
    );
    return cloudMoment;
  }

  /**
   * 离线上传队列核心：把待同步瞬间的本地照片上传到 Storage（填回 mediaUrls），再推送到云端。
   * 单条失败不阻塞其它，失败标 failed 可重试。需已登录云同步；syncing 闸门防重入。
   */
  async syncPending(): Promise<void> {
    if (this.syncing || !this.cloud.enabled || this.context === null) {
      return;
    }
    this.syncing = true;
    try {
      const config: MemoryApiConfig = this.buildApiConfig();
      const api: MemoryApi = new MemoryApi(config);
      const storage: MemoryStorage = new MemoryStorage(config);
      const targets: MomentModel[] = this.pendingMoments();
      for (let index = 0; index < targets.length; index++) {
        const moment: MomentModel = targets[index];
        try {
          const uploaded: string[] = [];
          for (let j = 0; j < moment.localMediaPaths.length; j++) {
            const path: string = await storage.uploadSandboxFile(
              this.cloud.coupleSpaceId, this.cloud.userId, moment.localMediaPaths[j]
            );
            uploaded.push(path);
          }
          this.applyUpload(moment.id, uploaded);
          const refreshed: MomentModel | undefined =
            this.moments.find((item: MomentModel) => item.id === moment.id);
          if (refreshed !== undefined) {
            await api.pushMoment(this.toCloudMoment(refreshed));
          }
          this.markMomentSync(moment.id, 'synced', '');
        } catch (err) {
          const message: string = err instanceof Error ? (err as Error).message : '未知错误';
          this.markMomentSync(moment.id, 'failed', message);
        }
      }
    } finally {
      this.syncing = false;
    }
  }

  // ---------- 纪念日 ----------

  addAnniversary(title: string, date: string, repeatType: RepeatType): void {
    const trimmed: string = title.trim();
    if (trimmed.length === 0 || date.length === 0) {
      return;
    }
    const anniversary: AnniversaryModel = new AnniversaryModel();
    anniversary.id = generateId();
    anniversary.coupleSpaceId = this.space.id;
    anniversary.title = trimmed;
    anniversary.date = date;
    anniversary.repeatType = repeatType;
    anniversary.reminderEnabled = true;
    anniversary.createdAt = nowIso();
    this.anniversaries = [anniversary, ...this.anniversaries];
    this.persist();
    this.scheduleReminderFor(anniversary.id);
  }

  updateAnniversary(id: string, title: string, date: string, repeatType: RepeatType,
    reminderEnabled: boolean, coverMediaUrl: string): void {
    const trimmed: string = title.trim();
    if (trimmed.length === 0 || date.length === 0) {
      return;
    }
    const existing: AnniversaryModel | undefined =
      this.anniversaries.find((anniversary: AnniversaryModel) => anniversary.id === id);
    if (existing !== undefined && existing.reminderId >= 0) {
      cancelAnniversaryReminder(existing.reminderId);
    }
    this.anniversaries = this.anniversaries.map((anniversary: AnniversaryModel) => {
      if (anniversary.id === id) {
        const next: AnniversaryModel = cloneAnniversary(anniversary);
        next.title = trimmed;
        next.date = date;
        next.repeatType = repeatType;
        next.reminderEnabled = reminderEnabled;
        next.coverMediaUrl = coverMediaUrl;
        next.reminderId = -1;
        return next;
      }
      return anniversary;
    });
    this.persist();
    if (reminderEnabled) {
      this.scheduleReminderFor(id);
    }
  }

  setAnniversaryReminderEnabled(id: string, enabled: boolean): void {
    const existing: AnniversaryModel | undefined =
      this.anniversaries.find((anniversary: AnniversaryModel) => anniversary.id === id);
    if (existing === undefined) {
      return;
    }
    if (!enabled && existing.reminderId >= 0) {
      cancelAnniversaryReminder(existing.reminderId);
    }
    this.anniversaries = this.anniversaries.map((anniversary: AnniversaryModel) => {
      if (anniversary.id === id) {
        const next: AnniversaryModel = cloneAnniversary(anniversary);
        next.reminderEnabled = enabled;
        if (!enabled) {
          next.reminderId = -1;
        }
        return next;
      }
      return anniversary;
    });
    this.persist();
    if (enabled) {
      this.scheduleReminderFor(id);
    }
  }

  deleteAnniversary(id: string): void {
    const existing: AnniversaryModel | undefined =
      this.anniversaries.find((anniversary: AnniversaryModel) => anniversary.id === id);
    if (existing !== undefined && existing.reminderId >= 0) {
      cancelAnniversaryReminder(existing.reminderId);
    }
    this.anniversaries = this.anniversaries.filter(
      (anniversary: AnniversaryModel) => anniversary.id !== id
    );
    this.persist();
  }

  /** 发布提醒并把系统返回的 reminderId 写回（fire-and-forget，失败不影响本地保存）。 */
  private scheduleReminderFor(id: string): void {
    const target: AnniversaryModel | undefined =
      this.anniversaries.find((anniversary: AnniversaryModel) => anniversary.id === id);
    if (target === undefined || !target.reminderEnabled) {
      return;
    }
    scheduleAnniversaryReminder(target).then((reminderId: number) => {
      if (reminderId >= 0) {
        this.storeReminderId(id, reminderId);
      }
    }).catch(() => {
      // 提醒发布失败不影响纪念日本地保存。
    });
  }

  private storeReminderId(id: string, reminderId: number): void {
    this.anniversaries = this.anniversaries.map((anniversary: AnniversaryModel) => {
      if (anniversary.id === id) {
        const next: AnniversaryModel = cloneAnniversary(anniversary);
        next.reminderId = reminderId;
        return next;
      }
      return anniversary;
    });
    this.persist();
  }

  // ---------- 云同步配置（可选） ----------

  setCloudConfig(supabaseUrl: string, anonKey: string): void {
    const cloud: CloudConfig = cloneCloud(this.cloud);
    cloud.supabaseUrl = supabaseUrl.trim();
    cloud.anonKey = anonKey.trim();
    this.cloud = cloud;
    this.persist();
  }

  setCloudSession(accessToken: string, userId: string, email: string, coupleSpaceId: string): void {
    const cloud: CloudConfig = cloneCloud(this.cloud);
    cloud.accessToken = accessToken;
    cloud.userId = userId;
    cloud.email = email;
    cloud.coupleSpaceId = coupleSpaceId;
    cloud.enabled = accessToken.length > 0;
    this.cloud = cloud;
    this.persist();
  }

  markSynced(): void {
    const cloud: CloudConfig = cloneCloud(this.cloud);
    cloud.lastSyncAt = nowIso();
    this.cloud = cloud;
    this.persist();
  }

  /**
   * 用本次拉取到的远端行的最大 updated_at 推进增量水位（服务端时间轴）。
   * 避免用客户端墙钟做 since 导致的跨设备时钟偏移漏行；远端为空时保持原水位。
   */
  advanceSyncWatermark(remote: MomentModel[]): void {
    let maxTime: number = 0;
    let maxIso: string = '';
    remote.forEach((moment: MomentModel) => {
      const time: number = new Date(moment.updatedAt).getTime();
      if (!isNaN(time) && time > maxTime) {
        maxTime = time;
        maxIso = moment.updatedAt;
      }
    });
    if (maxIso.length > 0) {
      const cloud: CloudConfig = cloneCloud(this.cloud);
      cloud.lastSyncAt = maxIso;
      this.cloud = cloud;
      this.persist();
    }
  }

  clearCloud(): void {
    this.cloud = new CloudConfig();
    this.persist();
  }

  /** 合并云端拉取到的瞬间，按 updatedAt 最后写入优先。 */
  mergePulledMoments(remote: MomentModel[]): void {
    const byId: Map<string, MomentModel> = new Map<string, MomentModel>();
    this.moments.forEach((moment: MomentModel) => byId.set(moment.id, moment));
    remote.forEach((moment: MomentModel) => {
      moment.syncState = 'synced'; // 云端拉取项视为已同步，避免被误判为待上传
      const existing: MomentModel | undefined = byId.get(moment.id);
      if (existing === undefined) {
        byId.set(moment.id, moment);
        return;
      }
      const remoteTime: number = new Date(moment.updatedAt).getTime();
      const existingTime: number = new Date(existing.updatedAt).getTime();
      if (isNaN(remoteTime) || isNaN(existingTime) || remoteTime >= existingTime) {
        byId.set(moment.id, moment);
      }
    });
    const merged: MomentModel[] = [];
    byId.forEach((moment: MomentModel) => merged.push(moment));
    this.moments = merged;
    this.persist();
  }

  resetAll(): void {
    this.anniversaries.forEach((anniversary: AnniversaryModel) => {
      if (anniversary.reminderId >= 0) {
        cancelAnniversaryReminder(anniversary.reminderId);
      }
    });
    this.clearMediaCache();
    this.space = new SpaceModel();
    this.moments = [];
    this.anniversaries = [];
    this.cloud = new CloudConfig();
    this.activeMemberId = '';
    this.resolvedMedia = new Map<string, string>();
    if (this.repo !== null) {
      this.repo.clear();
    }
  }

  private clearMediaCache(): void {
    const dir: string = this.mediaCacheDir();
    if (dir.length === 0) {
      return;
    }
    try {
      fileIo.rmdirSync(dir);
    } catch (err) {
      // 缓存目录不存在或清理失败，忽略。
    }
  }

  // ---------- 选择器（派生数据） ----------

  visibleMoments(): MomentModel[] {
    const visible: MomentModel[] = this.moments.filter(
      (moment: MomentModel) => !moment.deletedForUserIds.includes(this.activeMemberId)
    );
    return visible.sort((a: MomentModel, b: MomentModel) => (a.occurredAt < b.occurredAt ? 1 : -1));
  }

  filteredMoments(filter: TimelineFilter): MomentModel[] {
    const visible: MomentModel[] = this.visibleMoments();
    if (filter === 'mine') {
      return visible.filter((moment: MomentModel) => moment.creatorId === this.activeMemberId);
    }
    if (filter === 'partner') {
      return visible.filter((moment: MomentModel) => moment.creatorId !== this.activeMemberId);
    }
    if (filter === 'favorite') {
      return visible.filter((moment: MomentModel) => moment.isFavorite);
    }
    if (filter === 'located') {
      return visible.filter((moment: MomentModel) => moment.locationName.length > 0);
    }
    return visible;
  }

  latestVisibleMoment(): MomentModel | null {
    const visible: MomentModel[] = this.visibleMoments();
    return visible.length > 0 ? visible[0] : null;
  }

  onThisDayMoments(): MomentModel[] {
    const todayMonthDay: string = monthDayOf(todayYmd());
    const currentYear: number = yearOf(todayYmd());
    return this.visibleMoments().filter((moment: MomentModel) =>
      monthDayOf(moment.occurredAt) === todayMonthDay && yearOf(moment.occurredAt) < currentYear
    );
  }

  togetherDays(): number {
    if (this.space.startDate.length === 0) {
      return 0;
    }
    return togetherDayCount(this.space.startDate, todayYmd());
  }

  nextAnniversary(): NextAnniversaryView {
    const view: NextAnniversaryView = new NextAnniversaryView();
    let bestDays: number = -1;
    this.anniversaries.forEach((anniversary: AnniversaryModel) => {
      const days: number = daysUntilNextAnniversary(monthDayOf(anniversary.date), todayYmd());
      if (days >= 0 && (bestDays < 0 || days < bestDays)) {
        bestDays = days;
        view.has = true;
        view.title = anniversary.title;
        view.date = anniversary.date;
        view.daysLeft = days;
      }
    });
    return view;
  }

  respondedCount(): number {
    return this.visibleMoments().filter((moment: MomentModel) => moment.response.length > 0).length;
  }

  favoriteCount(): number {
    return this.visibleMoments().filter((moment: MomentModel) => moment.isFavorite).length;
  }
}
