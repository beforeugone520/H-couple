import { MomentModel } from '../../shared/models/MemoryModels';
import { MemoryTheme } from '../../shared/theme/MemoryTheme';

@Component
export struct TimelinePage {
  moments: MomentModel[] = [];

  private getRespondedCount(): number {
    let count = 0;
    for (let index = 0; index < this.moments.length; index++) {
      if (this.moments[index].response.length > 0) {
        count += 1;
      }
    }
    return count;
  }

  private getFavoriteCount(): number {
    let count = 0;
    for (let index = 0; index < this.moments.length; index++) {
      if (this.moments[index].isFavorite) {
        count += 1;
      }
    }
    return count;
  }

  private getLatestDateLabel(): string {
    if (this.moments.length === 0) {
      return '暂无最新记录';
    }

    return `最新 ${this.moments[0].occurredAt.substring(0, 10)}`;
  }

  private getMonthLabel(moment: MomentModel): string {
    const year = moment.occurredAt.substring(0, 4);
    const monthText = moment.occurredAt.substring(5, 7);
    const month = monthText.startsWith('0') ? monthText.substring(1, 2) : monthText;
    return `${year}年${month}月`;
  }

  private shouldShowMonthDivider(moment: MomentModel): boolean {
    let currentIndex = -1;
    for (let index = 0; index < this.moments.length; index++) {
      if (this.moments[index].id === moment.id) {
        currentIndex = index;
        break;
      }
    }

    if (currentIndex === 0) {
      return true;
    }

    if (currentIndex < 0) {
      return false;
    }

    return this.getMonthLabel(this.moments[currentIndex - 1]) !== this.getMonthLabel(moment);
  }

  private getResponseLabel(response: string): string {
    if (response === 'like') {
      return '喜欢';
    }

    if (response === 'hug') {
      return '抱抱';
    }

    if (response === 'miss_you') {
      return '想你';
    }

    return '已回应';
  }

  build() {
    if (this.moments.length === 0) {
      Column({ space: MemoryTheme.space.sm }) {
        Text('时间线还没有内容')
          .fontSize(MemoryTheme.font.title)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink);

        Text('保存后的共同瞬间会按发生日期倒序显示在这里。')
          .fontSize(MemoryTheme.font.body)
          .fontColor(MemoryTheme.colors.muted);

        Text('下一步')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink);

        Flex({ wrap: FlexWrap.Wrap }) {
          Text('添加照片或一句话')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .margin({ right: MemoryTheme.space.sm, bottom: MemoryTheme.space.sm });

          Text('保存后自动出现在时间线')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .margin({ right: MemoryTheme.space.sm, bottom: MemoryTheme.space.sm });
        }
        .width('100%');

        Text('如果时间线加载失败，重新进入时间线即可重试。')
          .fontSize(MemoryTheme.font.meta)
          .fontColor(MemoryTheme.status.errorInk)
          .padding({ left: 10, right: 10, top: 8, bottom: 8 })
          .backgroundColor(MemoryTheme.status.errorBg)
          .border({ width: 1, color: MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.card)
          .width('100%');

        Text('加载失败')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.status.errorInk)
          .padding({ left: 10, right: 10, top: 7, bottom: 7 })
          .backgroundColor(MemoryTheme.status.errorBg)
          .borderRadius(MemoryTheme.radius.pill);

        Text('失败状态不会显示为 0 条。')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.status.errorInk)
          .padding({ left: 10, right: 10, top: 7, bottom: 7 })
          .backgroundColor(MemoryTheme.status.errorBg)
          .borderRadius(MemoryTheme.radius.pill);

        Text('去「今天」记录第一个瞬间')
          .fontSize(MemoryTheme.font.meta)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.emptyState.actionInk)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .backgroundColor(MemoryTheme.emptyState.actionBg)
          .borderRadius(MemoryTheme.radius.card);
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(MemoryTheme.space.lg)
      .backgroundColor(MemoryTheme.colors.surface)
      .border({ width: 1, color: MemoryTheme.colors.line })
      .borderRadius(MemoryTheme.radius.card);
    } else {
      Column({ space: MemoryTheme.space.md }) {
        Flex({ wrap: FlexWrap.Wrap }) {
          Text(`${this.moments.length} 条瞬间`)
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);

          Text(`${this.getRespondedCount()} 条已回应`)
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);

          Text(`${this.getFavoriteCount()} 条珍藏`)
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);

          Text(this.getLatestDateLabel())
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);
        }
        .width('100%');

        List({ space: MemoryTheme.space.md }) {
          ForEach(this.moments, (moment: MomentModel) => {
            ListItem() {
              Column({ space: MemoryTheme.space.sm }) {
                if (this.shouldShowMonthDivider(moment)) {
                  Row({ space: MemoryTheme.space.sm }) {
                    Text(this.getMonthLabel(moment))
                      .fontSize(MemoryTheme.font.caption)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(MemoryTheme.colors.muted);

                    Text('')
                      .height(1)
                      .backgroundColor(MemoryTheme.colors.line)
                      .layoutWeight(1);
                  }
                  .width('100%')
                  .padding({ left: 28 });
                }

                Row({ space: MemoryTheme.space.sm }) {
                  Text('')
                    .width(10)
                    .height(10)
                    .backgroundColor(MemoryTheme.colors.primary)
                    .borderRadius(MemoryTheme.radius.pill)
                    .margin({ top: 6 });

                  Column({ space: MemoryTheme.space.sm }) {
                    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
                      Column({ space: 4 }) {
                        Text(moment.occurredAt.substring(0, 10))
                          .fontSize(MemoryTheme.font.meta)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(MemoryTheme.colors.ink);

                        Text(moment.locationName.length > 0 ? moment.locationName : '未记录地点')
                          .fontSize(MemoryTheme.font.meta)
                          .fontColor(MemoryTheme.colors.muted);
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1);

                      Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.End }) {
                        if (moment.isFavorite) {
                          Text('珍藏')
                            .fontSize(MemoryTheme.font.meta)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(MemoryTheme.status.pendingInk)
                            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                            .backgroundColor(MemoryTheme.status.pendingBg)
                            .borderRadius(MemoryTheme.radius.pill)
                            .margin({ left: MemoryTheme.space.xs, bottom: MemoryTheme.space.xs });
                        }

                        Text(moment.mood === 'miss' ? '想念' : moment.mood === 'happy' ? '开心' : '平静')
                          .fontSize(MemoryTheme.font.meta)
                          .fontWeight(FontWeight.Bold)
                          .fontColor(MemoryTheme.colors.primaryDark)
                          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                          .backgroundColor(MemoryTheme.colors.roseSoft)
                          .borderRadius(MemoryTheme.radius.pill)
                          .margin({ left: MemoryTheme.space.xs, bottom: MemoryTheme.space.xs });
                      }
                      .layoutWeight(1);
                    }
                    .width('100%');

                    Text(moment.text)
                      .fontSize(17)
                      .fontColor(MemoryTheme.colors.ink);

                    if (moment.mediaUrls.length > 0) {
                      Text(`${moment.mediaUrls.length} 张照片`)
                        .fontSize(MemoryTheme.font.caption)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(MemoryTheme.colors.primaryDark)
                        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
                        .backgroundColor(MemoryTheme.colors.roseSoft)
                        .borderRadius(MemoryTheme.radius.pill);
                    }

                    if (moment.partnerText.length > 0) {
                      Text(moment.partnerText)
                        .fontSize(MemoryTheme.font.body)
                        .fontColor(MemoryTheme.colors.sage)
                        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
                        .backgroundColor(MemoryTheme.colors.sageSoft)
                        .borderRadius(MemoryTheme.radius.card);
                    }

                    Text(moment.response.length > 0 ? '已回应' : '等待回应')
                      .fontSize(MemoryTheme.font.meta)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(moment.response.length > 0 ? MemoryTheme.status.successInk : MemoryTheme.status.pendingInk)
                      .padding({ left: 10, right: 10, top: 7, bottom: 7 })
                      .backgroundColor(moment.response.length > 0 ? MemoryTheme.status.successBg : MemoryTheme.status.pendingBg)
                      .borderRadius(MemoryTheme.radius.card);

                    if (moment.response.length > 0) {
                      Text(`你的回应：${this.getResponseLabel(moment.response)}`)
                        .fontSize(MemoryTheme.font.meta)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(MemoryTheme.status.successInk)
                        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
                        .backgroundColor(MemoryTheme.status.successBg)
                        .border({ width: 1, color: MemoryTheme.colors.line })
                        .borderRadius(MemoryTheme.radius.card);
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1);
                }
                .width('100%')
                .padding(MemoryTheme.space.lg)
                .backgroundColor(MemoryTheme.colors.surface)
                .border({ width: 1, color: MemoryTheme.colors.line })
                .borderRadius(MemoryTheme.radius.card);
              }
              .width('100%');
          }
          }, (moment: MomentModel) => moment.id);
        }
        .width('100%');
      }
      .width('100%');
    }
  }
}
