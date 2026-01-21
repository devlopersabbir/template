export const chartType = ["PIE", "BAR", "LINE", "DONUT_PIE", "HEATMAP"] as const;
export type ChartType = (typeof chartType)[number];

export const nodeType = ["LEAF", "INTERMEDIATE", "ROOT"] as const;
export type NodeType = (typeof nodeType)[number];
