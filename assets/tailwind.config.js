module.exports = {
  theme: {
    extend: {
      colors: {
        'dark': {
          '100': 'rgb(31, 32, 35)',
          '150': 'rgb(39, 40, 43)',
          '200': 'rgb(48, 50, 54)',
          '300': 'rgb(60, 63, 68)',
          '500': 'rgb(138, 143, 152)',
          '600': 'rgb(215, 216, 219)'
        }
      }
    }
  },
  variants: {},
  plugins: [
    require('@tailwindcss/ui')
  ]
}
