import { common } from '@kit.AbilityKit';
import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { AlbumPage } from '../features/album/AlbumPage';
import { TodayPage } from '../features/today/TodayPage';
import { TimelinePage } from '../features/timeline/TimelinePage';
import { UsPage } from '../features/us/UsPage';
import { SetupPage } from '../features/setup/SetupPage';
import { AppState } from '../shared/state/AppState';
import { MemberModel } from '../shared/models/MemoryModels';
import { MemoryTheme } from '../shared/theme/MemoryTheme';

@Entry
@Component
struct Index {
  @State appState: AppState = new AppState();
  @State activeTab: number = 0;
  private netConn: connection.NetConnection | null = null;

  aboutToAppear(): void {
    this.appState.init(getContext(this) as common.Context);
    this.startSyncWatcher();
  }

  aboutToDisappear(): void {
    if (this.netConn !== null) {
      this.netConn.unregister((err: BusinessError) => {});
      this.netConn = null;
    }
  }

  /** 云同步开启时：启动补偿一次，并监听联网恢复后自动补传待上传瞬间。 */
  private startSyncWatcher(): void {
    if (!this.appState.cloud.enabled) {
      return;
    }
    this.appState.syncPending();
    try {
      this.netConn = connection.createNetConnection();
      this.netConn.register((err: BusinessError) => {});
      this.netConn.on('netAvailable', (netHandle: connection.NetHandle) => {
        this.appState.syncPending();
      });
    } catch (err) {
      this.netConn = null;
    }
  }

  @Builder
  identitySwitch() {
    Row({ space: MemoryTheme.space.xs }) {
      Text('记录身份')
        .fontSize(MemoryTheme.font.caption)
        .fontColor(MemoryTheme.colors.muted);

      ForEach(this.appState.space.members, (member: MemberModel) => {
        Text(member.displayName)
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(member.id === this.appState.activeMemberId
            ? MemoryTheme.colors.surfaceStrong
            : MemoryTheme.colors.primaryDark)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor(member.id === this.appState.activeMemberId
            ? MemoryTheme.colors.primary
            : MemoryTheme.colors.roseSoft)
          .borderRadius(MemoryTheme.radius.pill)
          .onClick(() => {
            this.appState.setActiveMember(member.id);
          });
      }, (member: MemberModel) => member.id);
    }
  }

  @Builder
  topBar() {
    Column({ space: MemoryTheme.space.sm }) {
      Row() {
        Column({ space: 2 }) {
          Text('双人时光盒')
            .fontSize(MemoryTheme.font.title)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink);

          Text(this.appState.togetherDays() > 0
            ? `在一起第 ${this.appState.togetherDays()} 天`
            : '把今天收进时光盒')
            .fontSize(MemoryTheme.font.caption)
            .fontColor(MemoryTheme.colors.muted);
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);

        Text(this.appState.space.inviteCode.length > 0 ? `邀请码 ${this.appState.space.inviteCode}` : '私密空间')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.sage)
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .backgroundColor(MemoryTheme.colors.sageSoft)
          .borderRadius(MemoryTheme.radius.pill);
      }
      .width('100%');

      this.identitySwitch();
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({
      left: MemoryTheme.space.lg,
      right: MemoryTheme.space.lg,
      top: MemoryTheme.space.md,
      bottom: MemoryTheme.space.sm
    });
  }

  build() {
    Column() {
      if (!this.appState.ready) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(MemoryTheme.colors.primary);
          Text('正在打开时光盒…')
            .fontSize(MemoryTheme.font.body)
            .fontColor(MemoryTheme.colors.muted)
            .margin({ top: MemoryTheme.space.md });
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(MemoryTheme.colors.background);
      } else if (!this.appState.isSetup()) {
        SetupPage({ appState: this.appState });
      } else {
        this.topBar();

        Tabs({ barPosition: BarPosition.End, index: this.activeTab }) {
          TabContent() {
            TodayPage({ appState: this.appState });
          }.tabBar('今天');

          TabContent() {
            TimelinePage({ appState: this.appState });
          }.tabBar('时间线');

          TabContent() {
            AlbumPage({ appState: this.appState });
          }.tabBar('相册');

          TabContent() {
            UsPage({ appState: this.appState });
          }.tabBar('我们');
        }
        .layoutWeight(1)
        .barMode(BarMode.Fixed)
        .onChange((index: number) => {
          this.activeTab = index;
        });
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MemoryTheme.colors.background);
  }
}
