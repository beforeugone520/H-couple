const previewSteps = ['照片', '一句话', '回应'];
const previewStates = ['今日新记录', '等待回应', '双端同步'];

export function MemoryPreview() {
  return (
    <aside className="memory-preview" aria-label="记忆预览">
      <div className="preview-surface">
        <div className="preview-photo" aria-hidden="true">
          <span>照片</span>
        </div>
        <div className="preview-note">
          <time>2026.06.08</time>
          <p>晚风很好，适合一起慢慢走。</p>
          <span>已回应：抱抱</span>
        </div>
      </div>
      <ol className="preview-steps" aria-label="记录流程">
        {previewSteps.map((step) => (
          <li key={step}>{step}</li>
        ))}
      </ol>
      <div className="preview-state-rail" aria-label="预览状态">
        {previewStates.map((state) => (
          <span className="preview-state-item" key={state}>
            {state}
          </span>
        ))}
      </div>
    </aside>
  );
}
