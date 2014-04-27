part of ld29;

abstract class Entity{
  double x;
  double y;
  bool dead = false;
  
  Entity(this.x, this.y){
    
  }
  
  void tick();
  void render(CanvasRenderingContext2D ctx);
}

class ParticleEmitter extends Entity{
  
  List<Particle> particles;
  Random r = new Random();
  bool dead = false;
  
  ParticleEmitter(double x, double y, num particles) : super(x, y){
    this.particles = new List();
    for(int i = 0; i < particles; i++){
      this.particles.add(new Particle(x, y, r.nextInt(50), r.nextDouble()*10.0-5, r.nextDouble()*-10.0,r.nextInt(5)));
    }
  }
  
  @override
  void render(CanvasRenderingContext2D ctx) {
    ctx.fillStyle = "#492c11";
    for(int i = 0; i < particles.length; i++){
      Particle p = particles[i];
      p.render(ctx);
    }
  }
  
  int deadcount = 0;

  @override
  void tick() {
    for(int i = 0; i < particles.length; i++){
          Particle p = particles[i];
            if(p.dead){
              particles.removeAt(i--);
              deadcount++;
              continue; 
            }
            p.tick();
        }
    
    if(deadcount == particles.length){
        this.dead = true;
     }
  }
}

class Particle extends Entity{
  
  int tickcount;
  double velocityY;
  double velocityX;
  bool dead = false;
  int size;
  
  Particle(double x, double y, this.tickcount, this.velocityX, this.velocityY, this.size) : super(x, y);
  
  @override
  void render(CanvasRenderingContext2D ctx) {
    ctx.fillRect(x, y, this.size, this.size);
  }

  @override
  void tick() {
    this.x += this.velocityX;
    this.y += this.velocityY;
    this.velocityY += 1.0;
    if(this.tickcount <= 0){
      this.dead = true;
    }
    this.tickcount--;
  }
}

abstract class Driller extends Entity{
  static final int DirectionDOWN = 0;
  static final int DirectionLEFT = 1;
  static final int DirectionRIGHT = 2;
    
  int direction = DirectionDOWN;
  int nextDirection = DirectionDOWN;
  
  Tilesheet sheet;
  World world;
  int price = 0;
  int drilltime = 0;
  int tickcount = 0;
  int level = 0;
  Driller(double x, double y, this.sheet, this.world) : super(x, y);
}

class Oildriller extends Driller{
  
  int tox = 0;
  
  Oildriller(double x, double y, Tilesheet sheet, World world) : super(x, y, sheet, world){ 
    this.price = 10;
    this.drilltime = 120;
  }
  
  @override
  void render(CanvasRenderingContext2D ctx) {
    this.sheet.renderVariableTile(ctx, this.x, this.y, 4, 32, 1);
  }

  @override
  void tick() {
    tickcount++;
    if(tickcount % drilltime == 0){
      this.direction = this.nextDirection;
      
      if(this.direction == Driller.DirectionDOWN){
        level++;
        world.drillDown(this,this.x+tox*32, this.y+level*32, 3);  
      }
      
      if(this.direction == Driller.DirectionLEFT){
        tox--;
        world.drillLeft(this, this.x+tox*32, this.y+level*32, 8+4);
      }
      
      if(this.direction == Driller.DirectionRIGHT){
        tox++;
        world.drillLeft(this, this.x+tox*32, this.y+level*32, 8+4);
      }
    }
  }
}