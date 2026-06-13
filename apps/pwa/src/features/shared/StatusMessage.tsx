export type StatusTone = 'neutral' | 'pending' | 'success' | 'error';

type StatusMessageProps = {
  message: string;
  tone?: StatusTone;
};

export function StatusMessage({ message, tone = 'neutral' }: StatusMessageProps) {
  if (!message) {
    return null;
  }

  const isError = tone === 'error';
  const toneLabelByTone: Record<StatusTone, string> = {
    neutral: '提示',
    pending: '处理中',
    success: '已完成',
    error: '需要处理'
  };

  return (
    <p
      aria-live={isError ? 'assertive' : 'polite'}
      className={`status-message status-${tone}`}
      role={isError ? 'alert' : 'status'}
    >
      <span className="status-message-label">{toneLabelByTone[tone]}</span>
      <span>{message}</span>
    </p>
  );
}
