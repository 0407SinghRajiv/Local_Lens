import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/features/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        heading: ["Anton", "'Noto Sans Devanagari'", "'Noto Sans Bengali'", "Inter", "sans-serif"],
        display: ["Anton", "'Noto Sans Devanagari'", "'Noto Sans Bengali'", "Inter", "sans-serif"],
        anton: ["Anton", "'Noto Sans Devanagari'", "'Noto Sans Bengali'", "Inter", "sans-serif"],
        sans: ["Inter", "'Noto Sans Devanagari'", "'Noto Sans Bengali'", "sans-serif"],
        body: ["Inter", "'Noto Sans Devanagari'", "'Noto Sans Bengali'", "sans-serif"],
      },
      colors: {
        background: "var(--background)",
        foreground: "var(--foreground)",
      },
    },
  },
  plugins: [],
};

export default config;
