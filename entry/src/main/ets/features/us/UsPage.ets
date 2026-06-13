import { MemoryTheme } from '../../shared/theme/MemoryTheme';

@Component
export struct UsPage {
  coupleSpaceId: string = '';

  build() {
    Column({ space: MemoryTheme.space.md }) {
      Text('我们')
        .fontSize(MemoryTheme.font.title)
        .fontWeight(FontWeight.Bold);

      Column({ space: MemoryTheme.space.xs }) {
        Text(this.coupleSpaceId.length > 0 ? '已加入双人空间' : '还没有加入双人空间')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink);

        Text(this.coupleSpaceId.length > 0 ? `空间：${this.coupleSpaceId}` : '创建或输入邀请码后，两个人就能共同记录。')
          .fontSize(MemoryTheme.font.body)
          .fontColor(MemoryTheme.colors.muted);
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(MemoryTheme.space.md)
      .backgroundColor(MemoryTheme.colors.surfaceStrong)
      .borderRadius(MemoryTheme.radius.card);

      Row({ space: MemoryTheme.space.sm }) {
        Text(this.coupleSpaceId.length > 0 ? '已连接' : '待连接')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.coupleSpaceId.length > 0 ? MemoryTheme.colors.sage : MemoryTheme.status.pendingInk)
          .padding({ left: 10, right: 10, top: 7, bottom: 7 })
          .backgroundColor(this.coupleSpaceId.length > 0 ? MemoryTheme.colors.sageSoft : MemoryTheme.status.pendingBg)
          .borderRadius(MemoryTheme.radius.pill);

        Text('私密空间')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.sage)
          .padding({ left: 10, right: 10, top: 7, bottom: 7 })
          .backgroundColor(MemoryTheme.colors.sageSoft)
          .borderRadius(MemoryTheme.radius.pill);

        Text('时间线同步')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.sage)
          .padding({ left: 10, right: 10, top: 7, bottom: 7 })
          .backgroundColor(MemoryTheme.colors.sageSoft)
          .borderRadius(MemoryTheme.radius.pill);
      }
      .width('100%');

      Column({ space: MemoryTheme.space.sm }) {
        Text('空间准备')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink);

        Flex({ wrap: FlexWrap.Wrap }) {
          Text('1. 创建空间')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);

          Text('2. 复制邀请码')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);

          Text('3. 对方加入')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);
        }

        Row({ space: MemoryTheme.space.sm }) {
          Text('邀请码状态')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted)
            .layoutWeight(1);

          Text(this.coupleSpaceId.length > 0 ? '已连接到空间' : '待生成或输入')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.coupleSpaceId.length > 0 ? MemoryTheme.status.successInk : MemoryTheme.status.pendingInk)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(this.coupleSpaceId.length > 0 ? MemoryTheme.status.successBg : MemoryTheme.status.pendingBg)
            .borderRadius(MemoryTheme.radius.pill);
        }
        .alignItems(VerticalAlign.Top)
        .width('100%');

        Column({ space: MemoryTheme.space.xs }) {
          Text('邀请对方加入')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.primaryDark);

          Text('新建空间后，邀请码会保留在工作区顶部，复制后发给对方即可。')
            .fontSize(MemoryTheme.font.caption)
            .fontColor(MemoryTheme.colors.muted);

          Text('生成后可复制邀请码')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.primaryDark)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card);

          Text('复制失败可手动复制邀请码发送给对方。')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.status.errorInk)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.status.errorBg)
            .borderRadius(MemoryTheme.radius.card);
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor(MemoryTheme.colors.roseSoft)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card);
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(MemoryTheme.space.md)
      .backgroundColor(MemoryTheme.colors.surfaceStrong)
      .borderRadius(MemoryTheme.radius.card);

      Row({ space: MemoryTheme.space.sm }) {
        Text('同步状态')
          .fontSize(MemoryTheme.font.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink)
          .layoutWeight(1);

        Text('待连接')
          .fontSize(MemoryTheme.font.meta)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.sage)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(MemoryTheme.colors.sageSoft)
          .borderRadius(MemoryTheme.radius.pill);
      }
      .width('100%')
      .padding(MemoryTheme.space.md)
      .backgroundColor(MemoryTheme.colors.surfaceStrong)
      .borderRadius(MemoryTheme.radius.card);

      Button('生成邀请码')
        .height(MemoryTheme.size.touchTarget)
        .width('100%')
        .fontSize(MemoryTheme.font.body)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.surfaceStrong)
        .backgroundColor(MemoryTheme.colors.primary)
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
