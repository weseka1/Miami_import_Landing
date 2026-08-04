# MIAMI_IMPORT — Stock Manager

App de escritorio liviana para gestionar el stock, productos y ver pedidos
de **miamiimport4.mitiendanube.com** sin tener que entrar al admin de
Tiendanube cada vez.

## Cómo arrancar

1. **Doble click en `start.bat`** (Windows). La primera vez instala
   dependencias (toma 1-2 minutos), después arranca el servidor.
2. Se abre solo el navegador en `http://localhost:8000`.
3. Para cerrarla: cerrá la ventana negra (CMD).

## Qué hace

### Dashboard
- KPIs rápidos: productos publicados, stock total, sin stock, facturación.
- Top 10 productos más vendidos.
- Lista de productos con stock bajo (≤ 1 unidad).

### Productos
- Grilla con foto de todos los productos.
- Buscador en vivo (nombre / marca).
- Click en cualquier producto → modal con:
  - Foto grande
  - Link a la página del producto en la tienda
  - Lista de variantes (talles) con su stock actual
  - Botones `+` y `−` para ajustar stock, o tipear cantidad exacta
  - Botón "Guardar cambios" → sube los cambios a Tiendanube
  - Botón "Eliminar producto"

### Nuevo producto
- Formulario simple: nombre, marca, precio, talles, stock, descripción.
- Opción "Convertir USD → ARS" si el precio se ingresa en dólares.
- Upload de imágenes drag-and-drop (la primera es la portada).
- Crea el producto en Tiendanube + sube todas las imágenes en una sola
  operación.

### Pedidos
- Lista de los últimos 100 pedidos con estado, cliente, total, fecha.
- Click en "Actualizar" para refrescar.

### Estadísticas
- Métricas calculadas a partir de productos + pedidos.
- Link al panel completo de Tiendanube para ver más.

### Descargar Excel completo
- Botón en el menú izquierdo abajo: genera un Excel con 3 hojas:
  - **productos**: lista completa con stock, precios, URL, categorías
  - **variantes**: detalle por talle/SKU
  - **pedidos**: histórico de pedidos con cliente y productos

## Configuración

Las credenciales de Tiendanube están en `.env`:

```
TIENDANUBE_STORE_ID=7575582
TIENDANUBE_ACCESS_TOKEN=<token>
TIENDANUBE_USER_AGENT=...
USD_TO_ARS_RATE=1410
LOCAL_BACKUP_PATH=C:/Users/Yamil/Miami Import - Fotos
```

Si cambia el tipo de cambio, edita `USD_TO_ARS_RATE` en el `.env` y
reiniciá el servidor.

## Backup automático de fotos

Cada foto que se sube a Tiendanube se duplica en una **carpeta local**
(`LOCAL_BACKUP_PATH`) con un nombre que contiene **toda la info del
producto**:

```
DIESEL__remera-regular-blanca__talles-S-M-L__45000ARS__TN-123456__01.jpg
└─marca─┘ └────producto─────┘ └───talles───┘ └─precio─┘ └id-TN─┘ └pos┘
```

Así se puede buscar por marca, talle, precio o ID de Tiendanube sin
abrir cada imagen.

### Sincronizar la carpeta con Google Drive

1. Instalar **Drive for Desktop**: https://www.google.com/drive/download/
2. Loguearse con `yamilpintos18@gmail.com`.
3. En el ícono de Drive (bandeja del sistema) → **Settings → Preferences**.
4. **"My Computer" → "Add folder"** → seleccionar `C:\Users\Yamil\Miami Import - Fotos`.
5. Elegir **"Sync with Google Drive"** (la opción que sube la carpeta a la
   nube — la otra "Backup to Photos" es sólo para fotos personales).
6. Listo. Toda foto que aparezca en la carpeta se sube sola a Drive y
   queda visible en https://drive.google.com en una carpeta llamada
   *"Computers / My Computer / Miami Import - Fotos"*.

Ventaja vs API: sin OAuth, sin service accounts, usa tu cuota normal de
15 GB de Drive, y funciona también offline (queue de sync).

### Bajar las fotos viejas (backup retroactivo)

Para volcar a la carpeta local todas las fotos ya publicadas en Tiendanube:

```
python backup_fotos_a_drive.py
```

Opciones:
- `--dry-run` muestra qué bajaría sin tocar nada.
- `--limit 5` procesa sólo los primeros 5 productos (para probar).

Es idempotente: si una foto ya está en la carpeta con el mismo nombre,
la omite.

### Estado del backup

Para confirmar que está activo: abrir `http://localhost:8000/api/backup/status`.

### En Render (deploy en la nube)

El backup local **no aplica a Render** (no hay disco persistente). En
Render, dejar `LOCAL_BACKUP_PATH` vacío y la app sigue funcionando
contra Tiendanube sin backup. El backup se hace desde la PC local.

## Requisitos

- Windows 10/11 + Python 3.10 o superior instalado.
- Para verificar: abrí cmd y escribí `python --version`. Si no lo tenés,
  instalá desde https://www.python.org/downloads/ (durante la instalación
  marcá la opción **"Add Python to PATH"**).
- Conexión a internet (todas las operaciones consultan la API de
  Tiendanube).

## Estructura del proyecto

```
Stock_Manager_Miami_Import/
├── app.py                    ← backend FastAPI (proxy a Tiendanube)
├── drive_helper.py           ← guardado local + nombre enriquecido
├── backup_fotos_a_drive.py   ← script para bajar las fotos viejas
├── .env                      ← credenciales (no compartir)
├── requirements.txt          ← dependencias Python
├── start.bat                 ← lanzador para Windows
├── README.md                 ← este archivo
└── static/
    ├── index.html            ← UI (1 sola pantalla, tabs)
    ├── css/style.css         ← estilos premium blanco/negro
    └── js/app.js             ← lógica frontend
```

## Notas de seguridad

- El `.env` tiene el token de acceso a la API de Tiendanube. Si compartís
  este proyecto, **NO incluyas el `.env`** — regenera el token desde el
  admin si se filtró.
- La app corre solo en `localhost` (tu propia PC). No es accesible desde
  internet salvo que abras explícitamente el puerto 8000.

## Troubleshooting

- **"python no se reconoce como comando"**: instalá Python desde
  python.org y reiniciá la PC.
- **"Error de SSL"**: el script usa `truststore` para evitar problemas con
  certificados en Windows. Si igualmente da error, ejecutá:
  `python -m pip install --upgrade certifi truststore`.
- **"El puerto 8000 está en uso"**: cerrá otras instancias de la app y
  volvé a abrir.
- **"Error 401 / Unauthorized"**: el token está vencido o no tiene
  permisos suficientes. Regenerá uno nuevo en Tiendanube admin.
