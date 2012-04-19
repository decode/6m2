$(function() {
  $("#desSlideshow1").desSlideshow({
    autoplay: 'enable',//option:enable,disable
  slideshow_width: '800',//slideshow window width
  slideshow_height: '249',//slideshow window height
  thumbnail_width: '200',//thumbnail width
  time_Interval: '4000',//Milliseconds
  directory: 'images/'// flash-on.gif and flashtext-bg.jpg directory
  });
  $("#desSlideshow2").desSlideshow({
    autoplay: 'disable',//option:enable,disable
    slideshow_width: '600',//slideshow window width
    slideshow_height: '249',//slideshow window height
    thumbnail_width: '120',//thumbnail width
    time_Interval: '4000',//Milliseconds
    directory: 'images/'// flash-on.gif and flashtext-bg.jpg directory
  });
});
