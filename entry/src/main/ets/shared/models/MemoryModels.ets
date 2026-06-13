export type Mood = 'happy' | 'miss' | 'calm' | 'sad' | 'surprise';
export type MomentResponse = '' | 'like' | 'hug' | 'miss_you';

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
}

export class AnniversaryModel {
  id: string = '';
  coupleSpaceId: string = '';
  title: string = '';
  date: string = '';
  repeatType: 'none' | 'yearly' = 'yearly';
  reminderEnabled: boolean = true;
  coverMediaUrl: string = '';
}
