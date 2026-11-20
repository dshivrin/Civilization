const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync('docs/art/villager-atlas-review/review.js', 'utf8');

// Run the actual viewer and its registered lifecycle callbacks, without a browser dependency.
async function viewer(code = source) {
  class Element {
    constructor() { this.listeners = {}; this.dataset = {}; this.children = []; this.checked = false; }
    addEventListener(name, fn) { this.listeners[name] = fn; }
    fire(name) { this.listeners[name]?.(); }
    append(...children) { this.children.push(...children); }
    setAttribute() {}
    getContext() { return new Proxy({}, {get: () => () => {}}); }
    get selectedOptions() { return [{textContent: this.value}]; }
  }
  const elements = Object.fromEntries(['direction','activity','background','scale','guides','play','next','rate','static','frame','frameNumber','status','qualitySummary','viewers','rawSheets','oldConcept'].map(id => [id,new Element()]));
  Object.assign(elements.direction,{value:'near-right'}); elements.activity.value='walk';
  elements.scale.value='1.25'; elements.rate.value='4'; elements.background.value='gray';
  const document = Object.assign(new Element(),{hidden:false,body:new Element(),getElementById:id=>elements[id],createElement:()=>new Element()});
  const motion = Object.assign(new Element(),{matches:false});
  const data = JSON.parse(fs.readFileSync('docs/art/villager-atlas-review/gallery-data.js','utf8').replace(/^window.VILLAGER_ATLAS\s*=\s*/, '').replace(/;\s*$/, ''));
  const window = Object.assign(new Element(),{VILLAGER_ATLAS:data});
  const callbacks = new Map(); let nextId=0;
  class Image { set src(value) { this.url=value; queueMicrotask(()=>this.onload()); } }
  await vm.runInNewContext(code,{window,document,Image,matchMedia:()=>motion,requestAnimationFrame:fn=>{callbacks.set(++nextId,fn);return nextId;},cancelAnimationFrame:id=>callbacks.delete(id)});
  assert.equal(document.body.dataset.reviewReady,'true');
  const canvas = elements.viewers.children[0].children[1].children[0];
  const advance = time => { const current=[...callbacks.values()]; callbacks.clear(); current.forEach(fn=>fn(time)); };
  return {elements,document,motion,window,callbacks,advance,cell:()=>canvas.dataset.cell};
}

async function verifySuspension(code) {
  const v=await viewer(code);
  assert.equal(v.callbacks.size,0,'starts paused');
  v.elements.play.fire('click'); v.advance(0); v.advance(250);
  assert.equal(v.cell(),'1','actual playback advances the raw cell');
  v.document.hidden=true; v.document.fire('visibilitychange');
  assert.equal(v.callbacks.size,0,'hidden page cancels scheduled work');
  v.advance(5000); assert.equal(v.cell(),'1');
  v.document.hidden=false; v.document.fire('visibilitychange');
  v.advance(9000); assert.equal(v.cell(),'1','return starts a new clock without hidden-time catch-up');
  v.advance(9250); assert.equal(v.cell(),'2');
  v.motion.matches=true; v.motion.fire('change');
  assert.equal(v.callbacks.size,0); assert.equal(v.elements.play.disabled,true);
  v.motion.matches=false; v.motion.fire('change');
  v.elements.static.checked=true; v.elements.static.fire('change');
  assert.equal(v.callbacks.size,0); v.advance(12000); assert.equal(v.cell(),'2');
  v.elements.static.checked=false; v.elements.static.fire('change');
  assert.equal(v.callbacks.size,1);
  v.window.fire('pagehide'); assert.equal(v.callbacks.size,0);
  v.window.fire('pageshow'); assert.equal(v.callbacks.size,0,'page restoration stays paused');
}

test('actual viewer suspends for hiding, motion preference, Static and page lifecycle',async()=>verifySuspension(source));
test('negative control catches removal of the hidden-page guard',async()=>{
  const broken=source.replace(' && !document.hidden',''); assert.notEqual(broken,source);
  await assert.rejects(()=>verifySuspension(broken),/hidden page cancels/);
});
