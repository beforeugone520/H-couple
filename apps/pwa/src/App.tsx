import { useState } from 'react';
import { AuthGate } from './features/auth/AuthGate';
import { MemoryPreview } from './features/brand/MemoryPreview';
import { CoupleJoin } from './features/couple/CoupleJoin';
import { MomentComposer } from './features/moments/MomentComposer';
import { Timeline } from './features/moments/Timeline';
import { WorkspaceHeader } from './features/shared/WorkspaceHeader';

export function App() {
  const [coupleSpaceId, setCoupleSpaceId] = useState('');
  const [inviteCode, setInviteCode] = useState('');
  const [refreshKey, setRefreshKey] = useState(0);

  function enterCoupleSpace(nextCoupleSpaceId: string, nextInviteCode = '') {
    setCoupleSpaceId(nextCoupleSpaceId);
    setInviteCode(nextInviteCode);
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
              <Timeline coupleSpaceId={coupleSpaceId} refreshKey={refreshKey} />
            </div>
          ) : (
            <CoupleJoin onJoined={enterCoupleSpace} />
          )
        }
      </AuthGate>
    </main>
  );
}
