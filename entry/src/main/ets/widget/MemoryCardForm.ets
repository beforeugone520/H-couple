import { MemoryTheme } from '../shared/theme/MemoryTheme';

@Entry
@Component
struct MemoryCardForm {
  build() {
    Column({ space: MemoryTheme.space.xs }) {
      Text('双人时光盒')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);

      Text('今天也留下一点共同回忆')
        .fontSize(MemoryTheme.font.meta)
        .fontColor(MemoryTheme.colors.muted);

      Text('打开记录')
        .fontSize(MemoryTheme.font.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.primary)
        .padding({ top: 6 });
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding(MemoryTheme.space.md)
    .backgroundColor(MemoryTheme.colors.surface);
  }
}
