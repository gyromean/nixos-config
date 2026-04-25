{ old }:
# Runtime workaround: returning from an external editor can leave OpenTUI visually
# stale until a real terminal resize happens, so force the same resize path on resume.
old.configurePhase + ''
  substituteInPlace \
    "node_modules/.bun/@opentui+core@0.1.99+391ab383291bedc0/node_modules/@opentui/core/index-8978gvk3.js" \
    --replace-fail \
    'this.lib.resumeRenderer(this.rendererPtr);' \
    'this.lib.resumeRenderer(this.rendererPtr); this._terminalIsSetup = false; void this.setupTerminal().then(() => { const width = this.stdout.columns || 80; const height = this.stdout.rows || 24; if (width > 1) { this.processResize(width - 1, height); } else if (height > 1) { this.processResize(width, height - 1); } this.processResize(width, height); this.requestRender(); });'
''
