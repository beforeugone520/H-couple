import { AlbumPage } from '../features/album/AlbumPage';
import { TodayPage } from '../features/today/TodayPage';
import { TimelinePage } from '../features/timeline/TimelinePage';
import { UsPage } from '../features/us/UsPage';
import { AppState } from '../shared/state/AppState';
import { MemoryTheme } from '../shared/theme/MemoryTheme';

@Entry
@Component
struct Index {
  @State appState: AppState = new AppState();

  build() {
    Column() {
      Column({ space: MemoryTheme.space.md }) {
        Text('只属于两个人')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.primary);

        Text('双人时光盒')
          .fontSize(MemoryTheme.font.display)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink);

        Text('把照片、一句话和轻回应收进同一个私密空间。')
          .fontSize(MemoryTheme.font.body)
          .fontColor(MemoryTheme.colors.muted);

        Row({ space: MemoryTheme.space.sm }) {
          Text('共同记录')
            .fontSize(MemoryTheme.font.meta)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.primaryDark)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .borderRadius(MemoryTheme.radius.pill);

          Text('轻量回应')
            .fontSize(MemoryTheme.font.meta)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.primaryDark)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .borderRadius(MemoryTheme.radius.pill);

          Text('私密同步')
            .fontSize(MemoryTheme.font.meta)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.primaryDark)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .borderRadius(MemoryTheme.radius.pill);
        }

        Row({ space: MemoryTheme.space.sm }) {
          Text('身份确认')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card);

          Text('今日新记录')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card);

          Text('等待回应')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card);

          Text('双端同步')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card);
        }

        Column({ space: MemoryTheme.space.sm }) {
          Text('登录下一步')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.status.successInk);

          Flex({ wrap: FlexWrap.Wrap }) {
            Text('1 检查邮箱')
              .fontSize(MemoryTheme.font.caption)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.status.successInk)
              .padding({ left: 10, right: 10, top: 7, bottom: 7 })
              .backgroundColor(MemoryTheme.status.successBg)
              .border({ width: 1, color: MemoryTheme.colors.line })
              .borderRadius(MemoryTheme.radius.card)
              .margin({ right: MemoryTheme.space.sm, bottom: MemoryTheme.space.sm });

            Text('2 点击登录链接')
              .fontSize(MemoryTheme.font.caption)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.status.successInk)
              .padding({ left: 10, right: 10, top: 7, bottom: 7 })
              .backgroundColor(MemoryTheme.status.successBg)
              .border({ width: 1, color: MemoryTheme.colors.line })
              .borderRadius(MemoryTheme.radius.card)
              .margin({ right: MemoryTheme.space.sm, bottom: MemoryTheme.space.sm });

            Text('3 回到时光盒')
              .fontSize(MemoryTheme.font.caption)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.status.successInk)
              .padding({ left: 10, right: 10, top: 7, bottom: 7 })
              .backgroundColor(MemoryTheme.status.successBg)
              .border({ width: 1, color: MemoryTheme.colors.line })
              .borderRadius(MemoryTheme.radius.card)
              .margin({ right: MemoryTheme.space.sm, bottom: MemoryTheme.space.sm });
          }
        }
        .alignItems(HorizontalAlign.Start)
        .padding({ left: 12, right: 12, top: 10 })
        .backgroundColor(MemoryTheme.colors.surfaceStrong)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card)
        .width('100%');

        Row({ space: MemoryTheme.space.sm }) {
          Text('主操作：今天记录')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.surfaceStrong)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.primary)
            .borderRadius(MemoryTheme.radius.card);

          Text('下一步：时间线回看')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.sage)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.sageSoft)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card);
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .margin({ top: 22, bottom: 22 });

      Tabs({ barPosition: BarPosition.End }) {
        TabContent() {
          TodayPage({ moments: this.appState.moments });
        }.tabBar('今天');

        TabContent() {
          TimelinePage({ moments: this.appState.moments });
        }.tabBar('时间线');

        TabContent() {
          AlbumPage({ moments: this.appState.moments });
        }.tabBar('相册');

        TabContent() {
          UsPage({ coupleSpaceId: this.appState.coupleSpaceId });
        }.tabBar('我们');
      }
      .layoutWeight(1);
    }
    .width('100%')
    .height('100%')
    .padding({ left: MemoryTheme.space.lg, right: MemoryTheme.space.lg })
    .backgroundColor(MemoryTheme.colors.background);
  }
}
