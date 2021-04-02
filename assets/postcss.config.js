module.exports = {
  plugins: [
    require(process.env.MIX_ENV === 'prod' ? 'tailwindcss' : '@tailwindcss/jit'),
    require('autoprefixer')
  ]
}
