(function(){

function init(){
    var demo1 = document.getElementsByClassName('demo1')[0],
        domi1 = new OriDomi(demo1),
        demo2 = document.getElementsByClassName('demo2')[0],
        domi2 = new OriDomi(demo2, { hPanels: 1, vPanels: 3 }),
        demo3 = document.getElementsByClassName('demo3')[0],
        domi3 = new OriDomi(demo3, { hPanels: 1, vPanels: 5 }),
        demo4 = document.getElementsByClassName('demo4')[0],
        domi4 = new OriDomi(demo4, { hPanels: 1, vPanels: 6, perspective: 500 }),
        demo5 = document.getElementsByClassName('demo5')[0],
        domi5 = new OriDomi(demo5, { hPanels: 10, vPanels: 1 }),
        demo6 = document.getElementsByClassName('demo6')[0],
        domi6 = new OriDomi(demo6, { hPanels: 1, vPanels: 5, touchEnabled: false, speed: 400 }),
        foldMe = document.querySelector('.fold-me > p'),
        foldDomi = new OriDomi(foldMe, { vPanels: 1, hPanels: 4, perspective: 200, speed: 500 });

    foldMe.addEventListener('mouseover', function(){
        foldDomi.accordion(-40, 1);
    }, false);

    foldMe.addEventListener('mouseout', function(){
        foldDomi.reset();
    }, false);

    setTimeout(function(){
        domi1.reveal(40, 1);
    }, 1000);

    setTimeout(function(){
        domi2.reveal(40);
        domi3.stairs(-25, 2);
        domi4.accordion(-50);
        domi5.curl(-60, 1);
    }, 3000);

    demo6.addEventListener('click', function(){
        domi6.isFoldedUp ? domi6.reset() : domi6.foldUp();
    }, false);

}

document.addEventListener('DOMContentLoaded', init, false);

})();
