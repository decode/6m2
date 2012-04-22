$(document).ready(function(){
  $(".simple_form").validationEngine('attach', {promptPosition : "bottomRight", scroll: false});

  $("#user_new").validationEngine('attach', {promptPosition : "bottomRight", scroll: false});
  $("#user_edit").validationEngine('attach', {promptPosition : "bottomRight", scroll: false});
  $("#charge").validationEngine('attach', {promptPosition : "bottomRight", scroll: false});

});
