part of ld29;

class Tilesheet{
  
  ImageElement img;
  int tilesize;
  num tilesx;
  num tilesy;
  num scale = 2;
  
  Tilesheet(this.img, this.tilesize, this.scale){
    this.tilesx = this.img.width/this.tilesize;
    this.tilesy = this.img.height/this.tilesize;
  }
  
  void renderTile(CanvasRenderingContext2D ctx,num posx, num posy, int index){
    num tx = 0;
    num ty = 0;
    for(int x = 0; x < tilesx; x++){
      for(int y = 0; y < tilesy; y++ ){
        if((x + y * tilesx) == index){
          tx = x*tilesize;
          ty = y*tilesize;
        }
      }
    }
    ctx.drawImageScaledFromSource(this.img, tx, ty, tilesize, tilesize, posx, posy, tilesize*scale , tilesize*scale);
  }
  
  void renderVariableTile(CanvasRenderingContext2D ctx, num posx, num posy, int index, int tilesize, int scale){
    num tx = 0;
    num ty = 0;
    
    num tsx = this.img.width/tilesize;
    num tsy = this.img.height/tilesize;
    
    for(int x = 0; x < tsx; x++){
      for(int y = 0; y < tsy; y++){
        if((x+y*tsx) == index){
          tx = x*tilesize;
          ty = y*tilesize;
        }
      }
      ctx.drawImageScaledFromSource(this.img, tx, ty, tilesize, tilesize, posx, posy, tilesize*scale , tilesize*scale);
    }
  }
  
}