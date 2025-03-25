/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.{html.erb,erb}', // <--- this includes partials like shared/_header.html.erb
    './app/helpers/**/*.rb',
    './app/javascript/**/*.{js,jsx,ts,tsx}',
  ],  
  theme: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
  ]
}
