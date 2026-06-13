import { MomentModel } from '../models/MemoryModels';

@Observed
export class AppState {
  coupleSpaceId: string = '';
  moments: MomentModel[] = [];
  selectedTab: number = 0;
}
