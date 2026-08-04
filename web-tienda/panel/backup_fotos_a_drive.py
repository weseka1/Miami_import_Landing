#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Backup retroactivo de fotos: descarga las imágenes de TODOS los productos
de Tiendanube y las guarda en la carpeta LOCAL_BACKUP_PATH con el nombre
enriquecido (marca, producto, talles, precio, ID, posición).

Si esa carpeta está sincronizada con Google Drive vía "Drive for Desktop",
las fotos terminan en Drive automáticamente. Sin OAuth, sin API keys.

Uso:
    python backup_fotos_a_drive.py            # baja todo
    python backup_fotos_a_drive.py --dry-run  # sólo lista, no guarda
    python backup_fotos_a_drive.py --limit 5  # primeros 5 productos

Requisitos:
    .env con LOCAL_BACKUP_PATH apuntando a una carpeta existente o creable.

Idempotencia:
    Antes de bajar, lista los archivos ya presentes en la carpeta local y
    omite los que tengan el mismo nombre.
"""
from __future__ import annotations

import argparse
import sys
import time
from pathlib import Path
from typing import List

import truststore; truststore.inject_into_ssl()
import requests

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

# Reusar la lectura de .env de app.py
from app import CONFIG, STORE_ID, TOKEN, UA, BASE_TN  # noqa: E402
from . import drive_helper  # noqa: E402


def tn_get(path: str) -> requests.Response:
    return requests.get(
        f"{BASE_TN}{path}",
        headers={"Authentication": f"bearer {TOKEN}", "User-Agent": UA},
        timeout=30,
    )


def list_all_products() -> List[dict]:
    out = []
    page = 1
    while True:
        r = tn_get(f"/products?per_page=200&page={page}")
        if not r.ok:
            print(f"[!] Error listando productos: {r.status_code} {r.text[:200]}")
            break
        d = r.json()
        if not d:
            break
        out.extend(d)
        if len(d) < 200:
            break
        page += 1
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="No guarda nada, sólo simula.")
    ap.add_argument("--limit", type=int, default=0, help="Limitar a N productos.")
    args = ap.parse_args()

    if not drive_helper.is_enabled():
        print(f"[!] Backup desactivado: {drive_helper.status()['reason']}")
        print("    Completá LOCAL_BACKUP_PATH en .env (ej:")
        print('    LOCAL_BACKUP_PATH=C:/Users/Yamil/Miami Import - Fotos).')
        sys.exit(1)

    backup_path = drive_helper.status()["backup_path"]
    print(f"[ok] Backup habilitado. Carpeta: {backup_path}")
    print(f"[..] Listando productos de Tiendanube store {STORE_ID}...")
    productos = list_all_products()
    print(f"[ok] {len(productos)} productos encontrados.")

    if args.limit > 0:
        productos = productos[: args.limit]
        print(f"[..] Limitado a primeros {len(productos)}.")

    existing = drive_helper.existing_filenames()
    print(f"[ok] {len(existing)} archivos ya en la carpeta local (se omiten).")

    total_imgs = 0
    subidos = 0
    omitidos = 0
    errores = 0

    for idx, p in enumerate(productos, 1):
        nm = p.get("name")
        nm_es = nm.get("es") if isinstance(nm, dict) else (nm or "producto")
        marca = p.get("brand") or ""
        pid = p["id"]
        variantes = p.get("variants") or []
        talles = []
        for v in variantes:
            vals = v.get("values") or []
            if vals and isinstance(vals[0], dict):
                t = vals[0].get("es")
                if t:
                    talles.append(t)
        precio = variantes[0].get("price") if variantes else "0"
        imagenes = p.get("images") or []

        print(f"\n[{idx}/{len(productos)}] {marca} — {nm_es}  ({len(imagenes)} fotos)")

        for pos, img in enumerate(imagenes, 1):
            total_imgs += 1
            src_url = img.get("src") or ""
            if not src_url:
                continue
            ext = drive_helper.guess_ext_from_filename(src_url.split("?")[0])
            drive_name = drive_helper.build_filename(
                marca=marca,
                producto=nm_es,
                talles=talles,
                precio=precio,
                moneda="ARS",
                tn_id=pid,
                position=pos,
                ext=ext,
            )
            if drive_name in existing:
                omitidos += 1
                print(f"    -- ya existe: {drive_name}")
                continue
            if args.dry_run:
                print(f"    [dry] {drive_name}")
                continue
            try:
                r = requests.get(src_url, timeout=60)
                if not r.ok:
                    errores += 1
                    print(f"    !! no se pudo bajar {src_url[:60]}... ({r.status_code})")
                    continue
                res = drive_helper.upload_bytes(r.content, drive_name)
                if res:
                    subidos += 1
                    existing.add(drive_name)
                    print(f"    ++ {drive_name}")
                else:
                    errores += 1
                    print(f"    !! error guardando {drive_name}")
            except Exception as e:
                errores += 1
                print(f"    !! excepción: {e}")
            time.sleep(0.05)

    print()
    print("============================================")
    print(f"  Productos procesados : {len(productos)}")
    print(f"  Imágenes encontradas : {total_imgs}")
    print(f"  Guardadas localmente : {subidos}")
    print(f"  Omitidas (ya estaban): {omitidos}")
    print(f"  Errores              : {errores}")
    print("============================================")


if __name__ == "__main__":
    main()
