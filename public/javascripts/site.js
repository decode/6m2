$(document).ready(function(){
  $("#new_task").validationEngine('attach', {promptPosition : "centerRight", scroll: true});
  $("#new_transport").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_notice").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_article").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_message").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_issue").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_participant").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#new_transaction").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#user_new").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#user_edit").validationEngine('attach', {promptPosition : "centerRight", scroll: false});
  $("#charge").validationEngine('attach', {promptPosition : "centerRight", scroll: false});

  $('#customer_service').easyListSplitter({ colNumber: 4 });

  $("#site-bar").jixedbar();

  /*
  setTimeout(function(){
    $('#slider').nivoSlider({ pauseTime:5000, pauseOnHover:false, effect:'fade' });
  }, 1000);
  */
  $('#slider').coinslider({ height: 200, hoverPause: false });

});
