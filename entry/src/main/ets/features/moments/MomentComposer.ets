import { Mood } from '../../shared/models/MemoryModels';
import { MemoryTheme } from '../../shared/theme/MemoryTheme';

@Component
export struct MomentComposer {
  @State text: string = '';
  @State mood: Mood = 'calm';
  @State locationName: string = '';

  private getMoodLabel(): string {
    if (this.mood === 'happy') {
      return '开心';
    }

    if (this.mood === 'miss') {
      return '想念';
    }

    if (this.mood === 'sad') {
      return '委屈';
    }

    if (this.mood === 'surprise') {
      return '惊喜';
    }

    return '平静';
  }

  private getCompletenessCount(): number {
    let count = 0;
    if (this.text.trim().length > 0) {
      count += 1;
    }

    if (this.locationName.trim().length > 0) {
      count += 1;
    }

    return count;
  }

  build() {
    Column({ space: MemoryTheme.space.md }) {
      Column({ space: MemoryTheme.space.xs }) {
        Text('新的回忆')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.primary);

        Text('记录一个瞬间')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.ink);
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%');

      Text('照片')
        .fontSize(MemoryTheme.font.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);

      Row({ space: MemoryTheme.space.md }) {
        Text('照片')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.colors.primaryDark)
          .width(72)
          .height(72)
          .textAlign(TextAlign.Center)
          .backgroundColor(MemoryTheme.skeleton.base)
          .border({ width: 1, color: MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.card);

        Column({ space: MemoryTheme.space.xs }) {
          Text('添加照片')
            .fontSize(MemoryTheme.font.meta)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink);

          Text('选择后会显示预览，也可以再次更换或移除')
            .fontSize(MemoryTheme.font.meta)
            .fontColor(MemoryTheme.colors.muted);
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1);
      }
      .width('100%')
      .padding(MemoryTheme.space.md)
      .backgroundColor(MemoryTheme.colors.surfaceStrong)
      .border({ width: 1, color: MemoryTheme.colors.line })
      .borderRadius(MemoryTheme.radius.card);

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

      Text('心情')
        .fontSize(MemoryTheme.font.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.ink);

      Row({ space: MemoryTheme.space.sm }) {
        Button('开心')
          .height(MemoryTheme.size.touchTarget)
          .layoutWeight(1)
          .fontSize(MemoryTheme.font.meta)
          .fontColor(this.mood === 'happy' ? MemoryTheme.colors.surfaceStrong : MemoryTheme.colors.muted)
          .backgroundColor(this.mood === 'happy' ? MemoryTheme.colors.primary : MemoryTheme.colors.surfaceStrong)
          .border({ width: 1, color: this.mood === 'happy' ? MemoryTheme.colors.primary : MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.card)
          .onClick(() => {
            this.mood = 'happy';
          });

        Button('平静')
          .height(MemoryTheme.size.touchTarget)
          .layoutWeight(1)
          .fontSize(MemoryTheme.font.meta)
          .fontColor(this.mood === 'calm' ? MemoryTheme.colors.surfaceStrong : MemoryTheme.colors.muted)
          .backgroundColor(this.mood === 'calm' ? MemoryTheme.colors.primary : MemoryTheme.colors.surfaceStrong)
          .border({ width: 1, color: this.mood === 'calm' ? MemoryTheme.colors.primary : MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.card)
          .onClick(() => {
            this.mood = 'calm';
          });

        Button('想念')
          .height(MemoryTheme.size.touchTarget)
          .layoutWeight(1)
          .fontSize(MemoryTheme.font.meta)
          .fontColor(this.mood === 'miss' ? MemoryTheme.colors.surfaceStrong : MemoryTheme.colors.muted)
          .backgroundColor(this.mood === 'miss' ? MemoryTheme.colors.primary : MemoryTheme.colors.surfaceStrong)
          .border({ width: 1, color: this.mood === 'miss' ? MemoryTheme.colors.primary : MemoryTheme.colors.line })
          .borderRadius(MemoryTheme.radius.card)
          .onClick(() => {
            this.mood = 'miss';
          });
      }
      .width('100%');

      Column({ space: MemoryTheme.space.sm }) {
        Row() {
          Text('草稿概况')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.ink)
            .layoutWeight(1);

          Text(`记录完整度 ${this.getCompletenessCount()}/3`)
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted);
        }
        .width('100%');

        Flex({ wrap: FlexWrap.Wrap }) {
          Text('照片待补')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .borderRadius(MemoryTheme.radius.pill);

          Text(this.text.trim().length > 0 ? '文字已写' : '文字待写')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.text.trim().length > 0 ? MemoryTheme.status.successInk : MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(this.text.trim().length > 0 ? MemoryTheme.status.successBg : MemoryTheme.colors.surfaceStrong)
            .borderRadius(MemoryTheme.radius.pill);

          Text(this.locationName.trim().length > 0 ? '地点已填' : '地点待填')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.locationName.trim().length > 0 ? MemoryTheme.status.successInk : MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(this.locationName.trim().length > 0 ? MemoryTheme.status.successBg : MemoryTheme.colors.surfaceStrong)
            .borderRadius(MemoryTheme.radius.pill);
        }

        Flex({ wrap: FlexWrap.Wrap }) {
          Text('没有照片')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);

          Text(`${this.text.trim().length} 字`)
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);

          Text(this.getMoodLabel())
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);

          Text(this.locationName.trim().length > 0 ? this.locationName.trim() : '未记录地点')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.colors.muted)
            .padding({ left: 10, right: 10, top: 6, bottom: 6 })
            .backgroundColor(MemoryTheme.colors.surfaceStrong)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.pill);
        }
      }
      .width('100%')
      .padding(MemoryTheme.space.md)
      .backgroundColor(MemoryTheme.colors.surfaceStrong)
      .border({ width: 1, color: MemoryTheme.colors.line })
      .borderRadius(MemoryTheme.radius.card);

      Text(this.text.trim().length > 0 ? '保存状态：可以保存这个瞬间。' : '保存状态：输入一句话后可保存。')
        .fontSize(MemoryTheme.font.meta)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.text.trim().length > 0 ? MemoryTheme.status.successInk : MemoryTheme.status.neutralInk)
        .padding({ left: 10, right: 10, top: 8, bottom: 8 })
        .backgroundColor(this.text.trim().length > 0 ? MemoryTheme.status.successBg : MemoryTheme.status.neutralBg)
        .border({ width: 1, color: MemoryTheme.colors.line })
        .borderRadius(MemoryTheme.radius.card);

      Button('保存')
        .height(MemoryTheme.size.touchTarget)
        .width('100%')
        .fontSize(MemoryTheme.font.body)
        .fontWeight(FontWeight.Bold)
        .fontColor(MemoryTheme.colors.surfaceStrong)
        .backgroundColor(MemoryTheme.colors.primary)
        .borderRadius(MemoryTheme.radius.card)
        .enabled(this.text.trim().length > 0);

      Column({ space: MemoryTheme.space.sm }) {
        Text('保存后的下一步')
          .fontSize(MemoryTheme.font.caption)
          .fontWeight(FontWeight.Bold)
          .fontColor(MemoryTheme.status.successInk);

        Flex({ wrap: FlexWrap.Wrap }) {
          Text('查看时间线')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.status.successInk)
            .height(MemoryTheme.size.touchTarget)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.status.successBg)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .margin({ right: MemoryTheme.space.sm, bottom: MemoryTheme.space.sm });

          Text('继续记录')
            .fontSize(MemoryTheme.font.caption)
            .fontWeight(FontWeight.Bold)
            .fontColor(MemoryTheme.status.successInk)
            .height(MemoryTheme.size.touchTarget)
            .padding({ left: 10, right: 10, top: 7, bottom: 7 })
            .backgroundColor(MemoryTheme.status.successBg)
            .border({ width: 1, color: MemoryTheme.colors.line })
            .borderRadius(MemoryTheme.radius.card)
            .margin({ right: MemoryTheme.space.sm, bottom: MemoryTheme.space.sm });
        }

        Text('继续记录会回到一句话输入。')
          .fontSize(MemoryTheme.font.caption)
          .fontColor(MemoryTheme.colors.muted);
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      .backgroundColor(MemoryTheme.colors.surfaceStrong)
      .border({ width: 1, color: MemoryTheme.colors.line })
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
