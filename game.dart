part of ld29;

class Mouse {
  num x = 0;
  num y = 0;
  num rx = 0;
  num ry = 0;

  num tilesize;

  Mouse(this.tilesize);

  void snapToGrid(num px, num py, num scroll) {
    this.x = (px / tilesize).floor() * tilesize;
    this.y = ((py - scroll) / 32).floor() * 32.0;
  }
}

class Game {

  static final int WORLD_WIDTH = 20;
  static final int WORLD_HEIGHT = 128;
  static final int SCROLLSPEED = 12;

  static final int STATE_PLAYSCREEN = 0;
  static final int STATE_PLAY = 1;
  static final int STATE_RESET = 2;
  static final int STATE_PLAYEND = 3;

  CanvasElement canvas;
  CanvasElement tilelayer;
  CanvasRenderingContext2D ctx;
  CanvasRenderingContext2D tilectx;
  
  ImageElement title;

  int lastTime = new DateTime.now().millisecondsSinceEpoch;
  double unprocessedFrames = 0.0;

  World world;
  Tilesheet sheet;

  int state = STATE_PLAYSCREEN;

  bool pause = false;
  bool renderNormalCursor = true;

  String nnumbers = "1234567890";

  Mouse mouse;

  int scrollY = 0;
  int scroll = 0;

  int selection = -1;

  Game(this.canvas) {
    this.ctx = this.canvas.getContext("2d");
    this.ctx.imageSmoothingEnabled = false;

    mouse = new Mouse(32);

    this.canvas.addEventListener("mousemove", (MouseEvent e) {
      if (this.world.isBuildable(e.offset.x, e.offset.y - scrollY) && state == Game.STATE_PLAY) {
        this.mouse.rx = e.offset.x;
        this.mouse.ry = e.offset.y;
        this.renderNormalCursor = false;
        return;
      }
      this.renderNormalCursor = true;
    });

    this.canvas.addEventListener("click", (MouseEvent e) {
      if (this.world.clickOnDrillerEnd(e.offset.x, e.offset.y - scrollY) && state == Game.STATE_PLAY) {
        return;
      }

      if (this.world.isBuildable(e.offset.x, e.offset.y - scrollY) && state == Game.STATE_PLAY) {
        if (!(this.world.money - 10 < 0)) {
          this.world.addDriller(mouse.x.toDouble(), e.offset.y - scrollY, 0);
          this.world.money -= 10;
        }
      }
    });

    this.canvas.addEventListener("mousemove", (MouseEvent e) {
      this.mouse.snapToGrid(e.offset.x, e.offset.y, scrollY);
    });

    document.body.addEventListener("keyup", (KeyboardEvent e) {
      if (e.keyCode == 32) {
        if(this.state == Game.STATE_PLAYSCREEN){
          this.state = Game.STATE_PLAY;
          return;
        }
        if(this.state == Game.STATE_PLAY){
          pause = !pause;  
        }
        
        if(this.state == Game.STATE_PLAYEND){
          this.restart();
        }
      }

      //scroll down
      if ((e.keyCode == 40 || e.keyCode == 83) && state == Game.STATE_PLAY) {
        scroll = 0;
      }

      //scroll up
      if ((e.keyCode == 38 || e.keyCode == 87) && state == Game.STATE_PLAY) {
        scroll = 0;
      }

    });

    document.body.addEventListener("keydown", (KeyboardEvent e) {
      //scroll down
      if ((e.keyCode == 40 || e.keyCode == 83)&& state == Game.STATE_PLAY) {
        scroll = -SCROLLSPEED;
        this.renderNormalCursor = true;
      }

      //scroll up
      if ((e.keyCode == 38 || e.keyCode == 87) && state == Game.STATE_PLAY) {
        scroll = SCROLLSPEED;
        this.renderNormalCursor = true;
      }

    });

    this.tilelayer = new CanvasElement();
    this.tilelayer.width = 640;
    this.tilelayer.height = 128 * 32;
    this.tilectx = this.tilelayer.getContext("2d");
    this.tilectx.imageSmoothingEnabled = false;
  }

  void setState(int state) {
    this.state = state;
  }

  void start() {
    ImageElement image = new ImageElement();
    image.onLoad.listen((e) {
      sheet = new Tilesheet(image, 16, 2);
      world = new World(sheet, WORLD_WIDTH, WORLD_HEIGHT, this);
      title = new ImageElement();
      title.onLoad.listen((e){
        window.requestAnimationFrame(loop);
      });
      title.src = "title.png";
    });
    image.src = "tile.png";
  }

  void loop(double time) {
    try {
      int now = new DateTime.now().millisecondsSinceEpoch;
      unprocessedFrames += (now - lastTime) * 60.0 / 1000.0;
      lastTime = now;
      if (unprocessedFrames > 10.0) unprocessedFrames = 10.0;
      while (unprocessedFrames > 1.0) {
        tickcount++;
        if(this.state == Game.STATE_PLAY){
          tick();  
        }
        unprocessedFrames -= 1.0;
      }
      if(this.state == Game.STATE_PLAY){
        render();
      }
      
      if(this.state == Game.STATE_PLAYEND){
        renderEndScreen();
      }
      
      if(this.state == Game.STATE_PLAYSCREEN){
        renderPlayScreen();
      }
      window.requestAnimationFrame(loop);
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  void drawNumberString(String input, CanvasRenderingContext2D ctx, num posx, posy) {

    num start = posx;

    sheet.renderTile(ctx, start, posy, 8 * 7);
    start += 8*4;
    
    for (int i = 0; i < input.length; i++) {
      sheet.renderVariableTile(ctx, start, posy, nnumbers.indexOf(input[i]) + 16 * 15 + 2, 8, 4);
      start += 8 * 4;
    }

    
  }
  
  int tickcount = 0;
  
  void renderPlayScreen(){
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    this.ctx.fillStyle = "#000";
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
    this.ctx.drawImageScaledFromSource(this.title, 0, 0, this.title.width, 26, 20, 40, 600, 100);
    double scale = (sin(tickcount)/20)*40;
    this.ctx.drawImageScaledFromSource(this.title, 0, 30, this.title.width, this.title.height-26, 20, 170, 600+scale, 100+scale);
  }
  
  void renderEndScreen(){
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    this.ctx.fillStyle = "#000";
    this.ctx.fillRect(0, 0, this.canvas.width, this.canvas.height);
    this.ctx.drawImageScaledFromSource(this.title, 0, 0, this.title.width, 26, 20, 40, 600, 100);
    this.ctx.fillStyle = "#b86f29";
    this.ctx.font = "30px Arial";
    this.ctx.textAlign = "left";
    this.ctx.fillText("Thank you for playing my game :)", 60, 200);
    this.ctx.fillText("You made "+world.money.toString()+" out of "+(world.totalValue-10).toString()+"\$", 60, 250);
    this.ctx.fillText("Press Space to restart", 60, 300);
  }
  
  void restart(){
    this.world.reset();
    this.state = Game.STATE_PLAY;
  }

  void render() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    this.tilectx.clearRect(0, -scrollY, 640, 480 + (-scrollY));

    world.render(tilectx, 0, 0, 20, 18);
    world.renderEntities(tilectx);


    if (!this.renderNormalCursor) {
      world.renderScf(tilectx, mouse.x, mouse.ry - scrollY, 0);
    }
    ctx.drawImage(tilelayer, 0, scrollY);

    drawNumberString(this.world.money.toString(), ctx, 10, 10);

    if (pause) {
      ctx.fillStyle = "#2f1c0b";
      ctx.textAlign = "right";
      ctx.font = "30px Arial";
      ctx.fillText("Paused", this.canvas.width-30, 40);
    }
  }

  void tick() {
    scrollY += scroll;
    if (scrollY >= 0) {
      scrollY = 0;
    }

    if (scrollY < -this.world.h * 32 + 480) {
      scrollY = -this.world.h * 32 + 480;
    }

    this.world.setScrollY(scrollY);
    if (!pause) {
      world.tick();
    }
  }
}

//Some parts of this class are borrowed from notch
//I hope this is not against the rules :(
class Sample {
static AudioContext context;
static GainNode gainNode;

static Sample explode = new Sample("sound/explosion.wav");
static Sample collision = new Sample("sound/collision.wav");
static Sample move = new Sample("sound/move.wav");
static Sample done = new Sample("sound/done.wav");
static Sample pickup = new Sample("sound/pickup.wav");

static bool soundFailed = false;
static bool soundOn = true;

static void init() {
  try {
    context = new AudioContext();
    gainNode = context.createGainNode();
    gainNode.connectNode(context.destination);

    explode.load();
    collision.load();
    move.load();
    done.load();
    pickup.load();
  } catch (e) {
    print(e);
    soundFailed = true;
  }
}

bool loaded = false;
HttpRequest request;
AudioBuffer buffer;
String path;

Sample(this.path) {
}

void load() {
  try {
    request = new HttpRequest();
    request.responseType = "arraybuffer";
    request.onLoad.listen(sampleLoaded);
    request.open("GET", path, async: true);
    request.send();
  } catch (e) {
    print(e);
  }
}

void sampleLoaded(ProgressEvent e) {
  context.decodeAudioData(request.response).then((e) {
    buffer = e;
    loaded = true;
  });
}

void play() {
  if (!loaded || soundFailed || !soundOn) return;
  try {
    AudioBufferSourceNode sourceNode = context.createBufferSource();
    sourceNode.connectNode(gainNode);
    sourceNode.buffer = buffer;
    sourceNode.noteOn(0);
  } catch (e) {
    print(e);
    soundFailed = true;
  }
}
}
