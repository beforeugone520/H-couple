import { useState } from 'react';
import { AuthGate } from './features/auth/AuthGate';
import { MemoryPreview } from './features/brand/MemoryPreview';
import { CoupleJoin } from './features/couple/CoupleJoin';
import {
  clearStashedInviteCode,
  parseInviteCodeFromLocation,
  readStashedInviteCode,
  stashInviteCode
} from './features/couple/inviteLink';
import { Anniversaries } from './features/anniversary/Anniversaries';
import { MomentComposer } from './features/moments/MomentComposer';
import { Timeline } from './features/moments/Timeline';
import { WorkspaceHeader } from './features/shared/WorkspaceHeader';

export function App() {
  const [coupleSpaceId, setCoupleSpaceId] = useState('');
  const [inviteCode, setInviteCode] = useState('');
  const [refreshKey, setRefreshKey] = useState(0);
  const [detectedInviteCode] = useState(() => {
    if (typeof window === 'undefined') {
      return '';
    }
    const fromUrl = parseInviteCodeFromLocation(window.location.search, window.location.hash);
    if (fromUrl) {
      // 未登录用户点开邀请链接时，Magic Link 登录往返会丢掉 query，先暂存以便回来预填。
      stashInviteCode(fromUrl, window.sessionStorage);
      return fromUrl;
    }
    return readStashedInviteCode(window.sessionStorage);
  });

  function enterCoupleSpace(nextCoupleSpaceId: string, nextInviteCode = '') {
    setCoupleSpaceId(nextCoupleSpaceId);
    setInviteCode(nextInviteCode);
    if (typeof window !== 'undefined') {
      clearStashedInviteCode(window.sessionStorage);
    }
  }

  return (
    <main className="app-shell">
      <header className="app-hero">
        <div className="hero-copy">
          <p className="eyebrow">只属于两个人</p>
          <h1>双人时光盒</h1>
          <p className="hero-subtitle">把照片、一句话和轻回应收进同一个私密空间。</p>
        </div>
        <MemoryPreview />
      </header>
      <AuthGate>
        {(session) =>
          coupleSpaceId ? (
            <div className="workspace">
              <WorkspaceHeader inviteCode={inviteCode} />
              <MomentComposer
                session={session}
                coupleSpaceId={coupleSpaceId}
                onCreated={() => setRefreshKey((value) => value + 1)}
              />
              <Anniversaries coupleSpaceId={coupleSpaceId} />
              <Timeline coupleSpaceId={coupleSpaceId} refreshKey={refreshKey} currentUserId={session.user.id} />
            </div>
          ) : (
            <CoupleJoin onJoined={enterCoupleSpace} detectedInviteCode={detectedInviteCode} />
          )
        }
      </AuthGate>
    </main>
  );
}
