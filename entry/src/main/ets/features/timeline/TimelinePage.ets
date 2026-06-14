import { MomentModel, MomentResponse } from '../../shared/models/MemoryModels';
import { AppState, TimelineFilter } from '../../shared/state/AppState';
import { MemoryTheme } from '../../shared/theme/MemoryTheme';
import { moodLabel, monthLabelOf, responseLabel, ymdOf } from '../../shared/util/MemoryUtil';

@Component
export struct TimelinePage {
  @ObjectLink appState: AppState;
  @State filter: TimelineFilter = 'all';
  @State editingPartnerId: string = '';
  @State partnerDraft: string = '';

  private showMonthDivider(list: MomentModel[], index: number): boolean {
    if (index === 0) {
      return true;
    }
    return monthLabelOf(list[index - 1].occurredAt) !== monthLabelOf(list[index].occurredAt);
  }

  private beginPartnerEdit(moment: MomentModel): void {
    this.editingPartnerId = moment.id;
    this.partnerDraft = moment.partnerText;
  }

  private savePartnerEdit(): void {
    if (this.editingPartnerId.length > 0) {
      this.appState.setPartnerText(this.editingPartnerId, this.partnerDraft);
    }
    this.editingPartnerId = '';
    this.partnerDraft = '';
  }

  private retrySync(moment: MomentModel): void {
    this.appState.markMomentSync(moment.id, 'pending', '');
    this.appState.syncPending();
  }

  @Builder
  filterChip(value: TimelineFilter, label: string) {
    Text(label)
      .fontSize(MemoryTheme.font.caption)
      .fontWeight(FontWeight.Bold)
      .fontColor(this.filter === value ? MemoryTheme.colors.surfaceStrong : MemoryTheme.colors.muted)
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .backgroundColor(this.filter === value ? MemoryTheme.colors.primary : MemoryTheme.colors.surfaceStrong)
      .border({ width: 1, color: this.filter === value ? MemoryTheme.colors.primary : MemoryTheme.colors.line })
      .borderRadius(MemoryTheme.radius.pill)
      .margin({ right: MemoryTheme.space.sm, bottom: MemoryTheme.space.sm })
      .onClick(() => {
        this.filter = value;
      });
  }

  @Builder
  responseButton(moment: MomentModel, value: MomentResponse, label: string) {
    Text(label)
      .fontSize(MemoryTheme.font.caption)
      .fontWeight(FontWeight.Bold)
      .fontColor(moment.response === value ? MemoryTheme.colors.surfaceStrong : MemoryTheme.colors.sage)
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .backgroundColor(moment.response === value ? MemoryTheme.colors.sage : MemoryTheme.colors.sageSoft)
      .borderRadius(MemoryTheme.radius.pill)
      .onClick(() => {
        this.appState.setResponse(moment.id, value);
      });
  }

  @Builder
  momentCard(moment: MomentModel) {
    Column({ space: MemoryTheme.space.sm }) {
      Row() {
        Column({ space: 2 }) {
          Text(ymdOf(moment.occurredAt))
            .fontSize(MemoryTheme.font.meta)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink);
          Text(`${this.appState.memberName(moment.creatorId)}记录`)
            .fontSize(MemoryTheme.font.caption)
            .fontColor(MemoryTheme.colors.muted);
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);

        Text(moment.isFavorite ? '已珍藏' : '珍藏')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(moment.isFavorite ? MemoryTheme.status.pendingInk : MemoryTheme.colors.muted)
          .padding({ left: 12, right: 12, top: 7, bottom: 7 })
          .backgroundColor(moment.isFavorite ? MemoryTheme.status.pendingBg : MemoryTheme.colors.surfaceStrong)
          .border({ width: 1, color: MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.pill)
          .onClick(() => {
            this.appState.toggleFavorite(moment.id);
          });
      }
      .width('100%');

      if (this.appState.photoCount(moment) > 0) {
        Row({ space: MemoryTheme.space.sm }) {
          ForEach(this.appState.displayPhotoPaths(moment).slice(0, 3), (path: string) => {
            Image(this.appState.photoPathFor(path))
              .width(96)
              .height(96)
              .objectFit(ImageFit.Cover)
              .borderRadius(MemoryTheme.radius.photo)
              .backgroundColor(MemoryTheme.skeleton.base);
          }, (path: string) => path);

          if (this.appState.photoCount(moment) > 3) {
            Text(`+${this.appState.photoCount(moment) - 3}`)
              .fontSize(MemoryTheme.font.body)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.colors.muted)
              .width(96)
              .height(96)
              .textAlign(TextAlign.Center)
              .backgroundColor(MemoryTheme.colors.surfaceStrong)
              .border({ width: 1, color: MemoryTheme.colors.line })
              .borderRadius(MemoryTheme.radius.card);
          }
        }
        .width('100%');
      }

      if (moment.text.length > 0) {
        Text(moment.text)
          .fontSize(17)
          .fontColor(MemoryTheme.colors.ink)
          .width('100%');
      }

      Row({ space: MemoryTheme.space.sm }) {
        Text(moodLabel(moment.mood))
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.primaryDark)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(MemoryTheme.colors.roseSoft)
          .borderRadius(MemoryTheme.radius.pill);

        if (moment.locationName.length > 0) {
          Text(moment.locationName)
            .fontSize(MemoryTheme.font.caption)
            .fontColor(MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);
        }
      }
      .width('100%');

      // 对方补的一句话
      if (moment.partnerText.length > 0) {
        Text(`${this.appState.otherMember().displayName}：${moment.partnerText}`)
          .fontSize(MemoryTheme.font.body)
          .fontColor(MemoryTheme.colors.sage)
          .padding({ left: 12, right: 12, top: 10, bottom: 10 })
          .backgroundColor(MemoryTheme.colors.sageSoft)
          .borderRadius(MemoryTheme.radius.card)
          .width('100%');
      }

      // 当前身份不是记录者时，可补一句话
      if (moment.creatorId !== this.appState.activeMemberId) {
        if (this.editingPartnerId === moment.id) {
          Column({ space: MemoryTheme.space.sm }) {
            TextInput({ placeholder: '补一句话', text: this.partnerDraft })
              .height(MemoryTheme.size.touchTarget)
              .fontSize(MemoryTheme.font.body)
              .backgroundColor(MemoryTheme.colors.surfaceStrong)
              .border({ width: 1, color: MemoryTheme.colors.line })
              .borderRadius(MemoryTheme.radius.card)
              .onChange((value: string) => {
                this.partnerDraft = value;
              });
            Row({ space: MemoryTheme.space.sm }) {
              Button('保存')
                .height(36)
                .layoutWeight(1)
                .fontSize(MemoryTheme.font.meta)
                .fontColor(MemoryTheme.colors.surfaceStrong)
                .backgroundColor(MemoryTheme.colors.primary)
                .borderRadius(MemoryTheme.radius.card)
                .onClick(() => {
                  this.savePartnerEdit();
                });
              Button('取消')
                .height(36)
                .layoutWeight(1)
                .fontSize(MemoryTheme.font.meta)
                .fontColor(MemoryTheme.colors.muted)
                .backgroundColor(MemoryTheme.colors.surfaceStrong)
                .border({ width: 1, color: MemoryTheme.colors.line })
                .borderRadius(MemoryTheme.radius.card)
                .onClick(() => {
                  this.editingPartnerId = '';
                  this.partnerDraft = '';
                });
            }
            .width('100%');
          }
          .width('100%');
        } else {
          Text(moment.partnerText.length > 0 ? '修改我的一句话' : '补一句话')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.primaryDark)
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill)
            .onClick(() => {
              this.beginPartnerEdit(moment);
            });
        }
      }

      // 同步状态（仅云同步待上传/失败时提示）
      if (moment.syncState === 'pending') {
        Text('待上传')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.status.pendingInk)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(MemoryTheme.status.pendingBg)
          .borderRadius(MemoryTheme.radius.pill);
      } else if (moment.syncState === 'failed') {
        Row({ space: MemoryTheme.space.sm }) {
          Text('上传失败')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.status.errorInk)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.status.errorBg)
            .borderRadius(MemoryTheme.radius.pill);
          Text('重试')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.surfaceStrong)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.primary)
            .borderRadius(MemoryTheme.radius.pill)
            .onClick(() => {
              this.retrySync(moment);
            });
        }
        .width('100%');
      }

      // 轻回应
      Row({ space: MemoryTheme.space.sm }) {
        this.responseButton(moment, 'like', '喜欢');
        this.responseButton(moment, 'hug', '抱抱');
        this.responseButton(moment, 'miss_you', '想你');
      }
      .width('100%');

      Row() {
        Text(moment.response.length > 0 ? `回应：${responseLabel(moment.response)}` : '等待回应')
          .fontSize(MemoryTheme.font.meta)
          .fontWeight(FontWeight.Bold)
          .fontColor(moment.response.length > 0 ? MemoryTheme.status.successInk : MemoryTheme.status.pendingInk)
          .layoutWeight(1);

        Text('对我隐藏')
          .fontSize(MemoryTheme.font.caption)
          .fontColor(MemoryTheme.colors.muted)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .onClick(() => {
            this.appState.hideForActive(moment.id);
          });
      }
      .width('100%');
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(MemoryTheme.space.lg)
    .backgroundColor(MemoryTheme.colors.surface)
    .border({ width: 1, color: MemoryTheme.colors.line })
    .borderRadius(MemoryTheme.radius.card);
  }

  @Builder
  emptyState() {
    Column({ space: MemoryTheme.space.sm }) {
      Text(this.filter === 'all' ? '时间线还没有内容' : '没有符合筛选的瞬间')
        .fontSize(MemoryTheme.font.title)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);
      Text(this.filter === 'all'
        ? '去「今天」记录第一张照片或一句话，保存后会按发生日期倒序显示在这里。'
        : '换一个筛选条件，或去「今天」记录更多瞬间。')
        .fontSize(MemoryTheme.font.body)
        .fontColor(MemoryTheme.colors.muted);
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(MemoryTheme.space.lg)
    .backgroundColor(MemoryTheme.colors.surface)
    .border({ width: 1, color: MemoryTheme.colors.line })
    .borderRadius(MemoryTheme.radius.card);
  }

  build() {
    Column({ space: MemoryTheme.space.md }) {
      Flex({ wrap: FlexWrap.Wrap }) {
        this.filterChip('all', '全部');
        this.filterChip('mine', '我记录的');
        this.filterChip('partner', '对方记录的');
        this.filterChip('favorite', '收藏的');
        this.filterChip('located', '有地点');
      }
      .width('100%');

      Row({ space: MemoryTheme.space.sm }) {
        Text(`${this.appState.visibleMoments().length} 条瞬间`)
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(MemoryTheme.colors.surfaceStrong)
          .border({ width: 1, color: MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.pill);
        Text(`${this.appState.respondedCount()} 条已回应`)
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(MemoryTheme.colors.surfaceStrong)
          .border({ width: 1, color: MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.pill);
        Text(`${this.appState.favoriteCount()} 条珍藏`)
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(MemoryTheme.colors.surfaceStrong)
          .border({ width: 1, color: MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.pill);
      }
      .width('100%');

      if (this.appState.filteredMoments(this.filter).length === 0) {
        this.emptyState();
      } else {
        List({ space: MemoryTheme.space.md }) {
          ForEach(this.appState.filteredMoments(this.filter), (moment: MomentModel, index: number) => {
            ListItem() {
              Column({ space: MemoryTheme.space.sm }) {
                if (this.showMonthDivider(this.appState.filteredMoments(this.filter), index)) {
                  Text(monthLabelOf(moment.occurredAt))
                    .fontSize(MemoryTheme.font.caption)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(MemoryTheme.colors.muted)
                    .margin({ top: MemoryTheme.space.xs });
                }
                this.momentCard(moment);
              }
              .width('100%');
            }
          }, (moment: MomentModel) => moment.id);
        }
        .layoutWeight(1)
        .width('100%');
      }
    }
    .width('100%')
    .height('100%')
    .padding(MemoryTheme.space.lg);
  }
}
