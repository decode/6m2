$(document).ready(function(){
  $(".formtastic").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $(".simple_form").validationEngine('attach', {promptPosition : "centerRight", scroll: false});

  $("#user_new").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#user_edit").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#charge").validationEngine('attach', {promptPosition : "centerRight", scroll: false});


  $('#customer_service').easyListSplitter({ colNumber: 4 });

  /*$("#site-bar").jixedbar();*/
  /*
  setTimeout(function(){
    $('#slider').nivoSlider({ pauseTime:5000, pauseOnHover:false, effect:'fade' });
  }, 1000);
  */
  /*$('#slider').coinslider({ height: 150, hoverPause: true });*/

	$('#slides1').bxSlider({
		prev_image: 'images/btn_arrow_left.jpg',
		next_image: 'images/btn_arrow_right.jpg',
		wrapper_class: 'slides1_wrap',
		/*margin: 70,*/
		auto: true,
		auto_controls: false
	});

  $("#data_table").tablesorter(); 

  $.jtabber({
    mainLinkTag: "#nav a", // much like a css selector, you must have a 'title' attribute that links to the div id name
    activeLinkClass: "selected", // class that is applied to the tab once it's clicked
    hiddenContentClass: "hiddencontent", // the class of the content you are hiding until the tab is clicked
    showDefaultTab: 1, // 1 will open the first tab, 2 will open the second etc.  null will open nothing by default
    showErrors: false, // true/false - if you want errors to be alerted to you
    effect: 'slide', // null, 'slide' or 'fade' - do you want your content to fade in or slide in?
    effectSpeed: 'fast' // 'slow', 'medium' or 'fast' - the speed of the effect
  });

  /*
  var footerHeight = 0,
      footerTop = 0,
      $footer = $("#footer");

  positionFooter();

  function positionFooter() {

    footerHeight = $footer.height();
    footerTop = ($(window).scrollTop()+$(window).height()-footerHeight)+"px";

    if ( ($(document.body).height()+footerHeight) < $(window).height()) {
      $footer.css({
        position: "absolute"
      }).animate({
        top: footerTop
      })
    } else {
      $footer.css({
        position: "static"
      })
    }

  }

  $(window)
    .scroll(positionFooter)
    .resize(positionFooter)
  */

});
