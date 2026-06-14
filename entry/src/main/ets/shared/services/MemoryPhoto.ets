import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { generateId } from '../util/MemoryUtil';

/**
 * 照片选择与落地服务。
 * PhotoViewPicker 免权限，但返回的 file://media/... URI 只有临时读权限，
 * 必须复制进应用沙箱 filesDir 才能长期持有与展示。ArkUI Image() 接受沙箱绝对路径（不加 file:// 前缀）。
 */

const MEDIA_DIR_NAME: string = 'moments';

export async function pickImagesToSandbox(context: common.UIAbilityContext, maxCount: number): Promise<string[]> {
  const saved: string[] = [];
  try {
    const picker: photoAccessHelper.PhotoViewPicker = new photoAccessHelper.PhotoViewPicker();
    const options: photoAccessHelper.PhotoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
    options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
    options.maxSelectNumber = maxCount;
    const result: photoAccessHelper.PhotoSelectResult = await picker.select(options);
    const uris: string[] = result.photoUris;
    for (let index = 0; index < uris.length; index++) {
      const dest: string = await copyUriToSandbox(context, uris[index]);
      if (dest.length > 0) {
        saved.push(dest);
      }
    }
  } catch (err) {
    // 用户取消（错误码 202）属于正常流程；其他异常也回退为“未选择”。
  }
  return saved;
}

export function deleteSandboxFile(path: string): void {
  try {
    fileIo.unlinkSync(path);
  } catch (err) {
    // 文件可能已被移除，忽略。
  }
}

async function copyUriToSandbox(context: common.UIAbilityContext, uri: string): Promise<string> {
  const dir: string = `${context.filesDir}/${MEDIA_DIR_NAME}`;
  ensureDir(dir);
  const destPath: string = `${dir}/${generateId()}.${extractExtension(uri)}`;
  let sourceFd: number = -1;
  try {
    const source: fileIo.File = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
    sourceFd = source.fd;
    await fileIo.copyFile(sourceFd, destPath);
    return destPath;
  } catch (err) {
    return '';
  } finally {
    if (sourceFd >= 0) {
      try {
        fileIo.closeSync(sourceFd);
      } catch (closeErr) {
        // 关闭失败不影响复制结果。
      }
    }
  }
}

function ensureDir(dir: string): void {
  try {
    fileIo.mkdirSync(dir);
  } catch (err) {
    // 目录已存在时会抛错，忽略即可。
  }
}

function extractExtension(uri: string): string {
  const dot: number = uri.lastIndexOf('.');
  if (dot >= 0 && dot < uri.length - 1) {
    const ext: string = uri.substring(dot + 1).toLowerCase();
    if (ext.length > 0 && ext.length <= 5) {
      return ext;
    }
  }
  return 'jpg';
}
