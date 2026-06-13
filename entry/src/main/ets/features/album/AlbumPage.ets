import { MomentModel } from '../../shared/models/MemoryModels';
import { MemoryTheme } from '../../shared/theme/MemoryTheme';

@Component
export struct AlbumPage {
  moments: MomentModel[] = [];

  build() {
    Column({ space: MemoryTheme.space.md }) {
      Text('相册')
        .fontSize(MemoryTheme.font.title)
        .fontWeight(FontWeight.Bold);

      Text(`已记录 ${this.moments.length} 个瞬间`)
        .fontSize(MemoryTheme.font.body)
        .fontColor(MemoryTheme.colors.muted);

      Column({ space: MemoryTheme.space.sm }) {
        Row() {
          Text('月份')
            .fontSize(MemoryTheme.font.body)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .layoutWeight(1);
          Text(`${this.moments.length} 张`)
            .fontSize(MemoryTheme.font.meta)
            .fontColor(MemoryTheme.colors.muted);
        }
        .width('100%');

        Row() {
          Text('地点')
            .fontSize(MemoryTheme.font.body)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .layoutWeight(1);
          Text('自动聚合')
            .fontSize(MemoryTheme.font.meta)
            .fontColor(MemoryTheme.colors.muted);
        }
        .width('100%');

        Row() {
          Text('纪念日')
            .fontSize(MemoryTheme.font.body)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .layoutWeight(1);
          Text('待补充')
            .fontSize(MemoryTheme.font.meta)
            .fontColor(MemoryTheme.colors.muted);
        }
        .width('100%');
      }
      .width('100%')
      .padding(MemoryTheme.space.md)
      .backgroundColor(MemoryTheme.colors.surfaceStrong)
      .borderRadius(MemoryTheme.radius.card);
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(MemoryTheme.space.lg)
    .backgroundColor(MemoryTheme.colors.surface)
    .border({ width: 1, color: MemoryTheme.colors.line })
    .borderRadius(MemoryTheme.radius.card);
  }
}
