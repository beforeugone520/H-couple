import { useEffect, useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../../lib/supabase';
import { StatusMessage, type StatusTone } from '../shared/StatusMessage';

type AuthGateProps = {
  children: (session: Session) => JSX.Element;
};

export function AuthGate({ children }: AuthGateProps) {
  const [session, setSession] = useState<Session | null>(null);
  const [email, setEmail] = useState('');
  const [status, setStatus] = useState('请输入邮箱登录。');
  const [statusTone, setStatusTone] = useState<StatusTone>('neutral');
  const [isSending, setIsSending] = useState(false);
  const [hasSentMagicLink, setHasSentMagicLink] = useState(false);
  const normalizedEmail = email.trim();
  const isEmailReady = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(normalizedEmail);
  const canRequestMagicLink = isEmailReady && !isSending;
  const emailStatus = normalizedEmail.length === 0
    ? '邮箱待输入'
    : isEmailReady
      ? '邮箱格式可用，可以发送链接'
      : '请输入完整邮箱地址';

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => setSession(data.session));
    const { data } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
    });
    return () => data.subscription.unsubscribe();
  }, []);

  async function requestMagicLink() {
    if (!canRequestMagicLink) {
      return;
    }

    try {
      setIsSending(true);
      setHasSentMagicLink(false);
      setStatus('正在发送登录链接...');
      setStatusTone('pending');
      const { error } = await supabase.auth.signInWithOtp({
        email: normalizedEmail,
        options: { emailRedirectTo: window.location.origin }
      });
      setStatus(error ? error.message : '登录链接已发送，请查看邮箱。');
      setStatusTone(error ? 'error' : 'success');
      setHasSentMagicLink(!error);
    } finally {
      setIsSending(false);
    }
  }

  if (session) {
    return children(session);
  }

  return (
    <section className="panel auth-panel">
      <div className="section-heading">
        <p className="eyebrow">邮箱登录</p>
        <h2>先确认是你</h2>
      </div>
      <div className="onboarding-rail auth-rail" aria-label="登录方式">
        <span className="onboarding-label">登录方式</span>
        <div className="onboarding-pills">
          <span className="onboarding-pill">一次性链接</span>
          <span className="onboarding-pill">不需要密码</span>
          <span className="onboarding-pill">仅用于确认身份</span>
        </div>
      </div>
      <label className="field">
        <span>邮箱</span>
        <input
          aria-label="邮箱"
          aria-describedby="email-login-helper"
          autoComplete="email"
          inputMode="email"
          type="email"
          value={email}
          onChange={(event) => {
            setEmail(event.target.value);
            setHasSentMagicLink(false);
          }}
          placeholder="you@example.com"
        />
        <span className="field-helper" id="email-login-helper">
          我们会发送一次性登录链接到这个邮箱。
        </span>
        <div
          aria-live="polite"
          className={`email-readiness ${canRequestMagicLink ? 'email-readiness-ready' : ''}`}
        >
          <span>邮箱状态</span>
          <strong>{emailStatus}</strong>
        </div>
      </label>
      <button
        aria-busy={isSending}
        className="primary-action"
        onClick={requestMagicLink}
        disabled={!canRequestMagicLink}
      >
        {isSending ? '发送中...' : '发送登录链接'}
      </button>
      {hasSentMagicLink && (
        <div className="auth-next-steps" aria-label="登录下一步">
          <span className="auth-next-label">下一步</span>
          <ol>
            <li>检查邮箱</li>
            <li>点击登录链接</li>
            <li>回到时光盒</li>
          </ol>
        </div>
      )}
      <StatusMessage message={status} tone={statusTone} />
    </section>
  );
}
