import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { Mood } from '../../shared/models/MemoryModels';
import { AppState } from '../../shared/state/AppState';
import { MemoryTheme } from '../../shared/theme/MemoryTheme';
import { deleteSandboxFile, pickImagesToSandbox } from '../../shared/services/MemoryPhoto';

const MAX_PHOTOS: number = 9;

@Component
export struct MomentComposer {
  @ObjectLink appState: AppState;
  @State text: string = '';
  @State mood: Mood = 'calm';
  @State locationName: string = '';
  @State mediaUrls: string[] = [];
  @State picking: boolean = false;

  private canSave(): boolean {
    return this.text.trim().length > 0 || this.mediaUrls.length > 0;
  }

  private async pickPhotos(): Promise<void> {
    const remaining: number = MAX_PHOTOS - this.mediaUrls.length;
    if (remaining <= 0) {
      promptAction.showToast({ message: `最多 ${MAX_PHOTOS} 张照片` });
      return;
    }
    this.picking = true;
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
      const picked: string[] = await pickImagesToSandbox(context, remaining);
      if (picked.length > 0) {
        this.mediaUrls = [...this.mediaUrls, ...picked];
      }
    } finally {
      this.picking = false;
    }
  }

  private removePhoto(path: string): void {
    deleteSandboxFile(path);
    this.mediaUrls = this.mediaUrls.filter((item: string) => item !== path);
  }

  private save(): void {
    if (!this.canSave()) {
      return;
    }
    this.appState.addMoment(this.text, this.mood, this.locationName, this.mediaUrls);
    this.text = '';
    this.mood = 'calm';
    this.locationName = '';
    this.mediaUrls = [];
    promptAction.showToast({ message: '已收进时光盒' });
  }

  @Builder
  moodButton(target: Mood, label: string) {
    Button(label)
      .height(MemoryTheme.size.touchTarget)
      .layoutWeight(1)
      .fontSize(MemoryTheme.font.meta)
      .fontColor(this.mood === target ? MemoryTheme.colors.surfaceStrong : MemoryTheme.colors.muted)
      .backgroundColor(this.mood === target ? MemoryTheme.colors.primary : MemoryTheme.colors.surfaceStrong)
      .border({ width: 1, color: this.mood === target ? MemoryTheme.colors.primary : MemoryTheme.colors.line })
      .borderRadius(MemoryTheme.radius.card)
      .onClick(() => {
        this.mood = target;
      });
  }

  build() {
    Column({ space: MemoryTheme.space.md }) {
      Column({ space: 2 }) {
        Text('新的回忆')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.primary);
        Text(`以「${this.appState.activeMember().displayName}」的身份记录一个瞬间`)
          .fontSize(MemoryTheme.font.subtitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink);
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%');

      // 照片
      Text('照片')
        .fontSize(MemoryTheme.font.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);

      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.mediaUrls, (path: string) => {
          Stack({ alignContent: Alignment.TopEnd }) {
            Image(path)
              .width(80)
              .height(80)
              .objectFit(ImageFit.Cover)
              .borderRadius(MemoryTheme.radius.card)
              .backgroundColor(MemoryTheme.skeleton.base);
            Text('×')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.colors.surfaceStrong)
              .width(22)
              .height(22)
              .textAlign(TextAlign.Center)
              .backgroundColor(MemoryTheme.colors.primaryDark)
              .borderRadius(MemoryTheme.radius.pill)
              .margin({ top: 4, right: 4 })
              .onClick(() => {
                this.removePhoto(path);
              });
          }
          .margin({ right: MemoryTheme.space.sm, bottom: MemoryTheme.space.sm });
        }, (path: string) => path);

        if (this.mediaUrls.length < MAX_PHOTOS) {
          Column() {
            Text(this.picking ? '选择中' : '+ 添加')
              .fontSize(MemoryTheme.font.meta)
              .fontWeight(FontWeight.Bold)
              .fontColor(MemoryTheme.colors.primaryDark);
          }
          .justifyContent(FlexAlign.Center)
          .width(80)
          .height(80)
          .backgroundColor(MemoryTheme.colors.surfaceStrong)
          .border({ width: 1, color: MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.card)
          .onClick(() => {
            this.pickPhotos();
          });
        }
      }
      .width('100%');

      // 一句话
      Text('一句话')
        .fontSize(MemoryTheme.font.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);

      TextArea({ placeholder: '写一句今天想留下的话', text: this.text })
        .height(104)
        .fontSize(MemoryTheme.font.body)
        .backgroundColor(MemoryTheme.colors.surfaceStrong)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card)
        .onChange((value: string) => {
          this.text = value;
        });

      // 地点
      Text('地点')
        .fontSize(MemoryTheme.font.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);

      TextInput({ placeholder: '地点，可不填', text: this.locationName })
        .height(MemoryTheme.size.touchTarget)
        .fontSize(MemoryTheme.font.body)
        .backgroundColor(MemoryTheme.colors.surfaceStrong)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card)
        .onChange((value: string) => {
          this.locationName = value;
        });

      // 心情
      Text('心情')
        .fontSize(MemoryTheme.font.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);

      Row({ space: MemoryTheme.space.sm }) {
        this.moodButton('happy', '开心');
        this.moodButton('calm', '平静');
        this.moodButton('miss', '想念');
      }
      .width('100%');

      Row({ space: MemoryTheme.space.sm }) {
        this.moodButton('sad', '委屈');
        this.moodButton('surprise', '惊喜');
        Blank().layoutWeight(1);
      }
      .width('100%');

      Text(this.canSave() ? '准备好了，保存后会出现在时间线。' : '写一句话或添加一张照片即可保存。')
        .fontSize(MemoryTheme.font.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.canSave() ? MemoryTheme.status.successInk : MemoryTheme.status.neutralInk)
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .backgroundColor(this.canSave() ? MemoryTheme.status.successBg : MemoryTheme.status.neutralBg)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card)
        .width('100%');

      Button('保存')
        .height(MemoryTheme.size.touchTarget)
        .width('100%')
        .fontSize(MemoryTheme.font.body)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.surfaceStrong)
        .backgroundColor(MemoryTheme.colors.primary)
        .borderRadius(MemoryTheme.radius.card)
        .enabled(this.canSave())
        .opacity(this.canSave() ? 1 : 0.5)
        .onClick(() => {
          this.save();
        });
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(MemoryTheme.space.lg)
    .backgroundColor(MemoryTheme.colors.surface)
    .border({ width: 1, color: MemoryTheme.colors.line })
    .borderRadius(MemoryTheme.radius.card);
  }
}
