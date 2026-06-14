import { describe, expect, it } from 'vitest';
import {
  buildInviteUrl,
  clearStashedInviteCode,
  normalizeInviteCode,
  parseInviteCodeFromLocation,
  readStashedInviteCode,
  stashInviteCode
} from './inviteLink';

function fakeStorage(): Storage {
  const map = new Map<string, string>();
  return {
    get length() {
      return map.size;
    },
    clear: () => map.clear(),
    getItem: (key: string) => (map.has(key) ? (map.get(key) as string) : null),
    key: (index: number) => Array.from(map.keys())[index] ?? null,
    removeItem: (key: string) => map.delete(key),
    setItem: (key: string, value: string) => map.set(key, value)
  };
}

describe('normalizeInviteCode', () => {
  it('uppercases and strips whitespace', () => {
    expect(normalizeInviteCode(' love 42 ')).toBe('LOVE42');
  });
});

describe('parseInviteCodeFromLocation', () => {
  it('extracts the code from a query string', () => {
    expect(parseInviteCodeFromLocation('?code=LOVE42', '')).toBe('LOVE42');
  });

  it('extracts the code from a hash fragment', () => {
    expect(parseInviteCodeFromLocation('', '#code=LOVE42')).toBe('LOVE42');
  });

  it('extracts the code from a hash route with its own query', () => {
    expect(parseInviteCodeFromLocation('', '#/join?code=LOVE42')).toBe('LOVE42');
  });

  it('normalizes a lowercase spaced code from the link', () => {
    expect(parseInviteCodeFromLocation('?code=lo ve42', '')).toBe('LOVE42');
  });

  it('prefers the query string over the hash when both are present', () => {
    expect(parseInviteCodeFromLocation('?code=AAA111', '#code=BBB222')).toBe('AAA111');
  });

  it('returns an empty string when no code is present', () => {
    expect(parseInviteCodeFromLocation('?foo=bar', '')).toBe('');
  });

  it('returns an empty string when the code parameter is empty', () => {
    expect(parseInviteCodeFromLocation('?code=', '')).toBe('');
  });
});

describe('buildInviteUrl', () => {
  it('appends the code as a query parameter to the origin', () => {
    expect(buildInviteUrl('LOVE42', 'https://memorybox.example.com')).toBe(
      'https://memorybox.example.com/?code=LOVE42'
    );
  });

  it('does not double the slash when origin has a trailing slash', () => {
    expect(buildInviteUrl('LOVE42', 'https://memorybox.example.com/')).toBe(
      'https://memorybox.example.com/?code=LOVE42'
    );
  });
});

describe('invite code stash (magic-link round trip)', () => {
  it('stashes and reads back a normalized code', () => {
    const storage = fakeStorage();
    stashInviteCode(' love42 ', storage);
    expect(readStashedInviteCode(storage)).toBe('LOVE42');
  });

  it('ignores empty codes when stashing', () => {
    const storage = fakeStorage();
    stashInviteCode('   ', storage);
    expect(readStashedInviteCode(storage)).toBe('');
  });

  it('clears a stashed code', () => {
    const storage = fakeStorage();
    stashInviteCode('LOVE42', storage);
    clearStashedInviteCode(storage);
    expect(readStashedInviteCode(storage)).toBe('');
  });
});
