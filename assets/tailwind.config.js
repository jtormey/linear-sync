const plugin = require("tailwindcss/plugin")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/*_web.ex",
    "../lib/*_web/**/*.*ex"
  ],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
        'dark': {
          '100': 'rgb(31, 32, 35)',
          '150': 'rgb(39, 40, 43)',
          '200': 'rgb(48, 50, 54)',
          '300': 'rgb(60, 63, 68)',
          '500': 'rgb(138, 143, 152)',
          '600': 'rgb(215, 216, 219)'
        }
      }
    },
  },
  plugins: [
    require('@tailwindcss/ui'),
    require("@tailwindcss/forms"),
    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"]))
  ]
}
