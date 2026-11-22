const data = window.eventMotionCards;
const deck = document.getElementById('deck');
document.getElementById('title').textContent = data.title;
document.getElementById('subtitle').textContent = data.subtitle;
const status = document.getElementById('status');

const cards = data.cards.map((entry) => {
  const element = document.createElement('article');
  element.className = 'card';
  element.style.setProperty('--accent', entry.color);
  const heading = document.createElement('h2');
  heading.textContent = entry.title;
  const caption = document.createElement('p');
  caption.textContent = entry.caption;
  const canvas = document.createElement('canvas');
  element.append(heading, caption, canvas);
  deck.append(element);
  return { entry, element, heading, caption, canvas };
});

const clamp = (value) => Math.min(1, Math.max(0, value));
const mix = (a, b, t) => a + (b - a) * t;
const between = (a, b, t) => a.map((value, index) => mix(value, b[index], t));

const timeline = gsap.timeline({ paused: true, defaults: { ease: 'power2.out' } });
const layout = { mosaic: 0 };
timeline.to(layout, { mosaic: 1, duration: 0.620 }, data.mosaicMs / 1000);
for (const [index, card] of cards.entries()) {
  card.motion = { entered: 0, dock: 0, drawing: 0 };
  const start = card.entry.atMs / 1000;
  timeline.to(card.motion, { entered: 1, duration: 0.420 }, start);
  timeline.to(card.motion, { drawing: 1, duration: 0.790 }, start);
  if (index + 1 < cards.length) {
    timeline.to(card.motion, { dock: 1, duration: 0.480 }, cards[index + 1].entry.atMs / 1000);
  }
}

function draw(canvas, id, color, progress) {
  const width = Math.round(canvas.clientWidth);
  const height = Math.round(canvas.clientHeight);
  if (!width || !height) return;
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  ctx.strokeStyle = ctx.fillStyle = color;
  ctx.lineCap = 'round';
  ctx.lineWidth = Math.min(5, Math.max(1, height * 0.05));
  const dot = (x, y, radius) => {
    ctx.beginPath();
    ctx.arc(x * width, y * height, radius, 0, 2 * Math.PI);
    ctx.fill();
  };
  const line = (x1, y1, x2, y2) => {
    ctx.beginPath();
    ctx.moveTo(x1 * width, y1 * height);
    ctx.lineTo(x2 * width, y2 * height);
    ctx.stroke();
  };
  if (id === 'outline') {
    for (const [index, length] of [0.58, 0.44, 0.52].entries()) {
      const y = 0.29 + index * 0.21;
      dot(0.18, y, ctx.lineWidth / 2);
      line(0.26, y, 0.26 + length * progress, y);
    }
  } else if (id === 'layout') {
    for (let index = 0; index < 4; index++) {
      ctx.globalAlpha = progress * (0.92 - 0.17 * index);
      const x = 0.21 + (index % 2) * 0.31;
      const y = 0.22 + Math.floor(index / 2) * 0.33;
      ctx.fillRect(x * width, y * height, 0.26 * width, 0.25 * height);
    }
    ctx.globalAlpha = 1;
  } else if (id === 'motion') {
    ctx.beginPath();
    ctx.moveTo(0.19 * width, 0.68 * height);
    ctx.bezierCurveTo(0.48 * width, 0.68 * height, 0.54 * width, 0.32 * height, 0.82 * width, 0.32 * height);
    ctx.stroke();
    const t = progress;
    const s = 1 - t;
    dot(s ** 3 * 0.19 + 3 * s ** 2 * t * 0.48 + 3 * s * t ** 2 * 0.54 + t ** 3 * 0.82,
      s ** 3 * 0.68 + 3 * s ** 2 * t * 0.68 + 3 * s * t ** 2 * 0.32 + t ** 3 * 0.32, ctx.lineWidth * 1.45);
  } else {
    ctx.strokeRect(0.25 * width, 0.2 * height, 0.5 * width, 0.58 * height);
    line(0.31, 0.67, 0.31 + 0.38 * progress, 0.67);
    ctx.beginPath();
    ctx.moveTo(0.47 * width, 0.36 * height);
    ctx.lineTo(0.47 * width, 0.54 * height);
    ctx.lineTo(0.56 * width, 0.45 * height);
    ctx.fill();
  }
}

function paintFrame(seconds) {
  const time = seconds * 1000;
  const next = cards.find(({ entry }) => time < entry.atMs);
  const { mosaic } = layout;
  status.textContent = next ? `Up next  ${next.entry.title}` : time >= data.mosaicMs ? 'Draft ready for review' : 'Preparing the final draft';
  for (const [index, card] of cards.entries()) {
    const { entry, element, heading, caption, canvas, motion } = card;
    const { entered, dock, drawing } = motion;
    const focus = [8, 14 + 24 * (1 - entered), 404, 269];
    const rail = [index * 107, 321, 99, 64];
    const slot = [(index % 2) * 216, 8 + Math.floor(index / 2) * 197, 204, 185];
    const [left, top, width, height] = between(between(focus, rail, dock), slot, mosaic);
    const detail = 1 - dock * (1 - mosaic);
    const large = clamp((width - 200) / 200);
    Object.assign(element.style, {
      left: `${left}px`, top: `${top}px`, width: `${width}px`, height: `${height}px`,
      opacity: entered, transform: `rotateY(${0.23 * (1 - entered)}rad)`,
      padding: `${mix(8, 19, detail)}px`, borderRadius: `${mix(9, 16, detail)}px`,
      boxShadow: `0 6px 16px rgba(32,44,47,${0.10 * detail})`,
    });
    heading.style.fontSize = `${mix(12, mix(21, 32, large), detail)}px`;
    caption.style.fontSize = `${mix(14, 16, large)}px`;
    caption.hidden = detail <= 0.6;
    draw(canvas, entry.id, entry.color, drawing);
  }
}

window.addEventListener('hf-seek', (event) => paintFrame(event.detail.time));
paintFrame(0);
window.__timelines = window.__timelines || {};
window.__timelines.cards = timeline;
