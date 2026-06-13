export type Mood = 'happy' | 'miss' | 'calm' | 'sad' | 'surprise';
export type MomentResponse = '' | 'like' | 'hug' | 'miss_you';

export type Moment = {
  id: string;
  coupleSpaceId: string;
  creatorId: string;
  mediaUrls: string[];
  text: string;
  partnerText: string;
  mood: Mood;
  response: MomentResponse;
  locationName: string;
  occurredAt: string;
  createdAt: string;
  updatedAt: string;
  isFavorite: boolean;
};

export type MomentRow = {
  id: string;
  couple_space_id: string;
  creator_id: string;
  media_urls: string[];
  text: string;
  partner_text: string;
  mood: Mood;
  response: MomentResponse;
  location_name: string;
  occurred_at: string;
  created_at: string;
  updated_at: string;
  is_favorite: boolean;
};

export type NewMomentInput = {
  coupleSpaceId: string;
  creatorId: string;
  mediaUrls: string[];
  text: string;
  mood: Mood;
  locationName: string;
  occurredAt: string;
};
