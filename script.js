// script.js

window.addEventListener("load", function(){
    AOS.init({
        easing: 'ease-in-out',
        duration: 2500
    });

    const loader = document.querySelector(".loading");
    const container = document.querySelector(".container");
    const header = document.querySelector("header");
    const footer = document.querySelector("footer");

    // Hide loader and show container after 2 seconds
    setTimeout(function() {
        loader.remove();
        container.style.display = "flex";
        header.style.display = "block";
        footer.style.display = "block";
    }, 2000);
});
