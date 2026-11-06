const R = 6371008.8, RAD = Math.PI / 180;
export function toCoordinates([x, y], center, span = 500) {
  return { lat: center.lat + (260 - y) * span / 800 / R / RAD, lon: center.lon + (x - 400) * span / 800 / R / RAD / Math.cos(center.lat * RAD) };
}
export function toPixel(p, center, span = 500) {
  return [400 + (p.lon - center.lon) * RAD * R * Math.cos(center.lat * RAD) * 800 / span, 260 - (p.lat - center.lat) * RAD * R * 800 / span];
}
export function measureBoundary(points) {
  if (points.length < 3) throw new Error('Add at least three boundary points.');
  if (points.some(p => !Number.isFinite(p.lat) || !Number.isFinite(p.lon) || Math.abs(p.lat) > 85 || Math.abs(p.lon) > 180)) throw new Error('Boundary coordinates are outside the supported map range.');
  const origin = points[0];
  const xy = points.map(p => [(p.lon - origin.lon) * RAD * R * Math.cos(origin.lat * RAD), (p.lat - origin.lat) * RAD * R]);
  const orient = (a,b,c) => (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0]);
  for (let i=0;i<xy.length;i++) for(let j=i+1;j<xy.length;j++) {
    if (j===i+1 || (i===0 && j===xy.length-1)) continue;
    const a=xy[i],b=xy[(i+1)%xy.length],c=xy[j],d=xy[(j+1)%xy.length];
    if (orient(a,b,c)*orient(a,b,d)<0 && orient(c,d,a)*orient(c,d,b)<0) throw new Error('Boundary lines cross. Undo a point or trace again.');
  }
  let twiceArea=0, cx=0, cy=0, perimeter=0;
  xy.forEach((p,i) => { const q=xy[(i+1)%xy.length], cross=p[0]*q[1]-q[0]*p[1]; twiceArea+=cross; cx+=(p[0]+q[0])*cross; cy+=(p[1]+q[1])*cross; perimeter+=Math.hypot(q[0]-p[0],q[1]-p[1]); });
  const sqm=Math.abs(twiceArea)/2;
  if (sqm<100) throw new Error('Trace a field of at least 100 m² (0.01 ha).');
  if (sqm>1000000000) throw new Error('This boundary is too large for the field planner.');
  const center={lat:origin.lat+cy/(3*twiceArea)/R/RAD,lon:origin.lon+cx/(3*twiceArea)/R/RAD/Math.cos(origin.lat*RAD)};
  return {sqm,ha:sqm/10000,acres:sqm/4046.8564224,perimeter,center};
}
