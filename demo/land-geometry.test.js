import {test} from 'node:test';
import assert from 'node:assert/strict';
import {toCoordinates,toPixel,measureBoundary} from './land-geometry.js';
const center={lat:20.3899,lon:78.1307};
const coords=points=>points.map(p=>toCoordinates(p,center));
test('100m square measures one hectare and round-trips coordinates',()=>{
 const p=coords([[320,180],[480,180],[480,340],[320,340]]);
 const m=measureBoundary(p);assert.ok(Math.abs(m.ha-1)<0.00002);assert.ok(Math.abs(m.perimeter-400)<0.01);
 assert.ok(Math.abs(m.center.lat-center.lat)<1e-9);assert.ok(Math.abs(m.center.lon-center.lon)<1e-9);
 const pixel=toPixel(p[0],center);assert.ok(Math.abs(pixel[0]-320)<1e-6);
 assert.ok(Math.abs(measureBoundary(p.slice().reverse()).ha-m.ha)<0.00002);
});
test('irregular concave outline has its actual area rather than bounding-box area',()=>{
 const m=measureBoundary(coords([[100,100],[420,100],[420,260],[260,260],[260,420],[100,420]]));
 assert.ok(Math.abs(m.sqm-30000)<1);assert.ok(m.sqm<40000);
});
test('crossed, tiny, incomplete and invalid boundaries are rejected',()=>{
 assert.throws(()=>measureBoundary(coords([[100,100],[400,400],[100,400],[400,100]])),/cross/);
 assert.throws(()=>measureBoundary(coords([[1,1],[2,1],[2,2]])),/100 m/);
 assert.throws(()=>measureBoundary(coords([[1,1],[2,1]])),/three/);
 assert.throws(()=>measureBoundary([{lat:NaN,lon:0},{lat:0,lon:0},{lat:1,lon:1}]),/coordinates/);
});
