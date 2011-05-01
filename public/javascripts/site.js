$(document).ready(function(){
  $("#new_task").validationEngine('attach', {promptPosition : "centerRight", scroll: true});
  $("#new_transport").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_notice").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_article").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_message").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_issue").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_participant").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#user_new").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#user_edit").validationEngine('attach', {promptPosition : "centerRight", scroll: false});

  $('#customer_service').easyListSplitter({ colNumber: 4 });

  //cache the ticker
  var ticker = $("#ticker");

  //wrap dt:dd pairs in divs
  ticker.children().filter("dt").each(function() {

    var dt = $(this),
    container = $("<div>");

  dt.next().appendTo(container);
  dt.prependTo(container);

  container.appendTo(ticker);
  });

  //hide the scrollbar
  ticker.css("overflow", "hidden");

  //animator function
  function animator(currentItem) {

    //work out new anim duration
    var distance = currentItem.height();
    duration = (distance + parseInt(currentItem.css("marginTop"))) / 0.025;

    //animate the first child of the ticker
    currentItem.animate({ marginTop: -distance }, duration, "linear", function() {

      //move current item to the bottom
      currentItem.appendTo(currentItem.parent()).css("marginTop", 0);

      //recurse
      animator(currentItem.parent().children(":first"));
    }); 
  };

  //start the ticker
  animator(ticker.children(":first"));

  //set mouseenter
  ticker.mouseenter(function() {

    //stop current animation
    ticker.children().stop();

  });

  //set mouseleave
  ticker.mouseleave(function() {

    //resume animation
    animator(ticker.children(":first"));

  });
});
