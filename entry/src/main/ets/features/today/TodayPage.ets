import { MomentComposer } from '../moments/MomentComposer';
import { MomentModel } from '../../shared/models/MemoryModels';
import { MemoryTheme } from '../../shared/theme/MemoryTheme';

@Component
export struct TodayPage {
  moments: MomentModel[] = [];

  build() {
    Scroll() {
      Column({ space: MemoryTheme.space.md }) {
        Column({ space: MemoryTheme.space.md }) {
          Text('今天')
            .fontSize(MemoryTheme.font.title)
            .fontWeight(FontWeight.Bold);

          if (this.moments.length === 0) {
            Column({ space: MemoryTheme.space.sm }) {
              Text('还没有共同瞬间。')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(MemoryTheme.colors.ink);

              Text('先保存一张照片或一句话，这里会展示最近的生活状态。')
                .fontSize(MemoryTheme.font.body)
                .fontColor(MemoryTheme.colors.muted);

              Text('从下方记录区开始')
                .fontSize(MemoryTheme.font.meta)
                .fontWeight(FontWeight.Bold)
                .fontColor(MemoryTheme.emptyState.hintInk)
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor(MemoryTheme.emptyState.hintBg)
                .borderRadius(MemoryTheme.radius.card);
            }
            .alignItems(HorizontalAlign.Start)
            .width('100%')
            .padding(MemoryTheme.space.md)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .borderRadius(MemoryTheme.radius.card);
          } else {
            Text(this.moments[0].occurredAt.substring(0, 10))
              .fontSize(MemoryTheme.font.meta)
              .fontColor(MemoryTheme.colors.muted);

            Text(this.moments[0].text)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.colors.ink);

            Text(this.moments[0].locationName.length > 0 ? this.moments[0].locationName : '未记录地点')
              .fontSize(MemoryTheme.font.meta)
              .fontColor(MemoryTheme.colors.muted);
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(MemoryTheme.space.lg)
        .backgroundColor(MemoryTheme.colors.surface)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card);

        MomentComposer();
      }
      .width('100%');
    }
  }
}
