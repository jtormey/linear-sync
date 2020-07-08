module.exports = {
  theme: {
    extend: {
      colors: {
        'dark': {
          '100': 'rgb(31, 32, 35)',
          '200': 'rgb(48, 50, 54)',
          '300': 'rgb(60, 63, 68)',
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
