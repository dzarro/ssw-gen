function animate()  // control movie loop
{
 var j;
 next_frame();
 j=frame+1;
 if (images[frame].complete) {
   //document.animation.src=images[frame].src;
   let curImage = document.getElementById("animation");
   let nextImage = images[frame];

   curImage.id = "";
   nextImage.id = "animation";

   curImage.replaceWith(nextImage);
 
   document.form.frame.value="Displaying "+j+" of "+imax;
   if (swingon && (j == (rstop+1) || frame == rstart)) reverse();
   timeout_id=setTimeout("animate()",delay);
   playing=1;
 }
}

///////////////////////////////////////////////////////////////////////////

function oneStep() // step frames
{
 var j;
 if (timeout_id) clearTimeout(timeout_id); timeout_id=null;
 next_frame();
 j=frame+1;
 if (images[frame].complete) {
    //document.animation.src=images[frame].src;

   let curImage = document.getElementById("animation");
   let nextImage = images[frame];

   curImage.id = "";
   nextImage.id = "animation";

   curImage.replaceWith(nextImage);

    document.form.frame.value="Displaying "+j+" of "+imax;
    if (swingon && (j == (rstop+1) || frame == rstart)) reverse();
    playing=0;
 }
}

///////////////////////////////////////////////////////////////////////////

function reverse()  // reverse direction
