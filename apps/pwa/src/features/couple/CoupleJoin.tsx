import { useState } from 'react';
import { supabase } from '../../lib/supabase';
import { StatusMessage, type StatusTone } from '../shared/StatusMessage';

type CoupleJoinProps = {
  onJoined: (coupleSpaceId: string, inviteCode?: string) => void;
};

type CreatedSpace = {
  couple_space_id: string;
  invite_code: string;
};

type PendingAction = 'create' | 'join' | null;

function normalizeInviteCode(value: string) {
  return value.replace(/\s+/g, '').toUpperCase();
}

export function CoupleJoin({ onJoined }: CoupleJoinProps) {
  const [inviteCode, setInviteCode] = useState('');
  const [status, setStatus] = useState('');
  const [statusTone, setStatusTone] = useState<StatusTone>('neutral');
  const [pendingAction, setPendingAction] = useState<PendingAction>(null);
  const isCreating = pendingAction === 'create';
  const isJoining = pendingAction === 'join';
  const isPending = pendingAction !== null;
  const canJoin = inviteCode.trim().length >= 4 && !isPending;
  const inviteCodeStatus = inviteCode.length === 0
    ? '邀请码待输入'
    : inviteCode.length < 4
      ? '至少 4 位后可以加入'
      : '邀请码已整理，可以加入';

  async function createSpace() {
    if (isPending) {
      return;
    }

    try {
      setPendingAction('create');
      setStatus('正在创建双人空间...');
      setStatusTone('pending');
      const { data, error } = await supabase.rpc('create_couple_space');
      const created = Array.isArray(data) ? (data[0] as CreatedSpace | undefined) : undefined;

      if (error || !created) {
        setStatus(error?.message ?? '创建失败');
        setStatusTone('error');
        return;
      }

      setStatus(`邀请码：${created.invite_code}`);
      setStatusTone('success');
      onJoined(created.couple_space_id, created.invite_code);
    } finally {
      setPendingAction(null);
    }
  }

  async function joinSpace() {
    if (!canJoin) {
      return;
    }

    try {
      setPendingAction('join');
      setStatus('正在加入双人空间...');
      setStatusTone('pending');
      const { data, error } = await supabase.rpc('join_couple_space', {
        join_code: inviteCode
      });

      if (error || typeof data !== 'string') {
        setStatus(error?.message ?? '加入失败');
        setStatusTone('error');
        return;
      }

      onJoined(data);
    } finally {
      setPendingAction(null);
    }
  }

  return (
    <section className="panel join-panel">
      <div className="section-heading">
        <p className="eyebrow">双人空间</p>
        <h2>创建或加入你们的时光盒</h2>
      </div>
      <div className="setup-rail" aria-label="空间准备">
        <span className="onboarding-label">空间准备</span>
        <div className="setup-steps">
          <span className="setup-step">1. 创建空间</span>
          <span className="setup-step">2. 复制邀请码</span>
          <span className="setup-step">3. 对方加入</span>
        </div>
      </div>
      <button
        aria-busy={isCreating}
        className="primary-action"
        disabled={isPending}
        onClick={createSpace}
      >
        {isCreating ? '创建中...' : '创建双人空间'}
      </button>
      <p className="join-divider">已有邀请码</p>
      <div className="join-row">
        <label className="field">
          <span>邀请码</span>
          <input
            aria-label="邀请码"
            aria-describedby="invite-code-helper"
            autoCapitalize="characters"
            className="code-input"
            inputMode="text"
            value={inviteCode}
            onChange={(event) => setInviteCode(normalizeInviteCode(event.target.value))}
            placeholder="输入邀请码"
          />
          <span className="field-helper" id="invite-code-helper">
            邀请码会自动转为大写并移除空格。
          </span>
          <div
            aria-live="polite"
            className={`invite-readiness ${canJoin ? 'invite-readiness-ready' : ''}`}
          >
            <span>邀请码状态</span>
            <strong>{inviteCodeStatus}</strong>
          </div>
        </label>
        <button aria-busy={isJoining} className="secondary-action" onClick={joinSpace} disabled={!canJoin}>
          {isJoining ? '加入中...' : '加入'}
        </button>
      </div>
      <StatusMessage message={status} tone={statusTone} />
    </section>
  );
}
