import type { LucideIcon } from "lucide-react";
import { TrendingUp, TrendingDown } from "lucide-react";
import { cn } from "../ui/cn";

export type KpiAccent = "brand" | "ink" | "sea" | "amber" | "red";

interface KpiCardProps {
  label: string;
  value: string;
  icon: LucideIcon;
  delta?: string;
  deltaDir?: "up" | "down";
  hint?: string;
  accent?: KpiAccent;
}

const accentChip: Record<KpiAccent, string> = {
  brand: "bg-brand/10 text-brand-700 ring-1 ring-inset ring-brand/20",
  ink: "bg-graph/[0.05] text-graph-700 ring-1 ring-inset ring-graph/10",
  sea: "bg-sea/10 text-sea ring-1 ring-inset ring-sea/25",
  amber: "bg-amber-500/12 text-amber-700 ring-1 ring-inset ring-amber-500/25",
  red: "bg-red-500/10 text-red-700 ring-1 ring-inset ring-red-500/20",
};
const glow: Record<KpiAccent, string> = {
  brand: "bg-brand",
  ink: "bg-graph",
  sea: "bg-sea",
  amber: "bg-amber-500",
  red: "bg-red-500",
};

export default function KpiCard({ label, value, icon: Icon, delta, deltaDir = "up", hint, accent = "brand" }: KpiCardProps) {
  return (
    <div className="pcard pcard-hover group relative overflow-hidden p-5">
      <div className={cn("pointer-events-none absolute -right-6 -top-6 h-24 w-24 rounded-full opacity-[0.08] blur-2xl transition-opacity duration-300 group-hover:opacity-[0.16]", glow[accent])} />
      <div className="relative flex items-start justify-between">
        <div className={cn("flex h-10 w-10 items-center justify-center rounded-xl", accentChip[accent])}>
          <Icon size={18} strokeWidth={2.2} />
        </div>
        {delta && (
          <span className={cn("inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold", deltaDir === "up" ? "bg-sea/10 text-sea" : "bg-red-500/10 text-red-700")}>
            {deltaDir === "up" ? <TrendingUp size={12} /> : <TrendingDown size={12} />}
            {delta}
          </span>
        )}
      </div>
      <p className="relative mt-4 font-display text-[2rem] font-semibold leading-none tracking-tight text-graph">{value}</p>
      <p className="relative mt-2 text-sm font-medium text-graph-500">{label}</p>
      {hint && <p className="relative mt-1 text-xs text-graph-400">{hint}</p>}
    </div>
  );
}
