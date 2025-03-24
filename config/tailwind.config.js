/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./force-include.html'],
  safelist: ['text-red-600', 'text-4xl'],
  
  theme: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
  ]
}
