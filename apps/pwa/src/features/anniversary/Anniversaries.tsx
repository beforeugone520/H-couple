import { useEffect, useState } from 'react';
import { supabase } from '../../lib/supabase';
import { StatusMessage } from '../shared/StatusMessage';
import type { Anniversary, AnniversaryRow } from '../moments/momentTypes';
import {
  countdownLabel,
  daysUntilNextAnniversary,
  formatAnniversaryDate,
  normalizeAnniversary
} from './anniversaryService';

type AnniversariesProps = {
  coupleSpaceId: string;
};

export function Anniversaries({ coupleSpaceId }: AnniversariesProps) {
  const [items, setItems] = useState<Anniversary[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [status, setStatus] = useState('');
  const [hasError, setHasError] = useState(false);

  useEffect(() => {
    let isActive = true;

    async function load() {
      setIsLoading(true);
      setStatus('');
      setHasError(false);

      try {
        const { data, error } = await supabase
          .from('anniversaries')
          .select('*')
          .eq('couple_space_id', coupleSpaceId)
          .order('date', { ascending: true });

        if (!isActive) {
          return;
        }

        if (error) {
          setStatus(error.message);
          setHasError(true);
          setItems([]);
          return;
        }

        setItems(((data ?? []) as AnniversaryRow[]).map(normalizeAnniversary));
      } catch (error) {
        if (!isActive) {
          return;
        }

        setStatus(error instanceof Error ? error.message : '加载纪念日失败，请稍后再试。');
        setHasError(true);
        setItems([]);
      } finally {
        if (isActive) {
          setIsLoading(false);
        }
      }
    }

    load();

    return () => {
      isActive = false;
    };
  }, [coupleSpaceId]);

  const today = new Date();

  return (
    <section className="panel anniversary-panel">
      <div className="section-heading">
        <div>
          <p className="eyebrow">温柔提醒</p>
          <h2>纪念日</h2>
        </div>
      </div>
      <StatusMessage message={status} tone="error" />
      {isLoading ? (
        <p className="anniversary-loading" aria-live="polite">
          正在加载纪念日…
        </p>
      ) : hasError ? (
        <p className="anniversary-empty">纪念日暂时无法加载，请稍后再试。</p>
      ) : items.length === 0 ? (
        <p className="anniversary-empty">还没有纪念日。可在 HarmonyOS 端「我们」里添加第一次见面、生日或旅行纪念日。</p>
      ) : (
        <ul className="anniversary-list">
          {items.map((item) => {
            const days = daysUntilNextAnniversary(item.date, today);
            return (
              <li className="anniversary-item" key={item.id}>
                <div className="anniversary-info">
                  <span className="anniversary-title">{item.title}</span>
                  <span className="anniversary-date">{formatAnniversaryDate(item.date)}</span>
                </div>
                <span className="anniversary-countdown">{countdownLabel(days)}</span>
              </li>
            );
          })}
        </ul>
      )}
    </section>
  );
}
