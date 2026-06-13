import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { describe, expect, it } from 'vitest';

const styles = readFileSync(join(process.cwd(), 'src/styles.css'), 'utf8');

describe('styles', () => {
  it('defines dark-mode and reduced-motion contracts', () => {
    expect(styles).toContain('@media (prefers-color-scheme: dark)');
    expect(styles).toContain('--dark-bg:');
    expect(styles).toContain('--dark-surface:');
    expect(styles).toContain('--dark-ink:');
    expect(styles).toContain('@media (prefers-reduced-motion: reduce)');
  });

  it('keeps the mobile mood picker compact and touch-friendly', () => {
    expect(styles).toContain('.mood-control');
    expect(styles).toContain('grid-template-columns: repeat(2, minmax(0, 1fr));');
    expect(styles).toContain('.mood-control .segment-button');
    expect(styles).toContain('min-height: 44px;');
    expect(styles).not.toContain(`.join-row,
  .segmented-control {
    grid-template-columns: 1fr;
  }`);
  });

  it('keeps timeline response actions touch-friendly', () => {
    expect(styles).toContain('.response-row');
    expect(styles).toContain('gap: 8px;');
    expect(styles).toContain('.response-button');
    expect(styles).toContain('min-height: 44px;');
    expect(styles).toContain('touch-action: manipulation;');
    expect(styles).toContain('.response-button:hover:not(:disabled)');
    expect(styles).toContain('.response-button[aria-busy="true"]');
    expect(styles).toContain('opacity: 1;');
    expect(styles).not.toContain(`.response-button {
  min-height: 36px;`);
  });

  it('keeps pending primary actions readable while disabled', () => {
    expect(styles).toContain('.primary-action[aria-busy="true"]');
    expect(styles).toContain('opacity: 1;');
  });

  it('keeps async status messages labeled and compact', () => {
    expect(styles).toContain('.status-message');
    expect(styles).toContain('.status-message-label');
    expect(styles).toContain('display: flex;');
    expect(styles).toContain('width: fit-content;');
    expect(styles).toContain(`.status-message span:last-child {
  min-width: 0;
  overflow-wrap: anywhere;
}`);
  });

  it('keeps pending secondary actions readable while disabled', () => {
    expect(styles).toContain('.secondary-action[aria-busy="true"]');
    expect(styles).toContain('opacity: 1;');
  });

  it('styles invite-code helper text without adding layout noise', () => {
    expect(styles).toContain('.field-helper');
    expect(styles).toContain('.code-input');
    expect(styles).toContain('.email-readiness');
    expect(styles).toContain('.email-readiness-ready');
    expect(styles).toContain('.invite-readiness');
    expect(styles).toContain('.invite-readiness-ready');
    expect(styles).toContain('flex-wrap: wrap;');
    expect(styles).toContain('overflow-wrap: anywhere;');
    expect(styles).toContain(`.email-readiness,
  .invite-readiness {
    align-items: flex-start;
  }`);
    expect(styles).toContain('text-transform: uppercase;');
  });

  it('styles magic-link next steps as a compact success rail', () => {
    expect(styles).toContain('.auth-next-steps');
    expect(styles).toContain('.auth-next-label');
    expect(styles).toContain('counter-reset: auth-step;');
    expect(styles).toContain('.auth-next-steps li::before');
    expect(styles).toContain('grid-template-columns: repeat(3, minmax(0, 1fr));');
    expect(styles).toContain(`.auth-next-steps ol {
    grid-template-columns: 1fr;
  }`);
  });

  it('styles draft completeness as a compact progress cue', () => {
    expect(styles).toContain('.draft-summary-head');
    expect(styles).toContain('.draft-progress');
    expect(styles).toContain('.draft-progress-bar');
    expect(styles).toContain('.draft-completeness-items');
  });

  it('styles post-save next actions without adding a card layer', () => {
    expect(styles).toContain('.save-next-steps');
    expect(styles).toContain('.save-next-label');
    expect(styles).toContain('.save-next-actions');
    expect(styles).toContain('.save-next-link');
    expect(styles).toContain('.save-next-button');
    expect(styles).toContain(`.save-next-link,
.save-next-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 44px;`);
    expect(styles).toContain('.save-next-link:focus-visible');
    expect(styles).toContain('background: var(--status-success-bg);');
  });

  it('keeps custom clickable surfaces keyboard-visible', () => {
    expect(styles).toContain('.file-picker:has(input:focus-visible)');
    expect(styles).toContain('.save-next-link:focus-visible');
    expect(styles).toContain('.workspace-link:focus-visible');
    expect(styles).toContain('.empty-state-action:focus-visible');
    expect(styles).toContain('cursor: pointer;');
  });

  it('keeps compact composer actions touch-friendly on mobile', () => {
    expect(styles).toContain('.text-action');
    expect(styles).toContain(`.text-action {
    width: 100%;
    min-height: 44px;
  }`);
    expect(styles).not.toContain(`.text-action {
    width: 100%;
    min-height: 40px;
  }`);
  });

  it('gives dense segmented actions local hover feedback', () => {
    expect(styles).toContain('.segment-button:hover:not([aria-checked="true"])');
    expect(styles).toContain('.response-button:hover:not(:disabled)');
    expect(styles).toContain('background: rgb(180 35 95 / 8%);');
    expect(styles).toContain('box-shadow: 0 8px 18px rgb(79 63 53 / 10%);');
  });

  it('styles timeline response status chips with semantic tones', () => {
    expect(styles).toContain('.response-state');
    expect(styles).toContain('.response-state-pending');
    expect(styles).toContain('.response-state-success');
    expect(styles).toContain('.response-confirmation');
    expect(styles).toContain('background: var(--status-pending-bg);');
    expect(styles).toContain('background: var(--status-success-bg);');
  });

  it('keeps timeline favorite markers compact beside mood chips', () => {
    expect(styles).toContain('.moment-head');
    expect(styles).toContain(`.moment-head {
  display: flex;
  flex-wrap: wrap;`);
    expect(styles).toContain('.moment-title');
    expect(styles).toContain(`.moment-title {
  min-width: min(100%, 12rem);`);
    expect(styles).toContain('.moment-badges');
    expect(styles).toContain('.favorite-chip');
    expect(styles).toContain(`.moment-badges {
  display: flex;
  flex: 1 1 9rem;`);
    expect(styles).toContain('color: var(--status-pending-ink);');
    expect(styles).toContain('background: var(--status-pending-bg);');
    expect(styles).not.toContain('max-width: 52%;');
  });

  it('styles timeline month dividers without adding another card layer', () => {
    expect(styles).toContain('.timeline-month-divider');
    expect(styles).toContain('.timeline-month-divider h3');
    expect(styles).toContain('grid-column: 1 / -1;');
  });

  it('styles timeline loading errors separately from empty states', () => {
    expect(styles).toContain('.timeline-heading');
    expect(styles).toContain(`.timeline-heading {
  display: flex;
  flex-wrap: wrap;`);
    expect(styles).toContain('.timeline-error-state');
    expect(styles).toContain('.timeline-error-state .secondary-action');
    expect(styles).toContain('.count-pill-error');
    expect(styles).toContain('background: var(--status-error-bg);');
  });

  it('styles empty-state next steps without making a nested card', () => {
    expect(styles).toContain('.empty-state-steps');
    expect(styles).toContain('.empty-state-step');
    expect(styles).toContain('grid-template-columns: repeat(2, minmax(0, 1fr));');
    expect(styles).toContain('.empty-state-steps-label');
    expect(styles).toContain(`.empty-state-steps {
    grid-template-columns: 1fr;
  }`);
  });

  it('keeps hero preview state cues compact and responsive', () => {
    expect(styles).toContain('.preview-state-rail');
    expect(styles).toContain('.preview-state-item');
    expect(styles).toContain('grid-template-columns: repeat(3, minmax(0, 1fr));');
    expect(styles).toContain('@media (max-width: 520px)');
    expect(styles).toContain('.preview-state-rail');
  });

  it('keeps the connected workspace header scan-friendly', () => {
    expect(styles).toContain('.workspace-header');
    expect(styles).toContain('.workspace-invite');
    expect(styles).toContain('.workspace-invite-actions');
    expect(styles).toContain('.workspace-copy-button');
    expect(styles).toContain('.workspace-copy-status');
    expect(styles).toContain('.workspace-copy-status-success');
    expect(styles).toContain('.workspace-copy-status-error');
    expect(styles).toContain('.workspace-invite strong');
    expect(styles).toContain('.workspace-status');
    expect(styles).toContain('.workspace-status-item');
    expect(styles).toContain('.workspace-actions');
    expect(styles).toContain('.workspace-link');
    expect(styles).toContain('.workspace-link-primary');
    expect(styles).toContain('.workspace-link-secondary');
    expect(styles).toContain('letter-spacing: 0.08em;');
    expect(styles).toContain(`.workspace-invite {
    justify-items: start;
    width: 100%;
  }`);
    expect(styles).toContain(`.workspace-invite-actions {
    justify-content: flex-start;
  }`);
    expect(styles).toContain('grid-column: 1 / -1;');
  });
});
