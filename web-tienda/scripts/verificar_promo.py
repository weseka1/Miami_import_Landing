#!/usr/bin/env python
"""Verifica que el descuento diga lo mismo en TODAS las pantallas.

🔴 Por qué existe este archivo
------------------------------
`core/promo.py` prometía en su docstring que este verificador existía. No
existía. Durante cinco días la frase "hay un test que lo verifica de punta a
punta" fue lo único que sostenía la confianza en el camino del dinero, y
justamente en esos cinco días `/checkout` estuvo rotulando "Total" al subtotal
SIN descuento y disparando el aviso "el precio se actualizó, revisá antes de
pagar" en el 100% de las compras. Nadie lo vio porque un JS pisaba el número
dos líneas después y la cuenta terminaba bien.

La lección, que es la regla de la casa: **lo que no se mide, se publica.** Un
docstring que promete una red que no existe es peor que no tener red, porque
el próximo que toque la promo —persona o Claude— lee esa línea y asume que
alguien lo está mirando.

Qué comprueba
-------------
  ARITMÉTICA (sin red)   `promo.aplicar()` redondea bien, `ahorro()` cierra,
                         y aplicar dos veces NO da lo mismo que aplicar una
                         (el error simétrico, que es el caro).
  PANTALLAS (con red)    Recorre una compra de verdad contra una URL:
                         ficha → agregar al carrito → /carrito → /checkout,
                         y exige que los cuatro digan el mismo número.

Uso
---
    python scripts/verificar_promo.py                          # solo aritmética
    python scripts/verificar_promo.py --url https://miamiimport.com.ar
    python scripts/verificar_promo.py --url http://127.0.0.1:8001 --handle <handle>

Sale con código 1 si algo no cierra, para poder colgarlo del CI.
"""
from __future__ import annotations

import argparse
import http.cookiejar
import json
import re
import sys
import urllib.error
import urllib.request
from decimal import Decimal
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")   # la consola es cp1252
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core import promo  # noqa: E402

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

FALLAS: list[str] = []
PASOS: list[str] = []


def ok(msg: str) -> None:
    PASOS.append(msg)
    print(f"  OK   {msg}")


def mal(msg: str) -> None:
    FALLAS.append(msg)
    print(f"  FALLA {msg}")


# --------------------------------------------------------------------------- #
# 1. Aritmética — no necesita red ni base
# --------------------------------------------------------------------------- #
def verificar_aritmetica() -> None:
    print("\n== ARITMÉTICA ==")
    pct = promo.porcentaje()
    if not promo.vigente():
        ok("no hay promo vigente; aplicar() debe devolver el precio intacto")
        if promo.aplicar("130.00") != Decimal("130.00"):
            mal("sin promo vigente, aplicar() cambió el precio")
        return

    ok(f"promo vigente al {pct}%")

    for bruto in ("130.00", "300.00", "255.55", "0.01", "1999.99"):
        p = Decimal(bruto)
        neto = promo.aplicar(bruto)
        ahorro = promo.ahorro(bruto)
        if neto is None:
            mal(f"aplicar({bruto}) devolvió None"); continue
        # el ahorro y el neto tienen que reconstruir el bruto exactamente
        if neto + ahorro != p:
            mal(f"{bruto}: neto {neto} + ahorro {ahorro} = {neto + ahorro}, no {p}")
        if neto.as_tuple().exponent < -2:
            mal(f"{bruto}: neto con más de 2 decimales ({neto})")
        esperado = (p * (100 - pct) / 100).quantize(Decimal("0.01"))
        if abs(neto - esperado) > Decimal("0.01"):
            mal(f"{bruto}: neto {neto}, esperado ~{esperado}")
    ok("aplicar() y ahorro() cierran en 5 precios, con 2 decimales")

    # 🔴 El error simétrico y más caro: aplicar el descuento dos veces.
    una = promo.aplicar("300.00")
    dos = promo.aplicar(una)
    if una == dos:
        mal("aplicar() es idempotente — no debería serlo; eso tapa el doble descuento")
    else:
        ok(f"doble aplicación detectable: 300.00 → {una} → {dos} (nunca encadenar)")


# --------------------------------------------------------------------------- #
# 2. Pantallas — recorre una compra real
# --------------------------------------------------------------------------- #
def _plata(txt: str) -> Decimal | None:
    """'US$ 1.234,56' / '$ 171.828' → Decimal. Devuelve None si no hay número."""
    t = re.sub(r"[^\d.,\-]", "", txt or "")
    if not t:
        return None
    if "," in t and "." in t:            # 1.234,56 → 1234.56
        t = t.replace(".", "").replace(",", ".")
    elif "," in t:
        t = t.replace(",", ".")
    elif t.count(".") > 1:               # 171.828 → 171828
        t = t.replace(".", "")
    elif re.match(r"^\d{1,3}\.\d{3}$", t):
        t = t.replace(".", "")
    try:
        return Decimal(t)
    except Exception:
        return None


def verificar_pantallas(base: str, handle: str | None) -> None:
    print(f"\n== PANTALLAS — {base} ==")
    base = base.rstrip("/")
    jar = http.cookiejar.CookieJar()
    br = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
    br.addheaders = [("User-Agent", UA)]

    def get(ruta: str) -> str:
        with br.open(base + ruta, timeout=60) as r:
            return r.read().decode("utf-8", "replace")

    def post(ruta: str, payload: dict) -> dict:
        req = urllib.request.Request(
            base + ruta, data=json.dumps(payload).encode(),
            headers={"Content-Type": "application/json", "User-Agent": UA})
        with br.open(req, timeout=60) as r:
            return json.loads(r.read().decode("utf-8", "replace"))

    # --- elegir un producto con stock ---
    if not handle:
        listado = get("/productos")
        cand = re.findall(r"/productos/([a-z0-9\-]+)", listado)
        cand = [c for c in dict.fromkeys(cand) if c != "products"]
        if not cand:
            mal("no se pudo sacar ningún handle de /productos"); return
        handle = cand[0]
    ok(f"producto de prueba: {handle}")

    ficha = get(f"/productos/{handle}")
    # `data-vid` es el atributo real del botón de talle (product.html:136). Se
    # busca ADEMÁS el caso de variante única, que no dibuja botones y deja el id
    # escrito en el JS de la ficha (product.html:233).
    vids = re.findall(r'data-vid="(\d+)"', ficha) or \
           re.findall(r'selectedVid\s*=\s*"(\d+)"', ficha)
    if not vids:
        mal(f"no encontré variant_id en la ficha de {handle} — ¿cambió el markup?")
        return

    # --- el precio que anuncia la ficha ---
    m = re.search(r'class="[^"]*mi-precio[^"]*"[^>]*>\s*([^<]+)<', ficha)
    precio_ficha = _plata(m.group(1)) if m else None
    if precio_ficha is None:
        mal("no pude leer el precio de la ficha")
    else:
        ok(f"la ficha anuncia {precio_ficha}")

    # --- agregar al carrito ---
    agregado = False
    for vid in vids[:6]:
        try:
            post("/api/cart/add", {"variant_id": int(vid), "quantity": 1})
            agregado = True
            ok(f"agregado al carrito (variant {vid})")
            break
        except urllib.error.HTTPError as e:
            continue                      # sin stock: probamos el siguiente talle
    if not agregado:
        mal(f"ningún talle de {handle} se pudo agregar (¿sin stock?)"); return

    # --- lo que dice el carrito ---
    carrito = get("/carrito")
    sub_c = _plata((re.search(r"data-subtotal[^>]*>([^<]+)<", carrito) or [None, ""])[1])
    off_c = _plata((re.search(r"data-descuento[^>]*>([^<]+)<", carrito) or [None, ""])[1])
    tot_c = _plata((re.search(r"data-total[^>]*>([^<]+)<", carrito) or [None, ""])[1])
    if tot_c is None:
        mal("el carrito no muestra Total")
    else:
        ok(f"carrito: subtotal {sub_c} · off {off_c} · total {tot_c}")
        # Tolerancia de 1: el resumen se muestra en PESOS y cada cifra se
        # redondea por separado (202.150 × 0,85 = 171.827,5 → 171.828, mientras
        # el descuento 30.322,5 → 30.323). La cuenta exacta vive en USD con dos
        # decimales; acá se compara lo que el cliente LEE.
        if sub_c is not None and off_c is not None and abs((sub_c - off_c) - tot_c) > 1:
            mal(f"el carrito no cierra: {sub_c} − {off_c} ≠ {tot_c}")
        else:
            ok("el carrito cierra: subtotal − off = total (±1 por redondeo a pesos)")

    # --- lo que dice el checkout: el número Y el guardián ---
    chk = get("/checkout")
    m = re.search(r'id="total-final"[^>]*>([^<]+)<', chk)
    tot_k = _plata(m.group(1)) if m else None
    if tot_k is None:
        mal("el checkout no muestra #total-final")
    elif tot_c is not None and tot_k != tot_c:
        mal(f"🔴 el checkout dice {tot_k} y el carrito {tot_c} — NO coinciden")
    else:
        ok(f"el checkout muestra el mismo total que el carrito ({tot_k})")

    # 🔴 El guardián compara contra `esperado`. Si le pasan el subtotal de lista,
    # la diferencia es exactamente el descuento y el aviso salta SIEMPRE.
    m = re.search(r"const esperado\s*=\s*([\d.]+)\s*;", chk)
    if not m:
        mal("no encontré `const esperado` en el checkout")
    else:
        esperado = Decimal(m.group(1))
        if tot_c is not None and abs(esperado - tot_c) > Decimal("0.5"):
            mal(f"🔴 el guardián compara contra {esperado} pero se cobra {tot_c}: "
                f"el aviso 'el precio se actualizó' va a saltar en TODAS las compras")
        else:
            ok(f"el guardián compara contra el total real ({esperado})")

    # --- el porcentaje que se predica es el que se aplica ---
    if sub_c and tot_c and sub_c > 0:
        real = (1 - tot_c / sub_c) * 100
        pct = promo.porcentaje()
        if pct and abs(real - pct) > Decimal("0.6"):
            mal(f"se anuncia {pct}% y se descuenta {real:.2f}%")
        else:
            ok(f"se anuncia {pct}% y se descuenta {real:.2f}%")

    # --- limpiar: el carrito de prueba no queda dando vueltas ---
    try:
        for vid in vids[:6]:
            try: post("/api/cart/remove", {"variant_id": int(vid)})
            except Exception: pass
        ok("carrito de prueba vaciado")
    except Exception:
        pass


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--url", help="base a verificar (ej: https://miamiimport.com.ar). "
                                  "Sin esto solo corre la aritmética.")
    ap.add_argument("--handle", help="forzar un producto concreto")
    a = ap.parse_args()

    print(f"PROMO: activa={promo.PROMO.get('activa')} "
          f"porcentaje={promo.PROMO.get('porcentaje')} hasta={promo.PROMO.get('hasta')}")
    verificar_aritmetica()
    if a.url:
        try:
            verificar_pantallas(a.url, a.handle)
        except Exception as e:
            mal(f"la verificación contra {a.url} explotó: {type(e).__name__}: {e}")
    else:
        print("\n(sin --url: no se verificaron las pantallas)")

    print(f"\n{'=' * 58}")
    if FALLAS:
        print(f"{len(FALLAS)} FALLA(S) — el descuento NO dice lo mismo en todos lados:")
        for f in FALLAS:
            print(f"  · {f}")
        return 1
    print(f"TODO CIERRA — {len(PASOS)} comprobaciones")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
