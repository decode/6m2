$(document).ready(function() {
    // put all your jQuery goodness in here.
  //$('#content').width($(window).width());
  //$('#navibar').width($(window).width());
  //$('#toolbar').width($(window).width());

  //alert($('#navibar').css('padding-left'));
  //alert($("#wrapper").width());
  //$("#charge").validationEngine();

});
/*
function validate() {
  alert('true');
  var amount = $('#amount').val();
  var re=/^\d+[.]?\d{1,2}$/;
  if( amount != '' ) {
    if(!re.test(amount)) {
      return false;
    }
    else if( amount <= 0) {
      return false;
    }
  }
  return true;
};*/

$(function() {
  $('#amount').blur(function() {

    var amount = $(this).val();
    var re=/^\d+[.]?\d{1,2}$/;
    if( amount != '' ) {
      if(!re.test(amount)) {
        $('#price_error').remove();
        $('#charge').append('<div id="price_error" class="error">金额必须为数字，如有小数请保留两位！</div>');
      }
      else if( amount <= 0) {
        $('#price_error').remove();
        $('#task_price_input').append('<div id="price_error" class="error">请核对金额！</div>');
      }
      else if($('#link_error').length > 0) {
        $('#price_error').remove();
      }
    }
  });

  $('#task_price').blur(function() {

    var amount = $(this).val();
    var re=/^\d+[.]?[\d{1,2}]?$/;
    if( amount != '' ) {
      if(!re.test(amount))
      {
        $('#price_error').remove();
        $('#task_price_input').append('<div id="price_error" class="error">金额必须为数字，如有小数请保留两位！</div>');
      }
      else if( amount <= 0) {
        $('#price_error').remove();
        $('#task_price_input').append('<div id="price_error" class="error">请核对金额！</div>');
      }
      else if($('#link_error').length > 0) {
        $('#price_error').remove();
      }
    }
  });

  $('#email').blur(function() {
    var txt_value = $(this).val();
    if(txt_value=='') {
     $(this).val('请输入邮箱地址')
    }
    else if(!(/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(txt_value))) {
      alert('请输入一个有效的邮件地址');
      $(this).val('');
      return false;
    }
  });

  $('#task_link').blur(function() {
    var str = $(this).val();
    var RegUrl = new RegExp();
    RegUrl.compile("^[A-Za-z]+://[A-Za-z0-9-_]+\\.[A-Za-z0-9-_%&\?\/.=]+$");
    if (!RegUrl.test(str)) {
        $('#link_error').remove();
        $('#task_link_input').append('<div id="link_error" class="error">错误的网址</div>');
    }
    else if($('#link_error').length > 0) {
      $('#link_error').remove();
    }
  });

});
