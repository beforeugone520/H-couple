interface ThemeColors {
  background: string;
  surface: string;
  surfaceStrong: string;
  ink: string;
  muted: string;
  line: string;
  soft: string;
  primary: string;
  primaryDark: string;
  sage: string;
  sageSoft: string;
  roseSoft: string;
  goldSoft: string;
  blueSoft: string;
  inkSoft: string;
  overlayInk: string;
  hairline: string;
}

interface DarkThemeColors {
  background: string;
  surface: string;
  surfaceStrong: string;
  ink: string;
  muted: string;
  line: string;
  primary: string;
  primaryDark: string;
  sage: string;
  sageSoft: string;
  roseSoft: string;
  goldSoft: string;
  blueSoft: string;
  inkSoft: string;
  overlayInk: string;
  hairline: string;
}

interface ThemeStatus {
  neutralBg: string;
  neutralInk: string;
  pendingBg: string;
  pendingInk: string;
  successBg: string;
  successInk: string;
  errorBg: string;
  errorInk: string;
}

interface ThemeSkeleton {
  base: string;
  highlight: string;
}

interface ThemeEmptyState {
  actionBg: string;
  actionInk: string;
  hintBg: string;
  hintInk: string;
}

interface ThemeRadius {
  card: number;
  pill: number;
  photo: number;
  chip: number;
}

interface ThemeSpace {
  xxs: number;
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
  xxl: number;
}

interface ThemeSize {
  touchTarget: number;
}

interface ThemeFont {
  label: number;
  caption: number;
  meta: number;
  body: number;
  subtitle: number;
  title: number;
  display: number;
  hero: number;
  poster: number;
}

/** ArkUI .shadow() 接受 ShadowOptions（数值 radius/offsetY + 颜色），故阴影用结构化数值承载。颜色为 ARGB 字符串。 */
interface ThemeElevation {
  cardRadius: number;
  cardColor: string;
  cardOffsetY: number;
  raisedRadius: number;
  raisedColor: string;
  raisedOffsetY: number;
  heroRadius: number;
  heroColor: string;
  heroOffsetY: number;
}

/** 动效时长（毫秒）：照片淡入 enter、切换 base、按压 fast、数字过渡 slow。 */
interface ThemeMotion {
  fast: number;
  base: number;
  slow: number;
  enter: number;
}

/** 渐变锚点色：英雄卡背景、对方语义色块、照片底部压暗蒙版。 */
interface ThemeGradient {
  heroFrom: string;
  heroTo: string;
  sageFrom: string;
  sageTo: string;
  photoMaskTop: string;
  photoMaskBottom: string;
}

interface ThemeTokens {
  colors: ThemeColors;
  darkColors: DarkThemeColors;
  status: ThemeStatus;
  darkStatus: ThemeStatus;
  skeleton: ThemeSkeleton;
  darkSkeleton: ThemeSkeleton;
  emptyState: ThemeEmptyState;
  darkEmptyState: ThemeEmptyState;
  radius: ThemeRadius;
  space: ThemeSpace;
  size: ThemeSize;
  font: ThemeFont;
  elevation: ThemeElevation;
  darkElevation: ThemeElevation;
  motion: ThemeMotion;
  gradient: ThemeGradient;
  darkGradient: ThemeGradient;
}

export const MemoryTheme: ThemeTokens = {
  colors: {
    background: '#F7F0E8',
    surface: '#FFFAF5',
    surfaceStrong: '#FFFFFF',
    ink: '#191612',
    muted: '#776A5F',
    line: '#E5D6C8',
    soft: '#EEE2D6',
    primary: '#B4235F',
    primaryDark: '#811A45',
    sage: '#5F7351',
    sageSoft: '#E8EFDF',
    roseSoft: '#F6DFE9',
    goldSoft: '#F7EAD3',
    blueSoft: '#E8EDF7',
    inkSoft: '#3D352E',
    overlayInk: '#A6191612',
    hairline: '#EFE6DA'
  },
  darkColors: {
    background: '#191412',
    surface: '#241D1A',
    surfaceStrong: '#2F2622',
    ink: '#F8EFE8',
    muted: '#CBB8AA',
    line: '#4A3A34',
    primary: '#FF76AA',
    primaryDark: '#FFB3CD',
    sage: '#B9D3A6',
    sageSoft: '#263321',
    roseSoft: '#3C2230',
    goldSoft: '#35291D',
    blueSoft: '#253047',
    inkSoft: '#D8C8BC',
    overlayInk: '#A6F8EFE8',
    hairline: '#3A302C'
  },
  status: {
    neutralBg: '#FFFFFF',
    neutralInk: '#5F5147',
    pendingBg: '#F7EAD3',
    pendingInk: '#7B4D10',
    successBg: '#E8EFDF',
    successInk: '#3D5534',
    errorBg: '#F9E2E2',
    errorInk: '#8F2020'
  },
  darkStatus: {
    neutralBg: '#2F2622',
    neutralInk: '#EAD8CC',
    pendingBg: '#35291D',
    pendingInk: '#F0C477',
    successBg: '#263321',
    successInk: '#CDE4BC',
    errorBg: '#3A2020',
    errorInk: '#FFB7B7'
  },
  skeleton: {
    base: '#EEE2D6',
    highlight: '#FFFAF5'
  },
  darkSkeleton: {
    base: '#3A302C',
    highlight: '#4A3A34'
  },
  emptyState: {
    actionBg: '#B4235F',
    actionInk: '#FFFFFF',
    hintBg: '#F6DFE9',
    hintInk: '#811A45'
  },
  darkEmptyState: {
    actionBg: '#FF76AA',
    actionInk: '#191412',
    hintBg: '#3C2230',
    hintInk: '#FFB3CD'
  },
  radius: {
    card: 8,
    pill: 999,
    photo: 14,
    chip: 10
  },
  space: {
    xxs: 4,
    xs: 6,
    sm: 10,
    md: 14,
    lg: 18,
    xl: 24,
    xxl: 32
  },
  size: {
    touchTarget: 44
  },
  font: {
    label: 11,
    caption: 12,
    meta: 13,
    body: 15,
    subtitle: 18,
    title: 22,
    display: 34,
    hero: 48,
    poster: 60
  },
  elevation: {
    cardRadius: 12,
    cardColor: '#1426190E',
    cardOffsetY: 4,
    raisedRadius: 18,
    raisedColor: '#1F26190E',
    raisedOffsetY: 8,
    heroRadius: 26,
    heroColor: '#2426190E',
    heroOffsetY: 12
  },
  darkElevation: {
    cardRadius: 14,
    cardColor: '#40000000',
    cardOffsetY: 6,
    raisedRadius: 20,
    raisedColor: '#59000000',
    raisedOffsetY: 10,
    heroRadius: 28,
    heroColor: '#73000000',
    heroOffsetY: 14
  },
  motion: {
    fast: 120,
    base: 220,
    slow: 360,
    enter: 520
  },
  gradient: {
    heroFrom: '#FBEAF1',
    heroTo: '#F7F0E8',
    sageFrom: '#E8EFDF',
    sageTo: '#F7F0E8',
    photoMaskTop: '#00191612',
    photoMaskBottom: '#73191612'
  },
  darkGradient: {
    heroFrom: '#3C2230',
    heroTo: '#191412',
    sageFrom: '#263321',
    sageTo: '#191412',
    photoMaskTop: '#00000000',
    photoMaskBottom: '#73000000'
  }
};
