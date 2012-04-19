$(document).ready(function(){

  $("#nicemenu img.arrow").click(function(){ 

    $("span.head_menu").removeClass('active');

    submenu = $(this).parent().parent().find("div.sub_menu");

    if(submenu.css('display')=="block"){
      $(this).parent().removeClass("active"); 	
      submenu.hide(); 		
      $(this).attr('src','/images/arrow_hover.png');									
    }else{
      $(this).parent().addClass("active"); 	
      submenu.fadeIn(); 		
      $(this).attr('src','/images/arrow_select.png');	
    }

    $("div.sub_menu:visible").not(submenu).hide();
    $("#nicemenu img.arrow").not(this).attr('src','/images/arrow.png');

  })
  .mouseover(function(){ $(this).attr('src','/images/arrow_hover.png'); })
    .mouseout(function(){ 
      if($(this).parent().parent().find("div.sub_menu").css('display')!="block"){
        $(this).attr('src','/images/arrow.png');
      }else{
        $(this).attr('src','/images/arrow_select.png');
      }
    });

  $("#nicemenu span.head_menu").mouseover(function(){ $(this).addClass('over')})
    .mouseout(function(){ $(this).removeClass('over') });

  $("#nicemenu div.sub_menu").mouseover(function(){ $(this).fadeIn(); })
    .blur(function(){ 
      $(this).hide();
      $("span.head_menu").removeClass('active');
    });		

  $(document).click(function(event){ 		
    var target = $(event.target);
    if (target.parents("#nicemenu").length == 0) {				
      $("#nicemenu span.head_menu").removeClass('active');
      $("#nicemenu div.sub_menu").hide();
      $("#nicemenu img.arrow").attr('src','/images/arrow.png');
    }
  });			   


});
