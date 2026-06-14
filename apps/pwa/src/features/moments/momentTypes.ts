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
  deletedForUserIds: string[];
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
  deleted_for_user_ids?: string[];
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

export type RepeatType = 'none' | 'yearly';

export type Anniversary = {
  id: string;
  coupleSpaceId: string;
  title: string;
  date: string;
  repeatType: RepeatType;
  reminderEnabled: boolean;
  coverMediaUrl: string;
};

export type AnniversaryRow = {
  id: string;
  couple_space_id: string;
  title: string;
  date: string;
  repeat_type: RepeatType;
  reminder_enabled: boolean;
  cover_media_url: string | null;
};
