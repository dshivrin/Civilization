'use strict';
(async function () {
  const data = window.VILLAGER_ATLAS;
  const byId = id => document.getElementById(id);
  const controls = Object.fromEntries(['direction','activity','background','scale','guides','play','next','rate','static','frame','frameNumber','status'].map(id => [id, byId(id)]));
  if (!data || data.runtimeIntegrated || data.registrationCertified) {
    byId('qualitySummary').textContent = 'Review data is missing or has unexpected acceptance flags.';
    return;
  }
  const motion = matchMedia('(prefers-reduced-motion: reduce)');
  let frame = 0, wantsPlayback = false, request = null, previousTick = null;
  const paneList = [], images = [];
  const maxWidth = Math.max(...data.assets.flatMap(a => a.cells.map(c => c.rect[2])));
  const maxHeight = Math.max(...data.assets.flatMap(a => a.cells.map(c => c.rect[3])));
  for (const [index, asset] of data.assets.entries()) {
    const card = document.createElement('article'); card.className = 'card';
    const head = document.createElement('div'); head.className = 'card-head';
    const title = document.createElement('h3'); title.textContent = index === 0 ? 'Initial sheet' : 'Padding correction';
    const badge = document.createElement('div'); badge.className = 'badge';
    badge.textContent = asset.gridSafetyPassed ? 'Grid margins pass · art acceptance pending' : 'Grid margins need work · no runtime export';
    head.append(title, badge);
    const stage = document.createElement('div'); stage.className = 'stage';
    const canvas = document.createElement('canvas'); canvas.width = 400; canvas.height = 400;
    canvas.setAttribute('aria-label', title.textContent + ' selected original sprite cell');
    stage.append(canvas); const stats = document.createElement('div'); stats.className = 'stats';
    card.append(head, stage, stats); byId('viewers').append(card);
    const image = new Image();
    const loaded = new Promise((resolve, reject) => { image.onload = () => resolve(image); image.onerror = () => reject(new Error('Failed to decode '+asset.file)); });
    image.src = asset.file; images.push(loaded); paneList.push({asset, canvas, stage, stats, image});
    const figure = document.createElement('figure'), raw = document.createElement('img'), caption = document.createElement('figcaption');
    raw.src = asset.file; raw.alt = title.textContent + ', all 32 original cutouts on transparent alpha'; raw.loading = 'lazy';
    caption.textContent = `${title.textContent} · ${asset.width}×${asset.height} · ${asset.gutterPixels.toLocaleString()} covered gutter pixels at alpha>32`;
    figure.append(raw, caption); byId('rawSheets').append(figure);
  }
  byId('oldConcept').src = data.originalConcept;
  byId('qualitySummary').textContent = `The correction reduces covered gutter pixels from ${data.assets[0].gutterPixels.toLocaleString()} to ${data.assets[1].gutterPixels.toLocaleString()}. Both sheets still fail the proposed margin check. Root contact, camera and gait need review.`;
  const allowed = () => wantsPlayback && !controls.static.checked && !motion.matches && !document.hidden;
  function paint() {
    controls.status.setAttribute('aria-live', allowed() ? 'off' : 'polite');
    const scale = Number(controls.scale.value);
    const originX = (400-maxWidth*scale)/2, originY = (400-maxHeight*scale)/2;
    for (const pane of paneList) {
      const loop = pane.asset.loops.find(l => l.direction === controls.direction.value && l.state === controls.activity.value);
      const cell = pane.asset.cells[loop.frames[frame]], [x,y,w,h] = cell.rect;
      const ctx = pane.canvas.getContext('2d'); ctx.clearRect(0,0,400,400);
      // Same origin and scale across every candidate/frame: no silhouette-based alignment.
      ctx.drawImage(pane.image, x,y,w,h, originX,originY,w*scale,h*scale);
      pane.stage.className = 'stage ' + (controls.background.value === 'gray' ? '' : controls.background.value);
      if (controls.guides.checked) {
        const rootX = originX+w*data.proposedRootNormalized[0]*scale, rootY = originY+h*data.proposedRootNormalized[1]*scale;
        ctx.lineWidth = 1.5; ctx.strokeStyle = '#00aeb8'; ctx.beginPath();
        ctx.moveTo(originX,rootY); ctx.lineTo(originX+w*scale,rootY);
        ctx.moveTo(rootX,rootY-9); ctx.lineTo(rootX,rootY+9); ctx.stroke();
        ctx.strokeStyle = '#ef8500';
        if (cell.bounds) { const [a,b,c,d] = cell.bounds; ctx.strokeRect(originX+a*scale,originY+b*scale,(c-a+1)*scale,(d-b+1)*scale); }
        ctx.strokeStyle = '#52655f'; ctx.setLineDash([4,4]);
        const gutter = cell.gutterWidth*scale; ctx.strokeRect(originX+gutter,originY+gutter,w*scale-2*gutter,h*scale-2*gutter); ctx.setLineDash([]);
      }
      pane.canvas.dataset.cell = String(cell.index);
      pane.stats.textContent = `Cell ${cell.index+1} · ${cell.coveredPixels.toLocaleString()} covered pixels · ${cell.gutterPixels} in gutter. ${cell.bounds ? 'Original UV rectangle, fixed scale.' : 'Empty at alpha>32; no substitute frame.'}`;
    }
    controls.frame.value = String(frame); controls.frameNumber.textContent = `${frame+1} / 4`;
    controls.status.textContent = `${controls.direction.selectedOptions[0].textContent} · ${controls.activity.selectedOptions[0].textContent} · frame ${frame+1}/4 · ${allowed() ? 'Playing' : document.hidden ? 'Paused: hidden tab' : motion.matches ? 'Static: motion preference' : controls.static.checked ? 'Static' : 'Paused'}`;
  }
  function tick(now) {
    request = null;
    if (!allowed()) { previousTick = null; return; }
    if (previousTick === null) previousTick = now;
    if (now-previousTick >= 1000/Number(controls.rate.value)) {
      frame = (frame+1)%4; previousTick = now; paint();
    }
    request = requestAnimationFrame(tick);
  }
  function schedule() {
    if (request !== null) cancelAnimationFrame(request);
    request = null; previousTick = null;
    controls.play.disabled = controls.static.checked || motion.matches;
    controls.play.textContent = wantsPlayback ? 'Pause' : 'Play';
    paint(); if (allowed()) request = requestAnimationFrame(tick);
  }
  try { await Promise.all(images); }
  catch (error) { controls.status.textContent = error.message; controls.status.className = 'load-error'; return; }
  controls.next.disabled = false;
  for (const key of ['direction','activity']) controls[key].addEventListener('change', () => { frame=0; schedule(); });
  for (const key of ['background','scale','guides']) controls[key].addEventListener('change', paint);
  controls.rate.addEventListener('change', schedule);
  controls.static.addEventListener('change', schedule);
  controls.play.addEventListener('click', () => { wantsPlayback = !wantsPlayback; schedule(); });
  controls.next.addEventListener('click', () => { wantsPlayback=false; frame=(frame+1)%4; schedule(); });
  controls.frame.addEventListener('input', () => { wantsPlayback=false; frame=Number(controls.frame.value); schedule(); });
  document.addEventListener('visibilitychange', schedule);
  motion.addEventListener('change', schedule);
  window.addEventListener('pagehide', () => { wantsPlayback=false; if(request !== null) cancelAnimationFrame(request); request=null; previousTick=null; });
  window.addEventListener('pageshow', schedule);
  schedule(); document.body.dataset.reviewReady = 'true';
})();
