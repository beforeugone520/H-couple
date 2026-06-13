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
}

interface ThemeSpace {
  xs: number;
  sm: number;
  md: number;
  lg: number;
  xl: number;
}

interface ThemeSize {
  touchTarget: number;
}

interface ThemeFont {
  caption: number;
  meta: number;
  body: number;
  title: number;
  display: number;
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
    blueSoft: '#E8EDF7'
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
    blueSoft: '#253047'
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
    pill: 999
  },
  space: {
    xs: 6,
    sm: 10,
    md: 14,
    lg: 18,
    xl: 24
  },
  size: {
    touchTarget: 44
  },
  font: {
    caption: 12,
    meta: 13,
    body: 15,
    title: 22,
    display: 34
  }
};
