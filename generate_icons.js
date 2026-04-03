const { createCanvas } = require('canvas');
const fs = require('fs');
const path = require('path');

const S_orig = 180;
const S = 1024;
const scale = S / S_orig;

const GREEN  = '#1DB88A';
const WHITE  = '#F0EDE8';
const DARK   = '#0F1117';
const CARD   = '#1A1F2E';

function sc(v) { return v * scale; }

function rrect(ctx, x, y, w, h, r, fill, stroke, sw) {
  x = sc(x); y = sc(y); w = sc(w); h = sc(h); r = sc(r);
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.arcTo(x + w, y, x + w, y + r, r);
  ctx.lineTo(x + w, y + h - r);
  ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
  ctx.lineTo(x + r, y + h);
  ctx.arcTo(x, y + h, x, y + h - r, r);
  ctx.lineTo(x, y + r);
  ctx.arcTo(x, y, x + r, y, r);
  ctx.closePath();
  if (fill)   { ctx.fillStyle = fill; ctx.fill(); }
  if (stroke) { ctx.strokeStyle = stroke; ctx.lineWidth = sc(sw || 1); ctx.stroke(); }
}

// ── Opção C: Check circle ─────────────────────────────────────────────────────
function drawOptionC() {
  const canvas = createCanvas(S, S);
  const ctx = canvas.getContext('2d');

  // dark bg
  rrect(ctx, 0, 0, S_orig, S_orig, 36, '#0D1525');

  // green circle
  ctx.fillStyle = GREEN;
  ctx.beginPath();
  ctx.arc(sc(S_orig / 2), sc(S_orig / 2 - 8), sc(62), 0, Math.PI * 2);
  ctx.fill();

  // checkmark
  ctx.strokeStyle = WHITE;
  ctx.lineWidth = sc(12);
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.beginPath();
  ctx.moveTo(sc(S_orig / 2 - 28), sc(S_orig / 2 - 8));
  ctx.lineTo(sc(S_orig / 2 - 6),  sc(S_orig / 2 + 16));
  ctx.lineTo(sc(S_orig / 2 + 34), sc(S_orig / 2 - 28));
  ctx.stroke();

  // "ReciboPro" text below
  ctx.fillStyle = GREEN;
  ctx.font = `700 ${sc(16)}px sans-serif`;
  ctx.textAlign = 'center';
  ctx.fillText('ReciboPro', sc(S_orig / 2), sc(S_orig - 22));

  return canvas;
}

// ── Opção G: Doc card escuro ──────────────────────────────────────────────────
function drawOptionG() {
  const canvas = createCanvas(S, S);
  const ctx = canvas.getContext('2d');

  // bg
  rrect(ctx, 0, 0, S_orig, S_orig, 36, '#0D1525');

  // doc body
  rrect(ctx, 42, 20, 96, 120, 14, CARD);

  // folded corner (dark triangle)
  ctx.fillStyle = '#131928';
  ctx.beginPath();
  ctx.moveTo(sc(115), sc(20));
  ctx.lineTo(sc(138), sc(20));
  ctx.lineTo(sc(138), sc(43));
  ctx.closePath();
  ctx.fill();

  // corner border
  rrect(ctx, 115, 20, 23, 23, 0, null, '#1e2540', 1);

  // green accent bar left
  rrect(ctx, 42, 20, 8, 120, 4, GREEN);

  // lines
  [[58, 44, 62, 9], [58, 59, 72, 9], [58, 74, 52, 9], [58, 89, 68, 9], [58, 104, 44, 9]].forEach(
    ([x, y, w, h]) => rrect(ctx, x, y, w, h, 5, '#2a3050')
  );

  // bottom text
  ctx.fillStyle = GREEN;
  ctx.font = `700 ${sc(13)}px sans-serif`;
  ctx.textAlign = 'center';
  ctx.fillText('ReciboPro', sc(S_orig / 2), sc(158));

  return canvas;
}

// ── Save ──────────────────────────────────────────────────────────────────────
const outDir = path.join(__dirname, 'assets', 'icons');
fs.mkdirSync(outDir, { recursive: true });

const cCanvas = drawOptionC();
fs.writeFileSync(path.join(outDir, 'icon_opcao_c.png'), cCanvas.toBuffer('image/png'));
console.log('✓ icon_opcao_c.png salvo em assets/icons/');

const gCanvas = drawOptionG();
fs.writeFileSync(path.join(outDir, 'icon_opcao_g.png'), gCanvas.toBuffer('image/png'));
console.log('✓ icon_opcao_g.png salvo em assets/icons/');
