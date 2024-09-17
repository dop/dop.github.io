window.addEventListener('DOMContentLoaded', initializePresentation);

let current = 0;
let slides = [];
let colorClassName = '';

const defaultFontSize = 4;
let fontZoomStep = 0.1;
let fontZoom = 0;

function showCurrentSlide(opts = {}) {
  if (slides[current]) {
    slides[current].scrollIntoView({behavior: opts.animate ? 'smooth' : 'auto'});
  }
}

function advanceSlidesBy(n) {
  current = Math.max(0, Math.min(slides.length - 1, current + n));
}

function next() {
  advanceSlidesBy(1);
  showCurrentSlide({animate: true})
}

function previous() {
  advanceSlidesBy(-1);
  showCurrentSlide({animate: true})
}

function firstSlide() {
  current = 0;
  showCurrentSlide();
}

function lastSlide() {
  current = slides.length - 1;
  showCurrentSlide();
}

function toggleFullscreen() {
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen();
  }
}

function toggleColorScheme() {
  const alternative = 'light';
  const cl = document.body.classList;
  if (cl.contains(alternative)) {
    colorClassName = '';
    cl.remove(alternative);
  } else {
    cl.add(colorClassName = alternative);
  }
}

function zoomOut() {
  fontZoom -= 1;
  setFontZoom();
}

function zoomIn() {
  fontZoom += 1;
  setFontZoom();
}

function zoom0() {
  fontZoom = 0;
  setFontZoom();
}

function exitPresentation() {
  const sheet = document.querySelector('#presentation-stylesheet');
  sheet.disabled = true;
  destroyPresentation();
}

const commands = {
  // Next
  n: next,
  N: next,
  ArrowDown: next,
  ArrowRight: next,
  ' ': next,

  // Previous
  p: previous,
  p: previous,
  ArrowUp: previous,
  ArrowLeft: previous,
  Backspace: previous,
  b: firstSlide,
  B: firstSlide,
  e: lastSlide,
  E: lastSlide,

  f: toggleFullscreen,
  F: toggleFullscreen,

  t: toggleColorScheme,
  T: toggleColorScheme,

  '-': zoomOut,
  '=': zoomIn,
  '0': zoom0,

  x: exitPresentation,
  X: exitPresentation,
}

function setFontZoom() {
  const fontSize = defaultFontSize + fontZoomStep * fontZoom;
  document.body.style = '--font-size: ' + fontSize + 'vmin';
}

function initializePresentation() {
  initializeSlides();
  initializeKeyBindings();
  initializeMouseEvents();
}

function destroyPresentation() {
  window.removeEventListener('resize', showCurrentSlide);
  // document.body.removeEventListener('click', next);
  window.removeEventListener('keydown', runPresentation);
  localStorage.removeItem('presentation');
}

function initializeSlides() {
  current = 0;
  slides = Array.from(document.querySelectorAll('#content > *'));
  try {
    ({current, colorClassName, fontZoom} = JSON.parse(localStorage.getItem('presentation')));
  } catch (e) {
  }
  if (colorClassName) {
    document.body.classList.add(colorClassName);
  }
  setFontZoom();
  showCurrentSlide();
  window.addEventListener('resize', showCurrentSlide);
}

function runPresentation(event) {
  const command = commands[event.key];
  if (command) {
    event.preventDefault();
    command();
    localStorage.setItem('presentation', JSON.stringify({current, colorClassName, fontZoom}));
    return false;
  } else {
    console.log(event);
  }
}

function initializeKeyBindings() {
  window.addEventListener('keydown', runPresentation);
}

function initializeMouseEvents() {
  // document.body.addEventListener('click', next);
}
