import { render, screen, within } from '@testing-library/react';
import { describe, expect, it } from 'vitest';
import { MemoryPreview } from './MemoryPreview';

describe('MemoryPreview', () => {
  it('renders a semantic preview of the memory workflow', () => {
    render(<MemoryPreview />);

    expect(screen.getByLabelText('记忆预览')).toBeTruthy();
    const flow = within(screen.getByLabelText('记录流程'));
    expect(flow.getByText('照片')).toBeTruthy();
    expect(flow.getByText('一句话')).toBeTruthy();
    expect(flow.getByText('回应')).toBeTruthy();
  });

  it('shows compact live-state cues in the hero preview', () => {
    render(<MemoryPreview />);

    const state = within(screen.getByLabelText('预览状态'));
    expect(state.getByText('今日新记录')).toBeTruthy();
    expect(state.getByText('等待回应')).toBeTruthy();
    expect(state.getByText('双端同步')).toBeTruthy();
  });
});
