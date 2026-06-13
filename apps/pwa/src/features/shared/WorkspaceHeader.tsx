import { useState } from 'react';

const workspaceStatuses = ['已连接', '私密空间', '时间线同步'];

type WorkspaceHeaderProps = {
  inviteCode?: string;
};

type CopyStatusTone = 'neutral' | 'success' | 'error';

export function WorkspaceHeader({ inviteCode = '' }: WorkspaceHeaderProps) {
  const [copyStatus, setCopyStatus] = useState('');
  const [copyStatusTone, setCopyStatusTone] = useState<CopyStatusTone>('neutral');

  async function copyInviteCode() {
    if (!inviteCode) {
      return;
    }

    try {
      await navigator.clipboard.writeText(inviteCode);
      setCopyStatus('已复制邀请码');
      setCopyStatusTone('success');
    } catch {
      setCopyStatus(`复制失败，请手动复制 ${inviteCode}`);
      setCopyStatusTone('error');
    }
  }

  return (
    <section className="workspace-header" aria-labelledby="workspace-heading">
      <div>
        <p className="eyebrow">当前工作区</p>
        <h2 id="workspace-heading">双人空间已连接</h2>
        <p className="workspace-subtitle">记录、回应和回看都会同步到这个私密空间。</p>
      </div>
      <div className="workspace-meta">
        {inviteCode && (
          <div className="workspace-invite" aria-label="新建空间邀请码">
            <span className="workspace-invite-label">邀请对方加入</span>
            <strong>{inviteCode}</strong>
            <span>复制后发给对方，对方加入后即可共同记录。</span>
            <div className="workspace-invite-actions">
              <button
                aria-label={`复制邀请码 ${inviteCode}`}
                className="workspace-copy-button"
                onClick={copyInviteCode}
                type="button"
              >
                复制邀请码
              </button>
              <span aria-live="polite" className={`workspace-copy-status workspace-copy-status-${copyStatusTone}`}>
                {copyStatus}
              </span>
            </div>
          </div>
        )}
        <div className="workspace-status" aria-label="工作区状态">
          {workspaceStatuses.map((status) => (
            <span className="workspace-status-item" key={status}>
              {status}
            </span>
          ))}
        </div>
        <nav className="workspace-actions" aria-label="工作区快捷操作">
          <a aria-label="主操作：记录瞬间" className="workspace-link workspace-link-primary" href="#moment-composer">
            记录瞬间
          </a>
          <a className="workspace-link workspace-link-secondary" href="#timeline-panel">
            查看时间线
          </a>
        </nav>
      </div>
    </section>
  );
}
