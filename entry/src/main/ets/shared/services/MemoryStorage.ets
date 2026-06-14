import { http } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { MemoryApiConfig } from './MemoryApi';
import { generateId, readString } from '../util/MemoryUtil';

/**
 * Supabase Storage REST 封装（bucket `moments`，private）。
 * HOS 端把沙箱照片上传到 Storage 并只保存对象 path（与 PWA 一致），
 * 渲染时按 path 申请短期 signed URL 下载到沙箱缓存再用本地绝对路径显示。
 * URL / anon key / access token 只在运行时注入，不在源码硬编码真实值（见 AGENTS.md）。
 */

const BUCKET: string = 'moments';

function extOf(path: string): string {
  const dot: number = path.lastIndexOf('.');
  if (dot >= 0 && dot < path.length - 1) {
    const ext: string = path.substring(dot + 1).toLowerCase();
    if (ext.length > 0 && ext.length <= 5) {
      return ext;
    }
  }
  return 'jpg';
}

function contentTypeOf(ext: string): string {
  if (ext === 'png') {
    return 'image/png';
  }
  if (ext === 'webp') {
    return 'image/webp';
  }
  if (ext === 'heic' || ext === 'heif') {
    return 'image/heic';
  }
  if (ext === 'gif') {
    return 'image/gif';
  }
  return 'image/jpeg';
}

function readFileToBuffer(path: string): ArrayBuffer {
  const stat: fileIo.Stat = fileIo.statSync(path);
  const buffer: ArrayBuffer = new ArrayBuffer(stat.size);
  const file: fileIo.File = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
  try {
    fileIo.readSync(file.fd, buffer);
  } finally {
    fileIo.closeSync(file);
  }
  return buffer;
}

export class MemoryStorage {
  private config: MemoryApiConfig;

  constructor(config: MemoryApiConfig) {
    this.config = config;
  }

  private bearer(): string {
    return this.config.accessToken.length > 0 ? this.config.accessToken : this.config.anonKey;
  }

  /** 上传一个沙箱文件到 Storage，返回对象 path（{spaceId}/{userId}/{uuid}.{ext}，不含 bucket）。 */
  async uploadSandboxFile(coupleSpaceId: string, userId: string, localPath: string): Promise<string> {
    const ext: string = extOf(localPath);
    const objectPath: string = `${coupleSpaceId}/${userId}/${generateId()}.${ext}`;
    const buffer: ArrayBuffer = readFileToBuffer(localPath);
    const url: string = `${this.config.supabaseUrl}/storage/v1/object/${BUCKET}/${objectPath}`;
    const request: http.HttpRequest = http.createHttp();
    try {
      const header: Record<string, string> = {};
      header['Content-Type'] = contentTypeOf(ext);
      header['apikey'] = this.config.anonKey;
      header['Authorization'] = `Bearer ${this.bearer()}`;
      header['x-upsert'] = 'false';
      header['cache-control'] = 'max-age=3600';
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: header,
        extraData: buffer,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 15000,
        readTimeout: 30000
      };
      const response: http.HttpResponse = await request.request(url, options);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`上传失败：HTTP ${response.responseCode}`);
      }
      return objectPath;
    } finally {
      request.destroy();
    }
  }

  /** 为对象 path 申请短期 signed URL，返回可直接 GET 的完整下载 URL。 */
  async createSignedUrl(storagePath: string, expiresInSec: number): Promise<string> {
    const url: string = `${this.config.supabaseUrl}/storage/v1/object/sign/${BUCKET}/${storagePath}`;
    const body: Record<string, Object> = {};
    body['expiresIn'] = expiresInSec;
    const request: http.HttpRequest = http.createHttp();
    try {
      const header: Record<string, string> = {};
      header['Content-Type'] = 'application/json';
      header['apikey'] = this.config.anonKey;
      header['Authorization'] = `Bearer ${this.bearer()}`;
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: header,
        extraData: JSON.stringify(body),
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 15000
      };
      const response: http.HttpResponse = await request.request(url, options);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`申请签名失败：HTTP ${response.responseCode}`);
      }
      if (typeof response.result !== 'string') {
        throw new Error('申请签名失败：响应异常');
      }
      const root: Record<string, Object> = JSON.parse(response.result) as Record<string, Object>;
      const signed: string = readString(root, 'signedURL');
      if (signed.length === 0) {
        throw new Error('申请签名失败：未返回签名 URL');
      }
      return `${this.config.supabaseUrl}/storage/v1${signed}`;
    } finally {
      request.destroy();
    }
  }

  /** GET 一个 signed URL 的二进制内容，落地到沙箱缓存绝对路径 destPath。 */
  async downloadToCache(signedFullUrl: string, destPath: string): Promise<void> {
    const request: http.HttpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 30000
      };
      const response: http.HttpResponse = await request.request(signedFullUrl, options);
      if (response.responseCode < 200 || response.responseCode >= 300) {
        throw new Error(`下载失败：HTTP ${response.responseCode}`);
      }
      if (!(response.result instanceof ArrayBuffer)) {
        throw new Error('下载失败：响应不是二进制');
      }
      const file: fileIo.File = fileIo.openSync(destPath, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      try {
        fileIo.writeSync(file.fd, response.result);
      } finally {
        fileIo.closeSync(file);
      }
    } finally {
      request.destroy();
    }
  }
}
