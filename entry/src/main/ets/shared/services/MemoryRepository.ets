import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AppSnapshot, createEmptySnapshot, snapshotFromJson, snapshotToJson } from '../models/MemorySerde';

/**
 * 本地优先持久化层：把整个应用快照以 JSON 字符串存进 Preferences。
 * Preferences 是应用沙箱内的键值存储，UIAbility 与桌面卡片扩展共享同一沙箱，
 * 因此卡片可以读取主端写入的同一份数据（见 docs：本地缓存 / 离线草稿）。
 */

const PREF_NAME: string = 'memorybox_state';
const SNAPSHOT_KEY: string = 'snapshot';

export class MemoryRepository {
  private prefs: preferences.Preferences;

  constructor(context: common.Context) {
    this.prefs = preferences.getPreferencesSync(context, { name: PREF_NAME });
  }

  load(): AppSnapshot {
    try {
      const raw: string = this.prefs.getSync(SNAPSHOT_KEY, '') as string;
      if (raw.length === 0) {
        return createEmptySnapshot();
      }
      return snapshotFromJson(raw);
    } catch (err) {
      // 损坏或不兼容的数据回退为空快照，保证应用始终可启动。
      return createEmptySnapshot();
    }
  }

  save(snapshot: AppSnapshot): void {
    const json: string = snapshotToJson(snapshot);
    this.prefs.putSync(SNAPSHOT_KEY, json);
    this.prefs.flushSync();
  }

  clear(): void {
    this.prefs.deleteSync(SNAPSHOT_KEY);
    this.prefs.flushSync();
  }
}
