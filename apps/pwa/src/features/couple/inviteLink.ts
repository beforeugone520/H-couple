/**
 * 邀请码与邀请链接工具。
 * 对方在 iPhone 上通过 {origin}/?code=XXX 形式的链接（或扫描包含该链接的二维码）打开 PWA，
 * 这里负责从 URL 中解析出邀请码，让加入空间这一步无需手输。
 */

export function normalizeInviteCode(value: string): string {
  return value.replace(/\s+/g, '').toUpperCase();
}

/** 从 location.search 与 location.hash 中解析邀请码；query 优先于 hash，找不到返回空串。 */
export function parseInviteCodeFromLocation(search: string, hash: string): string {
  const fromSearch = new URLSearchParams(search).get('code') ?? '';
  if (fromSearch.trim().length > 0) {
    return normalizeInviteCode(fromSearch);
  }
  const hashQuery = hash.includes('?') ? hash.slice(hash.indexOf('?')) : hash.replace(/^#/, '');
  const fromHash = new URLSearchParams(hashQuery).get('code') ?? '';
  return normalizeInviteCode(fromHash);
}

/** 把邀请码编码成可分享/可生成二维码的深链接：{origin}/?code=XXX。 */
export function buildInviteUrl(code: string, origin: string): string {
  const base = origin.replace(/\/+$/, '');
  return `${base}/?code=${encodeURIComponent(normalizeInviteCode(code))}`;
}

const STASH_KEY = 'memorybox_invite_code';

/**
 * 在 Magic Link 登录往返之间暂存邀请码。
 * 未登录用户点开 {origin}/?code=XXX，登录链接 redirect 回 origin 时会丢掉 query，
 * 故先把邀请码存进 sessionStorage，登录成功后再取回预填。
 */
export function stashInviteCode(code: string, storage: Storage): void {
  const normalized = normalizeInviteCode(code);
  if (normalized.length > 0) {
    storage.setItem(STASH_KEY, normalized);
  }
}

export function readStashedInviteCode(storage: Storage): string {
  return storage.getItem(STASH_KEY) ?? '';
}

export function clearStashedInviteCode(storage: Storage): void {
  storage.removeItem(STASH_KEY);
}
