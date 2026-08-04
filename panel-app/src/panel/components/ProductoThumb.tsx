import { useState } from "react";
import { Shirt } from "lucide-react";
import { cn } from "../ui/cn";

/**
 * Miniatura de producto. Si hay foto la muestra; si no (o si falla la carga),
 * cae en la "placa de producto" tipográfica: marca + pictograma de prenda
 * sobre paper-200. Nada de fotos falsas.
 */
export default function ProductoThumb({
  src,
  marca,
  alt,
  className,
  rounded = "rounded-lg",
  placa = false,
}: {
  src?: string;
  marca?: string | null;
  alt: string;
  className?: string;
  rounded?: string;
  /** true = versión grande (cards de grilla): marca visible bajo el pictograma. */
  placa?: boolean;
}) {
  const [err, setErr] = useState(false);

  if (!src || err) {
    return (
      <div className={cn("flex flex-col items-center justify-center gap-1.5 bg-paper-200", rounded, className)}>
        <Shirt size={placa ? 30 : 18} strokeWidth={1.5} className="text-graph-400" />
        {placa && marca && (
          <span className="max-w-full truncate px-3 text-[10px] font-semibold uppercase tracking-widest2 text-graph-400">{marca}</span>
        )}
      </div>
    );
  }
  return (
    <img
      src={src}
      alt={alt}
      loading="lazy"
      onError={() => setErr(true)}
      className={cn("bg-paper-200 object-contain", rounded, className)}
    />
  );
}
