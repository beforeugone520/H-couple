import { create } from 'qrcode';
import { buildInviteUrl } from '../couple/inviteLink';

type InviteQrProps = {
  code: string;
  origin?: string;
};

const QUIET_ZONE = 2;

/**
 * 把邀请深链接（{origin}/?code=XXX）渲染成内联 SVG 二维码，供对方用相机扫码加入。
 * 用成熟的 qrcode 编码器保证可被相机识别；内联 SVG（非 canvas）以便在 jsdom 下可测、可缩放。
 */
export function InviteQr({ code, origin }: InviteQrProps) {
  if (code.trim().length === 0) {
    return null;
  }

  const resolvedOrigin = origin ?? (typeof window === 'undefined' ? '' : window.location.origin);

  let size = 0;
  let modules: Uint8Array | number[] = [];
  try {
    const qr = create(buildInviteUrl(code, resolvedOrigin), { errorCorrectionLevel: 'M' });
    size = qr.modules.size;
    modules = qr.modules.data;
  } catch {
    return <p className="invite-qr-fallback">二维码生成失败，请改用邀请码加入。</p>;
  }

  const dimension = size + QUIET_ZONE * 2;
  const cells: JSX.Element[] = [];
  for (let row = 0; row < size; row += 1) {
    for (let col = 0; col < size; col += 1) {
      if (modules[row * size + col]) {
        cells.push(
          <rect key={`${row}-${col}`} x={col + QUIET_ZONE} y={row + QUIET_ZONE} width={1} height={1} />
        );
      }
    }
  }

  return (
    <svg
      className="invite-qr"
      role="img"
      aria-label="邀请二维码，对方用相机扫码后通过链接加入双人空间"
      viewBox={`0 0 ${dimension} ${dimension}`}
      shapeRendering="crispEdges"
    >
      <rect x={0} y={0} width={dimension} height={dimension} fill="#ffffff" />
      <g fill="#191612">{cells}</g>
    </svg>
  );
}
