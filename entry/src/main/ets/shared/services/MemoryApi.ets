import { http } from '@kit.NetworkKit';
import { MomentModel, MomentResponse, Mood } from '../models/MemoryModels';

export class MemoryApiConfig {
  supabaseUrl: string = '';
  anonKey: string = '';
  accessToken: string = '';
}

export class MemoryApi {
  private config: MemoryApiConfig;

  constructor(config: MemoryApiConfig) {
    this.config = config;
  }

  async listMoments(coupleSpaceId: string): Promise<MomentModel[]> {
    const request = http.createHttp();
    const url = `${this.config.supabaseUrl}/rest/v1/moments?couple_space_id=eq.${coupleSpaceId}&select=*&order=occurred_at.desc`;
    const response = await request.request(url, {
      method: http.RequestMethod.GET,
      header: {
        apikey: this.config.anonKey,
        Authorization: `Bearer ${this.config.accessToken}`
      }
    });
    request.destroy();
    const raw = JSON.parse(response.result as string) as Array<Record<string, Object>>;
    return raw.map((row) => this.toMoment(row));
  }

  private toMoment(row: Record<string, Object>): MomentModel {
    const moment = new MomentModel();
    moment.id = row['id'] as string;
    moment.coupleSpaceId = row['couple_space_id'] as string;
    moment.creatorId = row['creator_id'] as string;
    moment.mediaUrls = row['media_urls'] as string[];
    moment.text = row['text'] as string;
    moment.partnerText = row['partner_text'] as string;
    moment.mood = row['mood'] as Mood;
    moment.response = row['response'] as MomentResponse;
    moment.locationName = row['location_name'] as string;
    moment.occurredAt = row['occurred_at'] as string;
    moment.createdAt = row['created_at'] as string;
    moment.updatedAt = row['updated_at'] as string;
    moment.isFavorite = row['is_favorite'] as boolean;
    return moment;
  }
}
