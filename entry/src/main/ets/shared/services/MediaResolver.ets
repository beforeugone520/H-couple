import { fileIo } from '@kit.CoreFileKit';
import { MemoryApiConfig } from './MemoryApi';
import { MemoryStorage } from './MemoryStorage';

/**
 * 把已上传的 Storage 对象 path 解析成可直接喂给 ArkUI Image() 的沙箱缓存绝对路径。
 * 命中缓存直接返回；未命中则申请 signed URL 下载到 cacheDir 后返回。失败返回空串。
 * 缓存文件名对 path 做确定性映射（'/' -> '_'），保证同一 path 跨重启命中同一文件。
 */

const SIGNED_URL_TTL_SEC: number = 600;

/** storage path（形如 spaceId/userId/uuid.ext）不以 '/' 开头；本地沙箱绝对路径以 '/' 开头。 */
export function isLocalAbsolutePath(path: string): boolean {
  return path.startsWith('/');
}

function cacheNameOf(storagePath: string): string {
  return storagePath.replace(/\//g, '_');
}

function ensureDir(dir: string): void {
  try {
    fileIo.mkdirSync(dir);
  } catch (err) {
    // 目录已存在时会抛错，忽略即可。
  }
}

function cacheExists(dest: string): boolean {
  try {
    return fileIo.accessSync(dest);
  } catch (err) {
    return false;
  }
}

export async function resolveStoragePath(
  config: MemoryApiConfig,
  storagePath: string,
  cacheDir: string
): Promise<string> {
  ensureDir(cacheDir);
  const dest: string = `${cacheDir}/${cacheNameOf(storagePath)}`;
  if (cacheExists(dest)) {
    return dest;
  }
  try {
    const storage: MemoryStorage = new MemoryStorage(config);
    const signed: string = await storage.createSignedUrl(storagePath, SIGNED_URL_TTL_SEC);
    await storage.downloadToCache(signed, dest);
    return dest;
  } catch (err) {
    return '';
  }
}
