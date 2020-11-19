var theimg=document.getElementById("theimg")


onICHostReady = function(version) {
   gICAPI.onFocus = function(polarity) {
   }
   gICAPI.onData = function(data) {
     theimg.src=data;
   }
   gICAPI.onProperty = function(p) {
   }
}

function getUrl() {
  return window.location.href;
}
