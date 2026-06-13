import { useEffect, useRef, useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { supabase } from '../../lib/supabase';
import { StatusMessage, type StatusTone } from '../shared/StatusMessage';
import { buildMomentInsert, moodLabels } from './momentService';
import type { Mood } from './momentTypes';

type MomentComposerProps = {
  session: Session;
  coupleSpaceId: string;
  onCreated: () => void;
};

const moods: Array<{ value: Mood; label: string }> = [
  { value: 'happy', label: moodLabels.happy },
  { value: 'miss', label: moodLabels.miss },
  { value: 'calm', label: moodLabels.calm },
  { value: 'sad', label: moodLabels.sad },
  { value: 'surprise', label: moodLabels.surprise }
];

function getFileExtension(file: File): string {
  const fallback = file.type === 'image/png' ? 'png' : 'jpg';
  const extension = file.name.split('.').pop();
  return extension ? extension.toLowerCase() : fallback;
}

export function MomentComposer({ session, coupleSpaceId, onCreated }: MomentComposerProps) {
  const fileInputRef = useRef<HTMLInputElement | null>(null);
  const textInputRef = useRef<HTMLTextAreaElement | null>(null);
  const [text, setText] = useState('');
  const [mood, setMood] = useState<Mood>('calm');
  const [locationName, setLocationName] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [photoPreviewUrl, setPhotoPreviewUrl] = useState('');
  const [status, setStatus] = useState('');
  const [statusTone, setStatusTone] = useState<StatusTone>('neutral');
  const [isSaving, setIsSaving] = useState(false);
  const [hasSavedMoment, setHasSavedMoment] = useState(false);
  const canSave = Boolean(text.trim() || file);
  const canSubmit = canSave && !isSaving;
  const hasText = text.trim().length > 0;
  const hasLocation = locationName.trim().length > 0;
  const completenessCount = [Boolean(file), hasText, hasLocation].filter(Boolean).length;
  const completenessPercent = (completenessCount / 3) * 100;
  const saveHint = isSaving
    ? '正在保存这个瞬间...'
    : canSave
      ? '可以保存这个瞬间。'
      : '添加照片或输入一句话后可保存。';
  const filePickerTitle = file ? '已选择照片' : '添加照片';
  const filePickerMeta = file ? `点击可更换：${file.name}` : '支持拍照或从相册选择';
  const draftSummary = [
    file ? '已选照片' : '没有照片',
    `${text.trim().length} 字`,
    moodLabels[mood],
    locationName.trim() || '未记录地点'
  ];
  const draftCompletenessItems = [
    file ? '照片已添加' : '照片待补',
    hasText ? '文字已写' : '文字待写',
    hasLocation ? '地点已填' : '地点待填'
  ];

  useEffect(() => {
    if (!file) {
      setPhotoPreviewUrl('');
      return;
    }

    const nextPreviewUrl = URL.createObjectURL(file);
    setPhotoPreviewUrl(nextPreviewUrl);

    return () => {
      URL.revokeObjectURL(nextPreviewUrl);
    };
  }, [file]);

  async function uploadSelectedFile(): Promise<string[]> {
    if (!file) {
      return [];
    }

    const extension = getFileExtension(file);
    const path = `${coupleSpaceId}/${session.user.id}/${crypto.randomUUID()}.${extension}`;
    const { error } = await supabase.storage.from('moments').upload(path, file, {
      cacheControl: '3600',
      upsert: false
    });

    if (error) {
      throw error;
    }

    return [path];
  }

  async function createMoment() {
    if (!canSubmit) {
      return;
    }

    try {
      setIsSaving(true);
      setHasSavedMoment(false);
      setStatus('正在保存...');
      setStatusTone('pending');
      const mediaUrls = await uploadSelectedFile();
      const payload = buildMomentInsert({
        coupleSpaceId,
        creatorId: session.user.id,
        mediaUrls,
        text,
        mood,
        locationName,
        occurredAt: new Date().toISOString()
      });

      const { error } = await supabase.from('moments').insert(payload);
      if (error) {
        throw error;
      }

      setText('');
      setLocationName('');
      setMood('calm');
      setFile(null);
      setStatus('已保存。');
      setStatusTone('success');
      setHasSavedMoment(true);
      onCreated();
    } catch (error) {
      setStatus(error instanceof Error ? error.message : '保存失败');
      setStatusTone('error');
    } finally {
      setIsSaving(false);
    }
  }

  function clearSelectedFile() {
    setFile(null);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  }

  function continueRecording() {
    setHasSavedMoment(false);
    setStatus('');
    setStatusTone('neutral');
    textInputRef.current?.focus();
  }

  return (
    <section className="panel composer-panel" id="moment-composer">
      <div className="section-heading">
        <p className="eyebrow">新的回忆</p>
        <h2>记录一个瞬间</h2>
      </div>
      <label className="file-picker">
        <span className="file-picker-copy">
          <span className="file-picker-title">{filePickerTitle}</span>
          <span className="file-picker-meta">{filePickerMeta}</span>
        </span>
        {file && photoPreviewUrl && (
          <img className="file-preview-image" src={photoPreviewUrl} alt={`已选择照片预览：${file.name}`} />
        )}
        <input
          ref={fileInputRef}
          aria-label="照片"
          type="file"
          accept="image/*"
          onChange={(event) => setFile(event.target.files?.[0] ?? null)}
        />
      </label>
      {file && (
        <div className="file-actions">
          <button
            aria-label={`移除已选择照片 ${file.name}`}
            className="text-action"
            onClick={clearSelectedFile}
            type="button"
          >
            移除照片
          </button>
        </div>
      )}
      <label className="field">
        <span>一句话</span>
        <textarea
          ref={textInputRef}
          aria-label="一句话"
          value={text}
          onChange={(event) => setText(event.target.value)}
          placeholder="写一句今天想留下的话"
        />
      </label>
      <div className="field">
        <span>心情</span>
        <div className="segmented-control mood-control" role="radiogroup" aria-label="心情">
          {moods.map((item) => (
            <button
              aria-checked={mood === item.value}
              className="segment-button"
              key={item.value}
              onClick={() => setMood(item.value)}
              role="radio"
              type="button"
            >
              {item.label}
            </button>
          ))}
        </div>
      </div>
      <label className="field">
        <span>地点</span>
        <input
          aria-label="地点"
          value={locationName}
          onChange={(event) => setLocationName(event.target.value)}
          placeholder="地点，可不填"
        />
      </label>
      <div className="draft-summary" aria-label="草稿概况">
        <div className="draft-summary-head">
          <span className="draft-summary-label">草稿概况</span>
          <span className="draft-completeness-label">{`记录完整度 ${completenessCount}/3`}</span>
        </div>
        <div
          aria-label="记录完整度"
          aria-valuemax={3}
          aria-valuemin={0}
          aria-valuenow={completenessCount}
          className="draft-progress"
          role="progressbar"
        >
          <span className="draft-progress-bar" style={{ width: `${completenessPercent}%` }} />
        </div>
        <div className="draft-completeness-items">
          {draftCompletenessItems.map((item) => (
            <span className="draft-completeness-item" key={item}>
              {item}
            </span>
          ))}
        </div>
        <div className="draft-summary-items">
          {draftSummary.map((item) => (
            <span className="draft-summary-item" key={item}>
              {item}
            </span>
          ))}
        </div>
      </div>
      <p aria-live="polite" className={`save-hint ${canSave ? 'save-hint-ready' : ''}`} id="moment-save-hint">
        {saveHint}
      </p>
      <button
        aria-busy={isSaving}
        aria-describedby="moment-save-hint"
        className="primary-action"
        onClick={createMoment}
        disabled={!canSubmit}
      >
        {isSaving ? '保存中...' : '保存'}
      </button>
      {hasSavedMoment && (
        <div className="save-next-steps" aria-label="保存后的下一步">
          <span className="save-next-label">已加入时间线</span>
          <div className="save-next-actions">
            <a className="save-next-link" href="#timeline-panel">
              查看时间线
            </a>
            <button className="save-next-button" onClick={continueRecording} type="button">
              继续记录
            </button>
          </div>
        </div>
      )}
      <StatusMessage message={status} tone={statusTone} />
    </section>
  );
}
