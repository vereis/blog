// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const defaultTheme = require("tailwindcss/defaultTheme");
const plugin = require("tailwindcss/plugin");
const fs = require("fs");
const path = require("path");

module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      fontFamily: {
        sans: [
          "FantasqueSansMono Nerd Font Mono",
          ...defaultTheme.fontFamily.mono,
        ],
        serif: [
          "FantasqueSansMono Nerd Font Mono",
          ...defaultTheme.fontFamily.mono,
        ],
        mono: [
          "FantasqueSansMono Nerd Font Mono",
          ...defaultTheme.fontFamily.mono,
        ],
      },
      colors: {
        brand: "#FD4F00",
      },
      typography: ({ theme }) => ({
        mono: {
          css: {
            "pre > code": { backgroundColor: "transparent !important" },
            "blockquote p": { fontStyle: "normal" },
            "blockquote p:first-of-type::before": { content: "none" },
            "blockquote p:first-of-type::after": { content: "none" },
            "--tw-prose-body": theme("colors.white"),
            "--tw-prose-headings": theme("colors.white"),
            "--tw-prose-lead": theme("colors.white"),
            "--tw-prose-links": theme("colors.white"),
            "--tw-prose-bold": theme("colors.white"),
            "--tw-prose-counters": theme("colors.white"),
            "--tw-prose-bullets": theme("colors.white"),
            "--tw-prose-hr": theme("colors.white"),
            "--tw-prose-quotes": theme("colors.white"),
            "--tw-prose-quote-borders": theme("colors.white"),
            "--tw-prose-captions": theme("colors.white"),
            "--tw-prose-code": theme("colors.white"),
            "--tw-prose-pre-code": theme("colors.white"),
            "--tw-prose-pre-bg": theme("colors.white"),
            "--tw-prose-th-borders": theme("colors.white"),
            "--tw-prose-td-borders": theme("colors.white"),
            "--tw-prose-invert-body": theme("colors.white"),
            "--tw-prose-invert-headings": theme("colors.white"),
            "--tw-prose-invert-lead": theme("colors.white"),
            "--tw-prose-invert-links": theme("colors.white"),
            "--tw-prose-invert-bold": theme("colors.white"),
            "--tw-prose-invert-counters": theme("colors.white"),
            "--tw-prose-invert-bullets": theme("colors.white"),
            "--tw-prose-invert-hr": theme("colors.white"),
            "--tw-prose-invert-quotes": theme("colors.white"),
            "--tw-prose-invert-quote-borders": theme("colors.white"),
            "--tw-prose-invert-captions": theme("colors.white"),
            "--tw-prose-invert-code": theme("colors.white"),
            "--tw-prose-invert-pre-code": theme("colors.white"),
            "--tw-prose-invert-pre-bg": theme("colors.white"),
            "--tw-prose-invert-th-borders": theme("colors.white"),
            "--tw-prose-invert-td-borders": theme("colors.white"),
          },
        },
      }),
    },
  },
  plugins: [
    require("@tailwindcss/typography"),
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, "./vendor/heroicons/optimized");
      let values = {};
      let icons = [
        ["", "/24/outline"],
        ["-solid", "/24/solid"],
        ["-mini", "/20/solid"],
      ];
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).map((file) => {
          let name = path.basename(file, ".svg") + suffix;
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) };
        });
      });
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, "");
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              "-webkit-mask": `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              "mask-repeat": "no-repeat",
              "background-color": "currentColor",
              "vertical-align": "middle",
              display: "inline-block",
              width: theme("spacing.5"),
              height: theme("spacing.5"),
            };
          },
        },
        { values }
      );
    }),
  ],
};
