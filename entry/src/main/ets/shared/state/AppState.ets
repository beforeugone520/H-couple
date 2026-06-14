import { common } from '@kit.AbilityKit';
import {
  AnniversaryModel,
  CloudConfig,
  MemberModel,
  MomentModel,
  MomentResponse,
  Mood,
  RepeatType,
  SpaceModel
} from '../models/MemoryModels';
import {
  AppSnapshot,
  cloneCloud,
  cloneMoment,
  cloneSpace,
  SNAPSHOT_VERSION
} from '../models/MemorySerde';
import { MemoryRepository } from '../services/MemoryRepository';
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

  private repo: MemoryRepository | null = null;

  // ---------- 生命周期 ----------

  init(context: common.Context): void {
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

  addMoment(text: string, mood: Mood, locationName: string, mediaUrls: string[]): void {
    const now: string = nowIso();
    const moment: MomentModel = new MomentModel();
    moment.id = generateId();
    moment.coupleSpaceId = this.space.id;
    moment.creatorId = this.activeMemberId;
    moment.mediaUrls = mediaUrls;
    moment.text = text.trim();
    moment.mood = mood;
    moment.locationName = locationName.trim();
    moment.occurredAt = now;
    moment.createdAt = now;
    moment.updatedAt = now;
    this.moments = [moment, ...this.moments];
    this.persist();
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
  }

  deleteAnniversary(id: string): void {
    this.anniversaries = this.anniversaries.filter(
      (anniversary: AnniversaryModel) => anniversary.id !== id
    );
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

  clearCloud(): void {
    this.cloud = new CloudConfig();
    this.persist();
  }

  /** 合并云端拉取到的瞬间，按 updatedAt 最后写入优先。 */
  mergePulledMoments(remote: MomentModel[]): void {
    const byId: Map<string, MomentModel> = new Map<string, MomentModel>();
    this.moments.forEach((moment: MomentModel) => byId.set(moment.id, moment));
    remote.forEach((moment: MomentModel) => {
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
    this.space = new SpaceModel();
    this.moments = [];
    this.anniversaries = [];
    this.cloud = new CloudConfig();
    this.activeMemberId = '';
    if (this.repo !== null) {
      this.repo.clear();
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
