import { describe, expect, it } from '@ohos/hypium';
import { MemoryTheme } from '../../../main/ets/shared/theme/MemoryTheme';

export default function visualThemeTest() {
  describe('VisualThemeTest', () => {
    it('defines shared native surface and action tokens', 0, () => {
      expect(MemoryTheme.colors.background).assertEqual('#F7F0E8');
      expect(MemoryTheme.colors.primary).assertEqual('#B4235F');
      expect(MemoryTheme.darkColors.background).assertEqual('#191412');
      expect(MemoryTheme.darkColors.surface).assertEqual('#241D1A');
      expect(MemoryTheme.status.successBg).assertEqual('#E8EFDF');
      expect(MemoryTheme.status.errorInk).assertEqual('#8F2020');
      expect(MemoryTheme.skeleton.base).assertEqual('#EEE2D6');
      expect(MemoryTheme.skeleton.highlight).assertEqual('#FFFAF5');
      expect(MemoryTheme.darkSkeleton.base).assertEqual('#3A302C');
      expect(MemoryTheme.darkSkeleton.highlight).assertEqual('#4A3A34');
      expect(MemoryTheme.emptyState.actionBg).assertEqual('#B4235F');
      expect(MemoryTheme.emptyState.actionInk).assertEqual('#FFFFFF');
      expect(MemoryTheme.darkEmptyState.actionBg).assertEqual('#FF76AA');
      expect(MemoryTheme.darkEmptyState.actionInk).assertEqual('#191412');
      expect(MemoryTheme.radius.card).assertEqual(8);
      expect(MemoryTheme.size.touchTarget).assertEqual(44);
    })
  })
}
