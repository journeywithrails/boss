if (screen.width <= 800)
{
  document.write("<img src='/images/Chunk_Banner_small.gif'>")
  document.write("<br/>")
}
else if(screen.width < 1400)
{
  //document.write("<img src='/images/Chunk_Banner_medium.gif'>")
  document.write("<img src='/images/Chunk_Banner.gif'>")
  document.write("<br/>")
}
else 
{
  document.write("<img src='/images/Chunk_Banner_large.gif'>")
  document.write("<br/>")
}

