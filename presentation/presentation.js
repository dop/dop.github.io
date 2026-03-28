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
  const sheet = document.querySelector('[rel="stylesheet"][href*="presentation"]');
  if (sheet) {
    sheet.disabled = true;
    destroyPresentation();
  }
}



const docs = new Map([
  [next, 'Next slide.'],
  [previous, 'Previous slide.'],
]);

const commands = new Map([
  [next, { doc: 'Next slide.', keys: ['n', 'N', 'ArrowDown', 'ArrowRight', ' '] }],
  [previous, { doc: 'Previous slide.', keys: ['p', 'P', 'ArrowUp', 'ArrowLeft', 'Backspace'] }],
  [firstSlide, { doc: 'First slide.', keys: ['b', 'B'] }],
  [lastSlide, { doc: 'Last slide.', keys: ['e', 'E'] }],
  [toggleFullscreen, { doc: 'Toggle fullscreen.', keys: ['f', 'F'] }],
  [toggleColorScheme, { doc: 'Toggle theme.', keys: ['t', 'T'] }],
  [zoomIn, { doc: 'Zoom in.', keys: ['=', '+'] }],
  [zoomOut, { doc: 'Zoom out.', keys: ['-'] }],
  [zoom0, { doc: 'Default zoom.', keys: ['0'] }],
  [exitPresentation, { doc: 'Exit presentation.', keys: ['x', 'X'] }],
  [toggleHelp, { doc: 'Toggle help.', keys: ['?'] }],
])

const commandByKey = new Map();
for (const [command, {keys}] of commands.entries()) {
  for (const key of keys) {
    commandByKey[key] = command;
  }
}

function setFontZoom() {
  const fontSize = defaultFontSize + fontZoomStep * fontZoom;
  document.body.style = '--font-size: ' + fontSize + 'vmin';
}

function initializePresentation() {
  initializeSlides();
  initializeKeyBindings();
  initializeMouseEvents();
  initializeHelp();
}

function destroyPresentation() {
  window.removeEventListener('resize', showCurrentSlide);
  window.removeEventListener('keydown', runPresentation);
  window.removeEventListener('click', navigate);
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
  const command = commandByKey[event.key];
  if (command) {
    event.preventDefault();
    command();
    localStorage.setItem('presentation', JSON.stringify({current, colorClassName, fontZoom}));
    return false;
  }
  // else {
  //   console.log(event);
  // }
}

function initializeKeyBindings() {
  window.addEventListener('keydown', runPresentation);
}

function initializeMouseEvents() {
  window.addEventListener('click', navigate);
}

function navigate(event) {
  const {x, y} = event;
  const {clientHeight: height, clientWidth: width} = document.documentElement;
  if (y < height * 0.25) {
    previous();
  }
  else if (y > height * 0.75) {
    next();
  }
  else if (x < width * 0.25) {
    previous();
  }
  else if (x > width * 0.75) {
    next();
  }
}

function initializeHelp() {
  document.body.insertAdjacentHTML(
    'beforeend',
    '<button id="help-toggle" onclick="javascript:toggleHelp()">?</button>',
  );
}

function toggleHelp() {
  const help = document.getElementById("help");
  if (help) {
    help.remove();
  } else {
    let table = '<div id="help"><table id="key-bindings">';
    table += '<thead><th>Key</th><th>Binding</th></thead>';

    for (const [command, {doc, keys}] of commands.entries()) {
      table += '<tr><td>';
      for (const key of keys) {
        table += '<code>' + prettyKey(key) + '</code>';
      }
      table += `</td><td>${doc}</td></tr>`;
    }

    table += '</table></div>';
    document.body.insertAdjacentHTML('afterbegin', table);
  }
}

const prettyKeys = {
  ArrowDown: '↓',
  ArrowUp: '↑',
  ArrowRight: '→',
  ArrowLeft: '←',
  Backspace: '⌫',
  ' ': '␣',
}

function prettyKey(key) {
  return prettyKeys[key] ?? key;
}

