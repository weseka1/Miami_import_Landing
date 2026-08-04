{# ============================================================
   PROBADOR VIRTUAL — botón + modal (solo se incluye si tryon_enabled)
   ============================================================ #}
<button id="mi-tryon-open" type="button"
  style="width:100%;padding:16px;background:rgba(255,255,255,.05);color:#f5f3ee;border:1px solid rgba(198,167,104,.45);
  border-radius:999px;letter-spacing:.18em;text-transform:uppercase;font-size:12px;font-weight:600;cursor:pointer;
  margin-bottom:14px;display:flex;align-items:center;justify-content:center;gap:10px;
  -webkit-backdrop-filter:blur(10px);backdrop-filter:blur(10px)">
  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" aria-hidden="true"><circle cx="12" cy="7" r="3.2"/><path d="M5.5 21v-1.5a5 5 0 0 1 5-5h3a5 5 0 0 1 5 5V21"/><path d="M3.5 3.5 5 5M20.5 3.5 19 5"/></svg>
  Probátelo puesto
</button>

<div id="mi-tryon" hidden style="position:fixed;inset:0;z-index:220;display:flex;align-items:flex-end;justify-content:center">
  <div id="mi-tryon-bg" style="position:absolute;inset:0;background:rgba(5,4,3,.7);-webkit-backdrop-filter:blur(6px);backdrop-filter:blur(6px)"></div>
  <div id="mi-tryon-card" style="position:relative;width:100%;max-width:440px;max-height:94svh;overflow-y:auto;overscroll-behavior:contain;
    background:rgba(20,16,12,.92);-webkit-backdrop-filter:blur(24px) saturate(150%);backdrop-filter:blur(24px) saturate(150%);
    border:1px solid rgba(255,255,255,.09);border-top:1px solid rgba(198,167,104,.4);border-radius:24px 24px 0 0;padding:22px 20px 28px">
    <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px">
      <div style="font-size:12px;letter-spacing:.22em;text-transform:uppercase;color:var(--mi-gold,#c6a768);font-weight:600">Probador virtual</div>
      <button id="mi-tryon-close" type="button" aria-label="Cerrar"
        style="width:38px;height:38px;border-radius:50%;border:1px solid rgba(255,255,255,.15);background:none;color:#f5f3ee;cursor:pointer;font-size:16px">✕</button>
    </div>
    <p style="margin:0 0 16px;font-size:13px;line-height:1.6;color:rgba(242,234,217,.6)">
      Subí una foto tuya de frente (cuerpo visible, buena luz) y te mostramos
      <strong style="color:#f2ead9">{{ product.name }}</strong> puesto.
    </p>

    <div id="mi-tryon-paso1">
      <label style="display:block;border:1.5px dashed rgba(198,167,104,.4);border-radius:18px;padding:26px 16px;text-align:center;cursor:pointer">
        <input id="mi-tryon-file" type="file" accept="image/*" style="display:none"/>
        <div id="mi-tryon-preview-wrap" style="display:none;margin-bottom:12px">
          <img id="mi-tryon-preview" alt="" style="max-height:220px;border-radius:12px;margin:0 auto"/>
        </div>
        <span id="mi-tryon-file-label" style="font-size:13px;letter-spacing:.08em;color:rgba(242,234,217,.75)">Tocá para elegir o sacarte una foto</span>
      </label>
      <button id="mi-tryon-go" type="button" disabled
        style="width:100%;margin-top:14px;padding:16px;background:var(--mi-gold,#c6a768);color:#0b0b0b;border:0;border-radius:999px;
        letter-spacing:.18em;text-transform:uppercase;font-size:12px;font-weight:700;cursor:pointer;opacity:.4">Generar mi look</button>
      <p style="margin:12px 0 0;font-size:11px;color:rgba(242,234,217,.4);text-align:center">Tu foto se usa solo para generar la prueba y no se guarda.</p>
    </div>

    <div id="mi-tryon-paso2" hidden style="text-align:center;padding:34px 0">
      <div style="font-size:14px;color:#f2ead9;margin-bottom:8px">Generando tu look<span id="mi-tryon-dots">…</span></div>
      <div style="font-size:12px;color:rgba(242,234,217,.5)">Tarda entre 20 y 60 segundos. No cierres esta ventana.</div>
    </div>

    <div id="mi-tryon-paso3" hidden style="text-align:center">
      <img id="mi-tryon-result" alt="Tu look" style="width:100%;border-radius:16px;margin-bottom:14px"/>
      <div style="display:flex;gap:10px;flex-wrap:wrap">
        <a id="mi-tryon-wa" target="_blank" rel="noopener"
          style="flex:1;padding:14px;background:var(--mi-gold,#c6a768);color:#0b0b0b;border-radius:999px;font-size:12px;letter-spacing:.12em;text-transform:uppercase;font-weight:700">Lo quiero — WhatsApp</a>
        <a id="mi-tryon-dl" download="mi-look-miami-import.jpg"
          style="flex:1;padding:14px;border:1px solid rgba(255,255,255,.25);color:#f2ead9;border-radius:999px;font-size:12px;letter-spacing:.12em;text-transform:uppercase;font-weight:600">Descargar</a>
      </div>
      <button id="mi-tryon-again" type="button" style="margin-top:12px;background:none;border:0;color:rgba(242,234,217,.55);font-size:12px;letter-spacing:.08em;cursor:pointer;text-decoration:underline">Probar con otra foto</button>
    </div>
    <div id="mi-tryon-err" style="min-height:18px;margin-top:10px;font-size:12.5px;color:#ff9b7a;text-align:center"></div>
  </div>
</div>

<style>
  @media(min-width:641px){
    #mi-tryon{align-items:center}
    #mi-tryon-card{border-radius:24px;max-height:88vh}
  }
  @media(prefers-reduced-motion:no-preference){
    #mi-tryon-card{animation:mi-tryon-in .35s cubic-bezier(.16,1,.3,1)}
    @keyframes mi-tryon-in{from{transform:translateY(26px);opacity:0}to{transform:none;opacity:1}}
  }
</style>

<script nonce="{{ csp_nonce }}">
(function(){
  var $=function(id){return document.getElementById(id)};
  var modal=$('mi-tryon'),file=$('mi-tryon-file'),go=$('mi-tryon-go'),err=$('mi-tryon-err');
  var pasos=[$('mi-tryon-paso1'),$('mi-tryon-paso2'),$('mi-tryon-paso3')];
  var elegido=null, dotsTimer=null;
  function paso(n){ pasos.forEach(function(p,i){ p.hidden=(i!==n-1); }); err.textContent=''; }
  function abrir(){ modal.hidden=false; document.body.style.overflow='hidden'; }
  function cerrar(){ modal.hidden=true; document.body.style.overflow=''; if(dotsTimer)clearInterval(dotsTimer); }
  $('mi-tryon-open').addEventListener('click',function(){ paso(1); abrir(); });
  $('mi-tryon-close').addEventListener('click',cerrar);
  $('mi-tryon-bg').addEventListener('click',cerrar);
  document.addEventListener('keydown',function(e){ if(e.key==='Escape'&&!modal.hidden)cerrar(); });

  file.addEventListener('change',function(){
    var f=file.files&&file.files[0]; if(!f)return;
    if(f.size>8*1024*1024){ err.textContent='La foto pesa más de 8MB. Elegí otra.'; return; }
    elegido=f;
    var r=new FileReader();
    r.onload=function(){ $('mi-tryon-preview').src=r.result; $('mi-tryon-preview-wrap').style.display='block';
      $('mi-tryon-file-label').textContent='Cambiar foto'; go.disabled=false; go.style.opacity='1'; };
    r.readAsDataURL(f);
  });

  go.addEventListener('click',function(){
    if(!elegido)return;
    paso(2);
    var d=$('mi-tryon-dots'),n=0;
    dotsTimer=setInterval(function(){ n=(n+1)%4; d.textContent='.'.repeat(n)||'…'; },450);
    var fd=new FormData();
    fd.append('person',elegido);
    fd.append('product_id','{{ product.id }}');
    fetch('/api/tryon',{method:'POST',body:fd}).then(function(r){
      return r.json().then(function(j){ return {ok:r.ok,j:j}; });
    }).then(function(res){
      clearInterval(dotsTimer);
      if(!res.ok||!res.j.ok){ paso(1); err.textContent=(res.j&&res.j.detail)||'No pudimos generar la prueba. Probá con otra foto.'; return; }
      $('mi-tryon-result').src=res.j.image_url;
      $('mi-tryon-dl').href=res.j.image_url;
      $('mi-tryon-wa').href='https://wa.me/5491162321391?text='+encodeURIComponent('Hola Diego! Me probé virtualmente "{{ product.name }}" y lo quiero. ¿Está disponible?');
      paso(3);
    }).catch(function(){ clearInterval(dotsTimer); paso(1); err.textContent='Se cortó la conexión. Probá de nuevo.'; });
  });

  $('mi-tryon-again').addEventListener('click',function(){
    elegido=null; file.value=''; $('mi-tryon-preview-wrap').style.display='none';
    $('mi-tryon-file-label').textContent='Tocá para elegir o sacarte una foto';
    go.disabled=true; go.style.opacity='.4'; paso(1);
  });
})();
</script>
