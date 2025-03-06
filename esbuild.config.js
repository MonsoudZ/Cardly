const esbuild = require('esbuild')

const isWatch = process.argv.includes('--watch')

const buildOptions = {
  entryPoints: ['app/javascript/*.js'],
  bundle: true,
  sourcemap: true,
  outdir: 'app/assets/builds',
  publicPath: '/assets',
  format: 'iife',
  target: ['es2020'],
  plugins: [],
  define: {
    'process.env.NODE_ENV': '"development"'
  }
}

if (isWatch) {
  esbuild.context(buildOptions).then(ctx => {
    ctx.watch()
  }).catch(() => process.exit(1))
} else {
  esbuild.build(buildOptions).catch(() => process.exit(1))
} 