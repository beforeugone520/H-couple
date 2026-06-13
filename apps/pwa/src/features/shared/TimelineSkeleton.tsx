type TimelineSkeletonProps = {
  label?: string;
  rows?: number;
};

export function TimelineSkeleton({ label = '正在加载时间线', rows = 3 }: TimelineSkeletonProps) {
  return (
    <div aria-busy="true" aria-live="polite" className="timeline-skeleton" role="status">
      <span className="sr-only">{label}</span>
      {Array.from({ length: rows }).map((_, index) => (
        <div aria-hidden="true" className="skeleton-row" data-testid="skeleton-row" key={index}>
          <div className="skeleton-media" />
          <div className="skeleton-lines">
            <span className="skeleton-line skeleton-line-short" />
            <span className="skeleton-line" />
            <span className="skeleton-line skeleton-line-mid" />
          </div>
        </div>
      ))}
    </div>
  );
}
