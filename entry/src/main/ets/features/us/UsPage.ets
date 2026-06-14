import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { AnniversaryModel, MemberModel, RepeatType } from '../../shared/models/MemoryModels';
import { AppState } from '../../shared/state/AppState';
import { MemoryApi, MemoryApiConfig, CloudSession } from '../../shared/services/MemoryApi';
import { MemoryTheme } from '../../shared/theme/MemoryTheme';
import { coerceYmd, daysUntilNextAnniversary, monthDayOf, todayYmd, ymdOf } from '../../shared/util/MemoryUtil';

@Component
export struct UsPage {
  @ObjectLink appState: AppState;
  @State nameYou: string = '';
  @State namePartner: string = '';
  @State startDateDraft: string = '';
  @State annTitle: string = '';
  @State annDate: string = '';
  @State annRepeat: RepeatType = 'yearly';
  @State cloudUrl: string = '';
  @State cloudKey: string = '';
  @State cloudEmail: string = '';
  @State cloudPassword: string = '';
  @State cloudSpaceId: string = '';
  @State cloudBusy: boolean = false;
  @State cloudStatus: string = '';
  @State confirmReset: boolean = false;

  aboutToAppear(): void {
    const members: MemberModel[] = this.appState.space.members;
    this.nameYou = members.length > 0 ? members[0].displayName : '';
    this.namePartner = members.length > 1 ? members[1].displayName : '';
    this.startDateDraft = this.appState.space.startDate.length > 0 ? this.appState.space.startDate : todayYmd();
    this.annDate = todayYmd();
    this.cloudUrl = this.appState.cloud.supabaseUrl;
    this.cloudKey = this.appState.cloud.anonKey;
    this.cloudEmail = this.appState.cloud.email;
    this.cloudSpaceId = this.appState.cloud.coupleSpaceId;
  }

  private copyInvite(): void {
    const code: string = this.appState.space.inviteCode;
    const data: pasteboard.PasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, code);
    pasteboard.getSystemPasteboard().setData(data).then(() => {
      promptAction.showToast({ message: '邀请码已复制' });
    }).catch(() => {
      promptAction.showToast({ message: '复制失败，请手动复制' });
    });
  }

  private saveNames(): void {
    const members: MemberModel[] = this.appState.space.members;
    if (members.length > 0) {
      this.appState.renameMember(members[0].id, this.nameYou);
    }
    if (members.length > 1) {
      this.appState.renameMember(members[1].id, this.namePartner);
    }
    promptAction.showToast({ message: '已更新称呼' });
  }

  private addAnniversary(): void {
    this.appState.addAnniversary(this.annTitle, coerceYmd(this.annDate, todayYmd()), this.annRepeat);
    this.annTitle = '';
    this.annDate = todayYmd();
    this.annRepeat = 'yearly';
  }

  private async cloudSignIn(): Promise<void> {
    if (this.cloudUrl.trim().length === 0 || this.cloudKey.trim().length === 0) {
      this.cloudStatus = '请先填写 Supabase URL 和 anon key';
      return;
    }
    this.cloudBusy = true;
    this.cloudStatus = '正在登录…';
    try {
      this.appState.setCloudConfig(this.cloudUrl, this.cloudKey);
      const config: MemoryApiConfig = new MemoryApiConfig();
      config.supabaseUrl = this.cloudUrl.trim();
      config.anonKey = this.cloudKey.trim();
      const api: MemoryApi = new MemoryApi(config);
      const session: CloudSession = await api.signInWithPassword(this.cloudEmail, this.cloudPassword);
      this.appState.setCloudSession(session.accessToken, session.userId, this.cloudEmail, this.cloudSpaceId.trim());
      this.cloudStatus = '登录成功，可拉取或推送';
      promptAction.showToast({ message: '云同步已登录' });
    } catch (err) {
      const message: string = err instanceof Error ? (err as Error).message : '未知错误';
      this.cloudStatus = `登录失败：${message}`;
    } finally {
      this.cloudBusy = false;
    }
  }

  private async cloudPull(): Promise<void> {
    if (this.cloudSpaceId.trim().length === 0) {
      this.cloudStatus = '请填写云端 couple_space_id';
      return;
    }
    this.cloudBusy = true;
    this.cloudStatus = '正在拉取…';
    try {
      const api: MemoryApi = new MemoryApi(this.activeConfig());
      const remote = await api.listMoments(this.cloudSpaceId.trim());
      this.appState.mergePulledMoments(remote);
      this.appState.markSynced();
      this.cloudStatus = `已拉取 ${remote.length} 条`;
      promptAction.showToast({ message: '已从云端拉取' });
    } catch (err) {
      const message: string = err instanceof Error ? (err as Error).message : '未知错误';
      this.cloudStatus = `拉取失败：${message}`;
    } finally {
      this.cloudBusy = false;
    }
  }

  private async cloudPush(): Promise<void> {
    this.cloudBusy = true;
    this.cloudStatus = '正在推送…';
    try {
      const api: MemoryApi = new MemoryApi(this.activeConfig());
      const moments = this.appState.visibleMoments();
      for (let index = 0; index < moments.length; index++) {
        await api.pushMoment(moments[index]);
      }
      this.appState.markSynced();
      this.cloudStatus = `已推送 ${moments.length} 条`;
      promptAction.showToast({ message: '已推送到云端' });
    } catch (err) {
      const message: string = err instanceof Error ? (err as Error).message : '未知错误';
      this.cloudStatus = `推送失败：${message}`;
    } finally {
      this.cloudBusy = false;
    }
  }

  private activeConfig(): MemoryApiConfig {
    const config: MemoryApiConfig = new MemoryApiConfig();
    config.supabaseUrl = this.appState.cloud.supabaseUrl;
    config.anonKey = this.appState.cloud.anonKey;
    config.accessToken = this.appState.cloud.accessToken;
    return config;
  }

  @Builder
  sectionTitle(text: string) {
    Text(text)
      .fontSize(MemoryTheme.font.body)
      .fontWeight(FontWeight.Bold)
      .fontColor(MemoryTheme.colors.ink);
  }

  build() {
    Scroll() {
      Column({ space: MemoryTheme.space.md }) {
        Text('我们')
          .fontSize(MemoryTheme.font.title)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink);

        // 空间状态 + 邀请码
        Column({ space: MemoryTheme.space.sm }) {
          this.sectionTitle('双人空间');
          Row() {
            Text(`邀请码 ${this.appState.space.inviteCode}`)
              .fontSize(MemoryTheme.font.body)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.colors.primaryDark)
              .layoutWeight(1);
            Text('复制')
              .fontSize(MemoryTheme.font.caption)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.colors.surfaceStrong)
              .padding({ left: 14, right: 14, top: 7, bottom: 7 })
              .backgroundColor(MemoryTheme.colors.primary)
              .borderRadius(MemoryTheme.radius.pill)
              .onClick(() => {
                this.copyInvite();
              });
          }
          .width('100%');
          Text('把邀请码发给对方。两人想在不同设备同步时，配合下方「云同步」使用。')
            .fontSize(MemoryTheme.font.caption)
            .fontColor(MemoryTheme.colors.muted);
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(MemoryTheme.space.md)
        .backgroundColor(MemoryTheme.colors.surfaceStrong)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card);

        // 称呼
        Column({ space: MemoryTheme.space.sm }) {
          this.sectionTitle('我们的称呼');
          TextInput({ placeholder: '你的称呼', text: this.nameYou })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.body)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.nameYou = value;
            });
          TextInput({ placeholder: '对方的称呼', text: this.namePartner })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.body)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.namePartner = value;
            });
          Text('在一起的日子')
            .fontSize(MemoryTheme.font.meta)
            .fontColor(MemoryTheme.colors.muted);
          TextInput({ placeholder: 'YYYY-MM-DD', text: this.startDateDraft })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.body)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.startDateDraft = value;
            });
          Button('保存')
            .height(MemoryTheme.size.touchTarget)
            .width('100%')
            .fontSize(MemoryTheme.font.body)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.surfaceStrong)
            .backgroundColor(MemoryTheme.colors.primary)
            .borderRadius(MemoryTheme.radius.card)
            .onClick(() => {
              this.appState.setStartDate(coerceYmd(this.startDateDraft, todayYmd()));
              this.saveNames();
            });
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(MemoryTheme.space.md)
        .backgroundColor(MemoryTheme.colors.surfaceStrong)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card);

        // 纪念日
        Column({ space: MemoryTheme.space.sm }) {
          this.sectionTitle('纪念日');
          TextInput({ placeholder: '名称，例如第一次见面', text: this.annTitle })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.body)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.annTitle = value;
            });
          Row({ space: MemoryTheme.space.sm }) {
            TextInput({ placeholder: 'YYYY-MM-DD', text: this.annDate })
              .height(MemoryTheme.size.touchTarget)
              .layoutWeight(1)
              .fontSize(MemoryTheme.font.body)
              .backgroundColor(MemoryTheme.colors.surfaceStrong)
              .border({ width: 1, color: MemoryTheme.colors.line })
              .borderRadius(MemoryTheme.radius.card)
              .onChange((value: string) => {
                this.annDate = value;
              });
            Text(this.annRepeat === 'yearly' ? '每年' : '一次')
              .fontSize(MemoryTheme.font.caption)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.colors.primaryDark)
              .padding({ left: 14, right: 14, top: 10, bottom: 10 })
              .backgroundColor(MemoryTheme.colors.roseSoft)
              .borderRadius(MemoryTheme.radius.pill)
              .onClick(() => {
                this.annRepeat = this.annRepeat === 'yearly' ? 'none' : 'yearly';
              });
          }
          .width('100%');
          Button('添加纪念日')
            .height(MemoryTheme.size.touchTarget)
            .width('100%')
            .fontSize(MemoryTheme.font.body)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.surfaceStrong)
            .backgroundColor(MemoryTheme.colors.primary)
            .borderRadius(MemoryTheme.radius.card)
            .enabled(this.annTitle.trim().length > 0)
            .opacity(this.annTitle.trim().length > 0 ? 1 : 0.5)
            .onClick(() => {
              this.addAnniversary();
            });

          if (this.appState.anniversaries.length === 0) {
            Text('还没有纪念日。')
              .fontSize(MemoryTheme.font.meta)
              .fontColor(MemoryTheme.colors.muted);
          } else {
            ForEach(this.appState.anniversaries, (anniversary: AnniversaryModel) => {
              Row() {
                Column({ space: 2 }) {
                  Text(anniversary.title)
                    .fontSize(MemoryTheme.font.body)
                    .fontColor(MemoryTheme.colors.ink);
                  Text(`${ymdOf(anniversary.date)} · ${this.annCountdown(anniversary)}`)
                    .fontSize(MemoryTheme.font.caption)
                    .fontColor(MemoryTheme.colors.muted);
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1);
                Text('删除')
                  .fontSize(MemoryTheme.font.caption)
                  .fontColor(MemoryTheme.status.errorInk)
                  .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                  .onClick(() => {
                    this.appState.deleteAnniversary(anniversary.id);
                  });
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

        // 云同步（可选）
        Column({ space: MemoryTheme.space.sm }) {
          this.sectionTitle('云同步（可选）');
          Text('纯本地即可完整使用。需要跨设备时，填写 Supabase 配置并登录后拉取/推送。')
            .fontSize(MemoryTheme.font.caption)
            .fontColor(MemoryTheme.colors.muted);
          TextInput({ placeholder: 'Supabase URL', text: this.cloudUrl })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.meta)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.cloudUrl = value;
            });
          TextInput({ placeholder: 'anon key', text: this.cloudKey })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.meta)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.cloudKey = value;
            });
          TextInput({ placeholder: '登录邮箱', text: this.cloudEmail })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.meta)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.cloudEmail = value;
            });
          this.cloudPasswordInput();
          TextInput({ placeholder: '云端 couple_space_id', text: this.cloudSpaceId })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.meta)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.cloudSpaceId = value;
            });

          Row({ space: MemoryTheme.space.sm }) {
            Button(this.appState.cloud.enabled ? '重新登录' : '登录')
              .height(40)
              .layoutWeight(1)
              .fontSize(MemoryTheme.font.meta)
              .fontColor(MemoryTheme.colors.surfaceStrong)
              .backgroundColor(MemoryTheme.colors.primary)
              .borderRadius(MemoryTheme.radius.card)
              .enabled(!this.cloudBusy)
              .onClick(() => {
                this.cloudSignIn();
              });
            Button('拉取')
              .height(40)
              .layoutWeight(1)
              .fontSize(MemoryTheme.font.meta)
              .fontColor(MemoryTheme.colors.sage)
              .backgroundColor(MemoryTheme.colors.sageSoft)
              .borderRadius(MemoryTheme.radius.card)
              .enabled(!this.cloudBusy && this.appState.cloud.enabled)
              .onClick(() => {
                this.cloudPull();
              });
            Button('推送')
              .height(40)
              .layoutWeight(1)
              .fontSize(MemoryTheme.font.meta)
              .fontColor(MemoryTheme.colors.sage)
              .backgroundColor(MemoryTheme.colors.sageSoft)
              .borderRadius(MemoryTheme.radius.card)
              .enabled(!this.cloudBusy && this.appState.cloud.enabled)
              .onClick(() => {
                this.cloudPush();
              });
          }
          .width('100%');

          if (this.cloudStatus.length > 0) {
            Text(this.cloudStatus)
              .fontSize(MemoryTheme.font.caption)
              .fontColor(MemoryTheme.colors.muted);
          }
          if (this.appState.cloud.lastSyncAt.length > 0) {
            Text(`上次同步：${ymdOf(this.appState.cloud.lastSyncAt)}`)
              .fontSize(MemoryTheme.font.caption)
              .fontColor(MemoryTheme.colors.muted);
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(MemoryTheme.space.md)
        .backgroundColor(MemoryTheme.colors.surfaceStrong)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card);

        // 重置
        Button(this.confirmReset ? '确认重置？再次点击清空全部' : '重置时光盒')
          .height(MemoryTheme.size.touchTarget)
          .width('100%')
          .fontSize(MemoryTheme.font.meta)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.confirmReset ? MemoryTheme.colors.surfaceStrong : MemoryTheme.status.errorInk)
          .backgroundColor(this.confirmReset ? MemoryTheme.status.errorInk : MemoryTheme.status.errorBg)
          .borderRadius(MemoryTheme.radius.card)
          .onClick(() => {
            if (this.confirmReset) {
              this.appState.resetAll();
              this.confirmReset = false;
            } else {
              this.confirmReset = true;
            }
          });
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(MemoryTheme.space.lg);
    }
    .width('100%')
    .layoutWeight(1)
    .align(Alignment.Top);
  }

  @Builder
  cloudPasswordInput() {
    TextInput({ placeholder: '登录密码', text: this.cloudPassword })
      .type(InputType.Password)
      .height(MemoryTheme.size.touchTarget)
      .fontSize(MemoryTheme.font.meta)
      .backgroundColor(MemoryTheme.colors.surfaceStrong)
      .border({ width: 1, color: MemoryTheme.colors.line })
      .borderRadius(MemoryTheme.radius.card)
      .onChange((value: string) => {
        this.cloudPassword = value;
      });
  }

  private annCountdown(anniversary: AnniversaryModel): string {
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
