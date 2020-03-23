(function () {
  window.addEventListener('DOMContentLoaded', initialize);

  let nav;
  let close;
  let menu;

  function initialize() {
    nav = document.getElementById('navigation');
    close = document.getElementById('nav-close');
    menu = document.getElementById('nav-menu');

    close.onclick = closeMenu;
    menu.onclick = showMenu;

    closeMenu();
  }

  function closeMenu() {
    nav.classList.add('closed');
  }

  function showMenu() {
    nav.classList.remove('closed');
  }
})();
