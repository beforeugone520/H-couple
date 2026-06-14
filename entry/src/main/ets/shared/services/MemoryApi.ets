import { http } from '@kit.NetworkKit';
import { MomentModel } from '../models/MemoryModels';
import { momentFromRecord } from '../models/MemorySerde';
import { readRecord, readString } from '../util/MemoryUtil';

/**
 * 可选的 Supabase 云同步层（REST / Auth）。
 * 纯本地模式下完全不需要它；启用云同步后用于跨设备让两个人看到同一条时间线。
 * URL / anon key / access token 只能在运行时注入，不在源码中硬编码真实值（见 AGENTS.md）。
 */

export class MemoryApiConfig {
  supabaseUrl: string = '';
  anonKey: string = '';
  accessToken: string = '';
}

export class CloudSession {
  accessToken: string = '';
  userId: string = '';
}

export class MemoryApi {
  private config: MemoryApiConfig;

  constructor(config: MemoryApiConfig) {
    this.config = config;
  }

  /** 邮箱 + 密码登录，返回 access token 和用户 id。 */
  async signInWithPassword(email: string, password: string): Promise<CloudSession> {
    const url: string = `${this.config.supabaseUrl}/auth/v1/token?grant_type=password`;
    const body: Record<string, Object> = {};
    body['email'] = email.trim();
    body['password'] = password;
    const response: http.HttpResponse = await this.send('POST', url, JSON.stringify(body), false);
    if (typeof response.result !== 'string') {
      throw new Error('登录失败：响应异常');
    }
    const root: Record<string, Object> = JSON.parse(response.result) as Record<string, Object>;
    if (response.responseCode < 200 || response.responseCode >= 300) {
      const message: string = readString(root, 'error_description', readString(root, 'msg', '登录失败'));
      throw new Error(message);
    }
    const session: CloudSession = new CloudSession();
    session.accessToken = readString(root, 'access_token');
    session.userId = readString(readRecord(root, 'user'), 'id');
    if (session.accessToken.length === 0) {
      throw new Error('登录失败：未返回访问令牌');
    }
    return session;
  }

  /** 拉取某双人空间的全部瞬间（按发生日期倒序）。 */
  async listMoments(coupleSpaceId: string): Promise<MomentModel[]> {
    const url: string =
      `${this.config.supabaseUrl}/rest/v1/moments?couple_space_id=eq.${coupleSpaceId}&select=*&order=occurred_at.desc`;
    const response: http.HttpResponse = await this.send('GET', url, '', true);
    if (response.responseCode < 200 || response.responseCode >= 300) {
      throw new Error(`拉取失败：HTTP ${response.responseCode}`);
    }
    if (typeof response.result !== 'string') {
      throw new Error('拉取失败：响应异常');
    }
    const parsed: Object = JSON.parse(response.result);
    if (!Array.isArray(parsed)) {
      throw new Error('拉取失败：响应格式不是数组');
    }
    const rows: Array<Record<string, Object>> = parsed as Array<Record<string, Object>>;
    return rows.map((row: Record<string, Object>) => momentFromRecord(row));
  }

  /** 推送一条瞬间到云端（按主键 id upsert，幂等）。 */
  async pushMoment(moment: MomentModel): Promise<void> {
    const url: string = `${this.config.supabaseUrl}/rest/v1/moments?on_conflict=id`;
    const response: http.HttpResponse = await this.send('POST', url, JSON.stringify(this.toRow(moment)), true);
    if (response.responseCode < 200 || response.responseCode >= 300) {
      throw new Error(`推送失败：HTTP ${response.responseCode}`);
    }
  }

  private toRow(moment: MomentModel): Record<string, Object> {
    const row: Record<string, Object> = {};
    row['id'] = moment.id;
    row['couple_space_id'] = moment.coupleSpaceId;
    row['creator_id'] = moment.creatorId;
    row['media_urls'] = moment.mediaUrls;
    row['text'] = moment.text;
    row['partner_text'] = moment.partnerText;
    row['mood'] = moment.mood;
    row['response'] = moment.response;
    row['location_name'] = moment.locationName;
    row['occurred_at'] = moment.occurredAt;
    row['is_favorite'] = moment.isFavorite;
    row['deleted_for_user_ids'] = moment.deletedForUserIds;
    return row;
  }

  private async send(method: string, url: string, body: string, useAuth: boolean): Promise<http.HttpResponse> {
    const request: http.HttpRequest = http.createHttp();
    try {
      const header: Record<string, string> = {};
      header['Content-Type'] = 'application/json';
      header['apikey'] = this.config.anonKey;
      const bearer: string = useAuth && this.config.accessToken.length > 0
        ? this.config.accessToken
        : this.config.anonKey;
      header['Authorization'] = `Bearer ${bearer}`;
      header['Prefer'] = 'resolution=merge-duplicates,return=minimal';

      const options: http.HttpRequestOptions = {
        method: method === 'GET' ? http.RequestMethod.GET : http.RequestMethod.POST,
        header: header,
        extraData: body,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 15000
      };
      return await request.request(url, options);
    } finally {
      request.destroy();
    }
  }
}
