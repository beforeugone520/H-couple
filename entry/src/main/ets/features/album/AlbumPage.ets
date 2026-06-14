import { AnniversaryModel, MomentModel } from '../../shared/models/MemoryModels';
import { AppState } from '../../shared/state/AppState';
import { MemoryTheme } from '../../shared/theme/MemoryTheme';
import { daysUntilNextAnniversary, monthDayOf, monthLabelOf, todayYmd, ymdOf } from '../../shared/util/MemoryUtil';

class AggItem {
  label: string = '';
  count: number = 0;
}

@Component
export struct AlbumPage {
  @ObjectLink appState: AppState;

  private monthAgg(): AggItem[] {
    const map: Map<string, number> = new Map<string, number>();
    this.appState.visibleMoments().forEach((moment: MomentModel) => {
      const label: string = monthLabelOf(moment.occurredAt);
      const current: number = map.get(label) ?? 0;
      map.set(label, current + 1);
    });
    const out: AggItem[] = [];
    map.forEach((count: number, label: string) => {
      const item: AggItem = new AggItem();
      item.label = label;
      item.count = count;
      out.push(item);
    });
    return out;
  }

  private locationAgg(): AggItem[] {
    const map: Map<string, number> = new Map<string, number>();
    this.appState.visibleMoments().forEach((moment: MomentModel) => {
      if (moment.locationName.length > 0) {
        const current: number = map.get(moment.locationName) ?? 0;
        map.set(moment.locationName, current + 1);
      }
    });
    const out: AggItem[] = [];
    map.forEach((count: number, label: string) => {
      const item: AggItem = new AggItem();
      item.label = label;
      item.count = count;
      out.push(item);
    });
    return out;
  }

  private photoMoments(): MomentModel[] {
    return this.appState.visibleMoments().filter((moment: MomentModel) => this.appState.photoCount(moment) > 0);
  }

  private totalPhotos(): number {
    let total: number = 0;
    this.appState.visibleMoments().forEach((moment: MomentModel) => {
      total += this.appState.photoCount(moment);
    });
    return total;
  }

  @Builder
  aggRow(title: string, items: AggItem[], emptyHint: string) {
    Column({ space: MemoryTheme.space.sm }) {
      Text(title)
        .fontSize(MemoryTheme.font.body)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);

      if (items.length === 0) {
        Text(emptyHint)
          .fontSize(MemoryTheme.font.meta)
          .fontColor(MemoryTheme.colors.muted);
      } else {
        ForEach(items, (item: AggItem) => {
          Row() {
            Text(item.label)
              .fontSize(MemoryTheme.font.body)
              .fontColor(MemoryTheme.colors.ink)
              .layoutWeight(1);
            Text(`${item.count} 个瞬间`)
              .fontSize(MemoryTheme.font.meta)
              .fontColor(MemoryTheme.colors.muted);
          }
          .width('100%')
          .padding({ top: 6, bottom: 6 });
        }, (item: AggItem) => item.label);
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(MemoryTheme.space.md)
    .backgroundColor(MemoryTheme.colors.surfaceStrong)
    .border({ width: 1, color: MemoryTheme.colors.line })
    .borderRadius(MemoryTheme.radius.card);
  }

  build() {
    Scroll() {
      Column({ space: MemoryTheme.space.md }) {
        Column({ space: MemoryTheme.space.xs }) {
          Text('相册')
            .fontSize(MemoryTheme.font.title)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink);
          Text(`已记录 ${this.appState.visibleMoments().length} 个瞬间 · ${this.totalPhotos()} 张照片`)
            .fontSize(MemoryTheme.font.body)
            .fontColor(MemoryTheme.colors.muted);
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%');

        if (this.photoMoments().length > 0) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.photoMoments(), (moment: MomentModel) => {
              Image(this.appState.photoPathFor(this.appState.displayPhotoPaths(moment)[0]))
                .width(104)
                .height(104)
                .objectFit(ImageFit.Cover)
                .borderRadius(MemoryTheme.radius.photo)
                .backgroundColor(MemoryTheme.skeleton.base)
                .margin({ right: MemoryTheme.space.sm, bottom: MemoryTheme.space.sm });
            }, (moment: MomentModel) => moment.id);
          }
          .width('100%');
        }

        this.aggRow('按月份', this.monthAgg(), '保存瞬间后会按月份自动聚合。');
        this.aggRow('按地点', this.locationAgg(), '记录时填写地点，这里会按地点聚合。');

        Column({ space: MemoryTheme.space.sm }) {
          Text('纪念日')
            .fontSize(MemoryTheme.font.body)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink);

          if (this.appState.anniversaries.length === 0) {
            Text('还没有纪念日，去「我们」添加第一次见面、生日或旅行纪念日。')
              .fontSize(MemoryTheme.font.meta)
              .fontColor(MemoryTheme.colors.muted);
          } else {
            ForEach(this.appState.anniversaries, (anniversary: AnniversaryModel) => {
              Row() {
                Column({ space: 2 }) {
                  Text(anniversary.title)
                    .fontSize(MemoryTheme.font.body)
                    .fontColor(MemoryTheme.colors.ink);
                  Text(ymdOf(anniversary.date))
                    .fontSize(MemoryTheme.font.caption)
                    .fontColor(MemoryTheme.colors.muted);
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);

                Text(this.countdownText(anniversary))
                  .fontSize(MemoryTheme.font.caption)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MemoryTheme.status.pendingInk)
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .backgroundColor(MemoryTheme.status.pendingBg)
                  .borderRadius(MemoryTheme.radius.pill);
              }
              .width('100%')
              .padding({ top: 6, bottom: 6 });
            }, (anniversary: AnniversaryModel) => anniversary.id);
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(MemoryTheme.space.md)
        .backgroundColor(MemoryTheme.colors.surfaceStrong)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card);
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(MemoryTheme.space.lg);
    }
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top);
  }

  private countdownText(anniversary: AnniversaryModel): string {
    const days: number = daysUntilNextAnniversary(monthDayOf(anniversary.date), todayYmd());
    if (days < 0) {
      return '日期待确认';
    }
    if (days === 0) {
      return '就是今天';
    }
    return `还有 ${days} 天`;
  }
}
