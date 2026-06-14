import { MomentComposer } from '../moments/MomentComposer';
import { MomentModel } from '../../shared/models/MemoryModels';
import { AppState, NextAnniversaryView } from '../../shared/state/AppState';
import { MemoryTheme } from '../../shared/theme/MemoryTheme';
import { moodLabel, todayYmd, yearOf, ymdOf } from '../../shared/util/MemoryUtil';

@Component
export struct TodayPage {
  @ObjectLink appState: AppState;

  build() {
    Scroll() {
      Column({ space: MemoryTheme.space.md }) {
        // 今日状态：把「在一起 N 天」做成情感中心
        Column({ space: MemoryTheme.space.sm }) {
          Text(`你好，${this.appState.activeMember().displayName} · ${todayYmd()}`)
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted);

          if (this.appState.togetherDays() > 0) {
            Row({ space: MemoryTheme.space.xs }) {
              Text('在一起')
                .fontSize(MemoryTheme.font.subtitle)
                .fontColor(MemoryTheme.colors.ink);
              Text(`${this.appState.togetherDays()}`)
                .fontSize(MemoryTheme.font.poster)
                .fontWeight(FontWeight.Bold)
                .fontColor(MemoryTheme.colors.primary);
              Text('天')
                .fontSize(MemoryTheme.font.subtitle)
                .fontColor(MemoryTheme.colors.ink);
            }
            .alignItems(VerticalAlign.Bottom);
          } else {
            Text('把今天收进时光盒')
              .fontSize(MemoryTheme.font.title)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.colors.ink);
          }

          this.nextAnniversaryChip();
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(MemoryTheme.space.xl)
        .linearGradient({
          angle: 135,
          colors: [[MemoryTheme.gradient.heroFrom, 0.0], [MemoryTheme.gradient.heroTo, 1.0]]
        })
        .borderRadius(MemoryTheme.radius.photo)
        .shadow({
          radius: MemoryTheme.elevation.heroRadius,
          color: MemoryTheme.elevation.heroColor,
          offsetX: 0,
          offsetY: MemoryTheme.elevation.heroOffsetY
        });

        // 最近一条
        Column({ space: MemoryTheme.space.sm }) {
          Text('最近的我们')
            .fontSize(MemoryTheme.font.body)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink);

          if (this.appState.latestVisibleMoment() === null) {
            this.emptyLatest();
          } else {
            this.latestCard(this.appState.latestVisibleMoment() as MomentModel);
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(MemoryTheme.space.lg)
        .backgroundColor(MemoryTheme.colors.surface)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card);

        // 某年今日
        if (this.appState.onThisDayMoments().length > 0) {
          Column({ space: MemoryTheme.space.sm }) {
            Text('某年今日')
              .fontSize(MemoryTheme.font.body)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.colors.ink);

            ForEach(this.appState.onThisDayMoments(), (moment: MomentModel) => {
              Row({ space: MemoryTheme.space.sm }) {
                Text(`${yearOf(todayYmd()) - yearOf(moment.occurredAt)} 年前`)
                  .fontSize(MemoryTheme.font.caption)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(MemoryTheme.colors.primaryDark)
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .backgroundColor(MemoryTheme.colors.roseSoft)
                  .borderRadius(MemoryTheme.radius.pill);
                Text(moment.text.length > 0 ? moment.text : '（仅照片）')
                  .fontSize(MemoryTheme.font.meta)
                  .fontColor(MemoryTheme.colors.ink)
                  .layoutWeight(1);
              }
              .width('100%')
              .alignItems(VerticalAlign.Center);
            }, (moment: MomentModel) => moment.id);
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(MemoryTheme.space.lg)
          .backgroundColor(MemoryTheme.colors.surface)
          .border({ width: 1, color: MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.card);
        }

        // 记录
        MomentComposer({ appState: this.appState });
      }
      .width('100%')
      .padding(MemoryTheme.space.lg);
    }
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top);
  }

  @Builder
  nextAnniversaryChip() {
    if (this.appState.nextAnniversary().has) {
      Text(this.nextAnniversaryText())
        .fontSize(MemoryTheme.font.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.status.pendingInk)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor(MemoryTheme.status.pendingBg)
        .borderRadius(MemoryTheme.radius.pill);
    }
  }

  private nextAnniversaryText(): string {
    const next: NextAnniversaryView = this.appState.nextAnniversary();
    if (next.daysLeft === 0) {
      return `今天是「${next.title}」`;
    }
    return `距离「${next.title}」还有 ${next.daysLeft} 天`;
  }

  @Builder
  latestCard(moment: MomentModel) {
    Column({ space: MemoryTheme.space.sm }) {
      Text(`${ymdOf(moment.occurredAt)} · ${this.appState.memberName(moment.creatorId)}记录`)
        .fontSize(MemoryTheme.font.meta)
        .fontColor(MemoryTheme.colors.muted);

      Text(moment.text.length > 0 ? moment.text : '（仅照片）')
        .fontSize(MemoryTheme.font.subtitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);

      Row({ space: MemoryTheme.space.sm }) {
        Text(moodLabel(moment.mood))
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.primaryDark)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(MemoryTheme.colors.roseSoft)
          .borderRadius(MemoryTheme.radius.pill);

        Text(moment.locationName.length > 0 ? moment.locationName : '未记录地点')
          .fontSize(MemoryTheme.font.caption)
          .fontColor(MemoryTheme.colors.muted)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(MemoryTheme.colors.surfaceStrong)
          .border({ width: 1, color: MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.pill);

        if (this.appState.photoCount(moment) > 0) {
          Text(`${this.appState.photoCount(moment)} 张照片`)
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.primaryDark)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.roseSoft)
            .borderRadius(MemoryTheme.radius.pill);
        }
      }

      if (this.appState.photoCount(moment) > 0) {
        Image(this.appState.photoPathFor(this.appState.displayPhotoPaths(moment)[0]))
          .width('100%')
          .height(200)
          .objectFit(ImageFit.Cover)
          .borderRadius(MemoryTheme.radius.photo)
          .backgroundColor(MemoryTheme.skeleton.base);
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%');
  }

  @Builder
  emptyLatest() {
    Column({ space: MemoryTheme.space.xs }) {
      Text('还没有共同瞬间')
        .fontSize(MemoryTheme.font.subtitle)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);
      Text('在下面记录第一张照片或一句话，这里会展示你们最近的生活状态。')
        .fontSize(MemoryTheme.font.body)
        .fontColor(MemoryTheme.colors.muted);
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(MemoryTheme.space.md)
    .backgroundColor(MemoryTheme.colors.surfaceStrong)
    .borderRadius(MemoryTheme.radius.card);
  }
}
