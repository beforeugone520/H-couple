import { Fragment, useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { StatusMessage } from '../shared/StatusMessage';
import { TimelineSkeleton } from '../shared/TimelineSkeleton';
import { getMomentDisplayMeta, getMomentMonthLabel, normalizeMoment, responseLabels } from './momentService';
import type { Moment, MomentResponse, MomentRow } from './momentTypes';

type TimelineProps = {
  coupleSpaceId: string;
  refreshKey: number;
};

function buildMomentPhotoAlt(meta: ReturnType<typeof getMomentDisplayMeta>) {
  if (meta.locationLabel === '未记录地点') {
    return `${meta.dateLabel}的共同瞬间照片`;
  }

  return `${meta.dateLabel}，${meta.locationLabel}的共同瞬间照片`;
}

function buildMomentContextLabel(meta: ReturnType<typeof getMomentDisplayMeta>) {
  if (meta.locationLabel === '未记录地点') {
    return `${meta.dateLabel}的共同瞬间`;
  }

  return `${meta.dateLabel}，${meta.locationLabel}的共同瞬间`;
}

export function Timeline({ coupleSpaceId, refreshKey }: TimelineProps) {
  const [moments, setMoments] = useState<Moment[]>([]);
  const [signedUrlByPath, setSignedUrlByPath] = useState<Record<string, string>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [status, setStatus] = useState('');
  const [hasLoadError, setHasLoadError] = useState(false);
  const [retryKey, setRetryKey] = useState(0);
  const [pendingResponseByMomentId, setPendingResponseByMomentId] = useState<Record<string, MomentResponse>>({});
  const respondedCount = moments.filter((moment) => moment.response).length;
  const favoriteCount = moments.filter((moment) => moment.isFavorite).length;
  const latestMomentMeta = moments[0] ? getMomentDisplayMeta(moments[0]) : null;
  const countLabel = isLoading ? '加载中' : hasLoadError ? '加载失败' : `${moments.length} 条`;

  useEffect(() => {
    let isActive = true;

    async function load() {
      setIsLoading(true);
      setStatus('');
      setHasLoadError(false);

      try {
        const { data, error } = await supabase
          .from('moments')
          .select('*')
          .eq('couple_space_id', coupleSpaceId)
          .order('occurred_at', { ascending: false });

        if (!isActive) {
          return;
        }

        if (error) {
          setStatus(error.message);
          setHasLoadError(true);
          setMoments([]);
          setSignedUrlByPath({});
          return;
        }

        const nextMoments = ((data ?? []) as MomentRow[]).map(normalizeMoment);
        const nextSignedUrls = await signMedia(nextMoments);

        if (!isActive) {
          return;
        }

        setMoments(nextMoments);
        setSignedUrlByPath(nextSignedUrls);
        setHasLoadError(false);
      } catch (error) {
        if (!isActive) {
          return;
        }

        setStatus(error instanceof Error ? error.message : '加载时间线失败，请稍后再试。');
        setHasLoadError(true);
        setMoments([]);
        setSignedUrlByPath({});
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    }

    async function signMedia(nextMoments: Moment[]) {
      const paths = nextMoments.flatMap((moment) => moment.mediaUrls);
      const uniquePaths = Array.from(new Set(paths)).filter(Boolean);
      const nextSignedUrls: Record<string, string> = {};

      await Promise.all(
        uniquePaths.map(async (path) => {
          const { data, error } = await supabase.storage.from('moments').createSignedUrl(path, 60 * 10);
          if (!error && data?.signedUrl) {
            nextSignedUrls[path] = data.signedUrl;
          }
        })
      );

      return nextSignedUrls;
    }

    load();

    return () => {
      isActive = false;
    };
  }, [coupleSpaceId, refreshKey, retryKey]);

  async function respond(momentId: string, response: MomentResponse) {
    if (pendingResponseByMomentId[momentId]) {
      return;
    }

    setPendingResponseByMomentId((items) => ({ ...items, [momentId]: response }));

    try {
      const { error } = await supabase.from('moments').update({ response }).eq('id', momentId);
      if (error) {
        setStatus(error.message);
        return;
      }
      setMoments((items) => items.map((item) => (item.id === momentId ? { ...item, response } : item)));
    } finally {
      setPendingResponseByMomentId((items) => {
        const { [momentId]: _completedResponse, ...rest } = items;
        return rest;
      });
    }
  }

  return (
    <section className="panel timeline-panel" id="timeline-panel">
      <div className="section-heading timeline-heading">
        <div>
          <p className="eyebrow">共同回看</p>
          <h2>时间线</h2>
        </div>
        <span className={`count-pill ${hasLoadError ? 'count-pill-error' : ''}`}>{countLabel}</span>
      </div>
      <StatusMessage message={status} tone="error" />
      {isLoading ? (
        <TimelineSkeleton />
      ) : hasLoadError ? (
        <div className="timeline-error-state">
          <p>时间线暂时无法加载。</p>
          <span>请稍后重试，已保存的瞬间不会丢失。</span>
          <button className="secondary-action" onClick={() => setRetryKey((value) => value + 1)} type="button">
            重新加载时间线
          </button>
        </div>
      ) : moments.length === 0 ? (
        <div className="empty-state">
          <p>还没有共同瞬间。</p>
          <span>先保存一张照片或一句话，这里会按时间倒序展示。</span>
          <div className="empty-state-steps" aria-label="时间线空态下一步">
            <span className="empty-state-steps-label">下一步</span>
            <span className="empty-state-step">添加照片或一句话</span>
            <span className="empty-state-step">保存后自动出现在时间线</span>
          </div>
          <div className="empty-state-actions">
            <a className="empty-state-action" href="#moment-composer">
              记录第一个瞬间
            </a>
          </div>
        </div>
      ) : (
        <>
          <div className="timeline-summary" aria-label="时间线概况">
            <span>{moments.length} 条瞬间</span>
            <span>{respondedCount} 条已回应</span>
            <span>{favoriteCount} 条珍藏</span>
            <span>{latestMomentMeta ? `最新 ${latestMomentMeta.dateLabel}` : '暂无最新记录'}</span>
          </div>
          <div className="timeline">
            {moments.map((moment, index) => {
              const meta = getMomentDisplayMeta(moment);
              const monthLabel = getMomentMonthLabel(moment);
              const shouldShowMonthDivider = index === 0 || getMomentMonthLabel(moments[index - 1]) !== monthLabel;
              const photoUrl = moment.mediaUrls[0] ? signedUrlByPath[moment.mediaUrls[0]] : '';
              const momentContextLabel = buildMomentContextLabel(meta);
              const pendingResponse = pendingResponseByMomentId[moment.id];

              return (
                <Fragment key={moment.id}>
                  {shouldShowMonthDivider && (
                    <div className="timeline-month-divider">
                      <h3>{monthLabel}</h3>
                    </div>
                  )}
                  <article className="moment">
                    <span className="timeline-marker" aria-hidden="true" />
                    <div className="moment-body">
                      <div className="moment-head">
                        <div className="moment-title">
                          <time>{meta.dateLabel}</time>
                          <p className="moment-location">{meta.locationLabel}</p>
                        </div>
                        <div className="moment-badges">
                          {moment.isFavorite && <span className="favorite-chip">珍藏</span>}
                          <span className={`mood-chip mood-${moment.mood}`}>{meta.moodLabel}</span>
                        </div>
                      </div>
                      {photoUrl && (
                        <figure className="moment-media">
                          <img className="moment-photo" src={photoUrl} alt={buildMomentPhotoAlt(meta)} />
                          {moment.mediaUrls.length > 1 && (
                            <figcaption className="media-count">{moment.mediaUrls.length} 张照片</figcaption>
                          )}
                        </figure>
                      )}
                      <div className="moment-copy">
                        {moment.text && <p>{moment.text}</p>}
                        {moment.partnerText && <p className="partner-text">{moment.partnerText}</p>}
                      </div>
                      <div className="response-meta">
                        <span className={`response-state response-state-${moment.response ? 'success' : 'pending'}`}>
                          {meta.responseLabel}
                        </span>
                        {moment.response && (
                          <span className="response-confirmation">{`你的回应：${responseLabels[moment.response]}`}</span>
                        )}
                        <div className="response-row">
                          {(['like', 'hug', 'miss_you'] as const).map((value) => {
                            const isPendingResponse = pendingResponse === value;
                            const responseLabel = responseLabels[value];

                            return (
                              <button
                                aria-busy={isPendingResponse}
                                aria-label={
                                  isPendingResponse
                                    ? `正在用${responseLabel}回应 ${momentContextLabel}`
                                    : `用${responseLabel}回应 ${momentContextLabel}`
                                }
                                aria-pressed={moment.response === value}
                                className="response-button"
                                disabled={Boolean(pendingResponse)}
                                key={value}
                                onClick={() => respond(moment.id, value)}
                                type="button"
                              >
                                {isPendingResponse ? '回应中...' : responseLabel}
                              </button>
                            );
                          })}
                        </div>
                      </div>
                    </div>
                  </article>
                </Fragment>
              );
            })}
          </div>
        </>
      )}
    </section>
  );
}
