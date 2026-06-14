import { AppState } from '../../shared/state/AppState';
import { MemoryTheme } from '../../shared/theme/MemoryTheme';
import { coerceYmd, todayYmd } from '../../shared/util/MemoryUtil';

/**
 * 首次进入的建立流程：设置两个人的称呼和在一起的日子，创建本地双人空间并生成邀请码。
 * 纯本地即可完整使用；之后可在「我们」里开启可选的云同步实现跨设备。
 */
@Component
export struct SetupPage {
  @ObjectLink appState: AppState;
  @State yourName: string = '';
  @State partnerName: string = '';
  @State startDate: string = '';

  aboutToAppear(): void {
    this.startDate = todayYmd();
  }

  private canCreate(): boolean {
    return this.yourName.trim().length > 0;
  }

  build() {
    Scroll() {
      Column({ space: MemoryTheme.space.lg }) {
        Column({ space: MemoryTheme.space.sm }) {
          Text('只属于两个人')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.primary);

          Text('双人时光盒')
            .fontSize(MemoryTheme.font.display)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink);

          Text('先建立你们的私密空间，把照片、一句话和轻回应收进同一个时光盒。')
            .fontSize(MemoryTheme.font.body)
            .fontColor(MemoryTheme.colors.muted);
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%');

        Column({ space: MemoryTheme.space.md }) {
          Text('你的称呼')
            .fontSize(MemoryTheme.font.meta)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink);

          TextInput({ placeholder: '例如：阿星', text: this.yourName })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.body)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.yourName = value;
            });

          Text('对方的称呼')
            .fontSize(MemoryTheme.font.meta)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink);

          TextInput({ placeholder: '例如：小鹿（可稍后再改）', text: this.partnerName })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.body)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.partnerName = value;
            });

          Text('在一起的日子')
            .fontSize(MemoryTheme.font.meta)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink);

          TextInput({ placeholder: 'YYYY-MM-DD', text: this.startDate })
            .height(MemoryTheme.size.touchTarget)
            .fontSize(MemoryTheme.font.body)
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .onChange((value: string) => {
              this.startDate = value;
            });

          Text('用于「今天」页显示在一起第几天，可填纪念日。')
            .fontSize(MemoryTheme.font.caption)
            .fontColor(MemoryTheme.colors.muted);
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(MemoryTheme.space.lg)
        .backgroundColor(MemoryTheme.colors.surface)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card);

        Button('创建我们的时光盒')
          .height(MemoryTheme.size.touchTarget)
          .width('100%')
          .fontSize(MemoryTheme.font.body)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.surfaceStrong)
          .backgroundColor(MemoryTheme.colors.primary)
          .borderRadius(MemoryTheme.radius.card)
          .enabled(this.canCreate())
          .opacity(this.canCreate() ? 1 : 0.5)
          .onClick(() => {
            this.appState.setupSpace(
              this.yourName,
              this.partnerName,
              coerceYmd(this.startDate, todayYmd())
            );
          });

        Text('创建后会生成邀请码。两个人想在不同设备上同步时，可在「我们」页开启云同步。')
          .fontSize(MemoryTheme.font.caption)
          .fontColor(MemoryTheme.colors.muted)
          .width('100%');
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding(MemoryTheme.space.lg);
    }
    .width('100%')
    .height('100%')
    .backgroundColor(MemoryTheme.colors.background);
  }
}
