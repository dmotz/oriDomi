//(function(){
    

var $body,
    $tagline,
    $foldMe,
    $demo1,
    $demo2,
    $demo3,
    $demo4,
    $demo5,
    methodMap = { demo2: 'reveal', demo3: 'stairs', demo4: 'accordion', demo5: 'curl' };

function randomAngle(){
    return Math.random() * 60 * (Math.random() > .5 ? -1 : 1);
}

function init(){
    $body = $(document.body),
    $demo1 = $('.demo1').oriDomi(),
    $foldMe = $('.fold-me > p').oriDomi({ vPanels: 1, hPanels: 4, perspective: 200, speed: 500 }),
    $demo2 = $('.demo2').oriDomi({ hPanels: 1, vPanels: 3 }),
    $demo3 = $('.demo3').oriDomi({ hPanels: 1, vPanels: 5 });
    $demo4 = $('.demo4').oriDomi({ hPanels: 1, vPanels: 4, perspetive: 500 });
    $demo5 = $('.demo5').oriDomi({ hPanels: 10, vPanels: 1, perspetive: 500 });

    setTimeout(function(){
        $demo1.click();
    }, 1000);
    
    setTimeout(function(){
        $demo2.oriDomi('reveal', 40);
        $demo3.oriDomi('stairs', -25, 'r');
        $demo4.oriDomi('accordion', -50);
        $demo5.oriDomi('curl', -60, 't');
    }, 3000);
    
    
    
    
    

    $body.on('click', '.source-link', function(){
        var $this = $(this);
        if($this.hasClass('open')){
            $this.removeClass('open').html('&larr; view source')
                .parent().find('article').addClass('hidden');
        }else{
            $this.addClass('open').html('&larr; hide source')
                .parent().find('article').removeClass('hidden');
        }
    }).on('click', '.demo', function(){
        var $this = $(this);
        console.lo
        $this.oriDomi(methodMap['demo' + $this.attr('data-id')], randomAngle(), $this.attr('data-anchor'));
    });
    
    $demo1.on('click', function(){
        if($demo1.hasClass('scrunched')){
            $demo1.removeClass('scrunched').oriDomi('reset');
        }else{
            $demo1.addClass('scrunched').oriDomi('reveal', 40, 1);
        }
    });
    
    $foldMe.on('mouseover', function(){
        $foldMe.oriDomi('accordion', -40, 'top');

    }).on('mouseout', function(){
        $foldMe.oriDomi('reset');

    });
    
}


$(init);


//})();
