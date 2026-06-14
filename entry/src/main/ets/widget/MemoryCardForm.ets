import { MemoryTheme } from '../shared/theme/MemoryTheme';

/**
 * 桌面卡片 UI。数据由 MemoryCardFormProvider 通过 formBindingData 注入，
 * 这里用 @LocalStorageProp 只读绑定，key 必须与 provider 的 createFormBindingData 字段一致。
 */
@Entry
@Component
struct MemoryCardForm {
  @LocalStorageProp('title') title: string = '双人时光盒';
  @LocalStorageProp('daysLine') daysLine: string = '今天也留下一点共同回忆';
  @LocalStorageProp('latestText') latestText: string = '还没有共同瞬间';
  @LocalStorageProp('nextLine') nextLine: string = '';

  build() {
    Column({ space: MemoryTheme.space.xs }) {
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);

      Text(this.daysLine)
        .fontSize(MemoryTheme.font.meta)
        .fontColor(MemoryTheme.colors.muted);

      Text(this.latestText)
        .fontSize(14)
        .fontColor(MemoryTheme.colors.primary)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .padding({ top: 6 });

      if (this.nextLine.length > 0) {
        Text(this.nextLine)
          .fontSize(MemoryTheme.font.caption)
          .fontColor(MemoryTheme.colors.sage)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .padding({ top: 4 });
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .height('100%')
    .padding(MemoryTheme.space.md)
    .backgroundColor(MemoryTheme.colors.surface);
  }
}
