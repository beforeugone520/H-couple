import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AppSnapshot, createEmptySnapshot, snapshotFromJson } from '../shared/models/MemorySerde';
import { AnniversaryModel, MomentModel } from '../shared/models/MemoryModels';
import { daysUntilNextAnniversary, monthDayOf, todayYmd, togetherDayCount } from '../shared/util/MemoryUtil';

/**
 * 桌面卡片数据提供方。卡片与主端 UIAbility 共享同一应用沙箱，
 * 因此这里读取主端写入的同一份 Preferences 快照（name: memorybox_state），
 * 把最近一条瞬间、在一起天数、下一个纪念日绑定给卡片显示。
 */

const DOMAIN: number = 0x0000;
const TAG: string = 'MemoryCardForm';

interface CardData {
  title: string;
  daysLine: string;
  latestText: string;
  nextLine: string;
}

export default class MemoryCardFormProvider extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    return formBindingData.createFormBindingData(this.buildCardData());
  }

  onUpdateForm(formId: string): void {
    const data: formBindingData.FormBindingData = formBindingData.createFormBindingData(this.buildCardData());
    formProvider.updateForm(formId, data).catch((err: BusinessError) => {
      hilog.error(DOMAIN, TAG, 'updateForm failed: %{public}s', JSON.stringify(err));
    });
  }

  private buildCardData(): CardData {
    const snapshot: AppSnapshot = this.readSnapshot();
    const data: CardData = {
      title: '双人时光盒',
      daysLine: '今天也留下一点共同回忆',
      latestText: '还没有共同瞬间',
      nextLine: ''
    };

    if (snapshot.space.startDate.length > 0) {
      const days: number = togetherDayCount(snapshot.space.startDate, todayYmd());
      if (days > 0) {
        data.daysLine = `在一起第 ${days} 天`;
      }
    }

    const visible: MomentModel[] = snapshot.moments
      .filter((moment: MomentModel) => moment.deletedForUserIds.length === 0)
      .sort((a: MomentModel, b: MomentModel) => (a.occurredAt < b.occurredAt ? 1 : -1));
    if (visible.length > 0) {
      const latest: MomentModel = visible[0];
      data.latestText = latest.text.length > 0 ? latest.text : '记录了一组照片';
    }

    let bestDays: number = -1;
    snapshot.anniversaries.forEach((anniversary: AnniversaryModel) => {
      const days: number = daysUntilNextAnniversary(monthDayOf(anniversary.date), todayYmd());
      if (days >= 0 && (bestDays < 0 || days < bestDays)) {
        bestDays = days;
        data.nextLine = days === 0
          ? `今天是「${anniversary.title}」`
          : `距「${anniversary.title}」还有 ${days} 天`;
      }
    });

    return data;
  }

  private readSnapshot(): AppSnapshot {
    try {
      const prefs: preferences.Preferences =
        preferences.getPreferencesSync(this.context, { name: 'memorybox_state' });
      const raw: string = prefs.getSync('snapshot', '') as string;
      if (raw.length === 0) {
        return createEmptySnapshot();
      }
      return snapshotFromJson(raw);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'readSnapshot failed: %{public}s', JSON.stringify(err));
      return createEmptySnapshot();
    }
  }
}
