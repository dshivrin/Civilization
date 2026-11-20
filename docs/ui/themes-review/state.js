/* Review-only state machine. Storage adapter is injected; never reads player saves. */
(function(root){
'use strict';
function empty(){return {schema:1,events:[],viewed:[],eraCommitted:[],theme:"stone-temperate",construction:{}};}
function valid(s){return s&&s.schema===1&&Array.isArray(s.events)&&Array.isArray(s.viewed)&&Array.isArray(s.eraCommitted);}
function create(storage,key='civilization-ui-review-v1',constructionKinds=['hut','storehouse']){
 let state=empty();try{const saved=JSON.parse(storage.getItem(key));if(valid(saved))state={...empty(),...saved};}catch{}
 function commit(next){try{storage.setItem(key,JSON.stringify(next));state=next;return true;}catch{return false;}}
 return {
  snapshot:()=>JSON.parse(JSON.stringify(state)),
  complete(event){if(!['research','goals','achievement'].includes(event.destination)||!event.id||!event.title)return {added:false,reason:'invalid'};if(state.events.some(e=>e.id===event.id))return {added:false,reason:'duplicate'};const next=JSON.parse(JSON.stringify(state));next.events.push({...event});return {added:commit(next),reason:'commit'};},
  unread(destination){return state.events.filter(e=>e.destination===destination&&!state.viewed.includes(e.id));},
  result(id){return state.viewed.includes(id)?state.events.find(e=>e.id===id)||null:null;},
  view(id){if(!state.events.some(e=>e.id===id))return false;const next=JSON.parse(JSON.stringify(state));if(!next.viewed.includes(id))next.viewed.push(id);return commit(next);},
  setConstruction(id,value){if(!constructionKinds.includes(id)||!Number.isFinite(value)||value<0||value>100)return false;const next=JSON.parse(JSON.stringify(state));next.construction[id]=value;return commit(next);},
  era(id,theme="bronze-egypt"){if(state.eraCommitted.includes(id))return false;const next=JSON.parse(JSON.stringify(state));next.eraCommitted.push(id);next.theme=theme;return commit(next);},
  reset(){return commit(empty());}
 };
}
root.UIReviewState={create,empty};if(typeof module!=='undefined')module.exports=root.UIReviewState;
})(typeof window!=='undefined'?window:globalThis);
