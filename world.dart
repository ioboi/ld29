part of ld29;

class Diamond {
  int value;
  Diamond(this.value);
}

class DrillEnd {
  int index;
  int direction;
  bool dead = false;
  DrillEnd(this.index, this.direction);
}

class World {

  static final int TILE_BEDROCK = 8 + 5;
  static final int TILE_PIPELEFTORRIGHT = 8 + 4;
  static final int TILE_PIPEDOWN = 3;
  static final int TILE_PIPEDOWNRIGHT = 8 + 4;
  static final int TILE_PIPEDOWNLEFT = 8 + 3;
  static final int TILE_ROCK = 2 * 8 + 4;

  static final int TILE_BIGDIAMOND = 6;
  static final int TILE_BIGSAPHIRE = 8 + 7;
  static final int TILE_SMALLSAPHIRE = 7;
  static final int TILE_SMALLDIAMOND = 4;

  Game game;

  num w;
  num h;

  int totalValue = 0;

  List<int> tiles;
  List<Driller> drillers;

  Tilesheet sheet;

  List<ParticleEmitter> emitters;

  Random r = new Random(1222377771217);

  int money = 10;

  num scrollY = 0;

  Map<int, Diamond> diamonds = new Map();

  Map<Driller, DrillEnd> drillends = new Map();


  World(this.sheet, this.w, this.h, this.game) {
    this.tiles = new List((this.w * this.h).toInt());
    this.emitters = new List();
    this.drillers = new List();
    this.generateWorld();
  }

  void generateWorld() {
    for (int y = 0; y < this.h; y++) {
      for (int x = 0; x < this.w; x++) {
        if (y < 5) {
          tiles[(x + y * this.w).toInt()] = 2;
          continue;
        }

        if (y == 5) {
          tiles[(x + y * this.w).toInt()] = 1;
          continue;
        }

        if (y == this.h - 1) {
          tiles[(x + y * this.w).toInt()] = 8 + 5;
          continue;
        }

        if (y > 5 && y < this.h - (this.h / 2)) {
          int yesorno = r.nextInt(40);

          if (yesorno == 4 || yesorno == 1) {
            tiles[(x + y * this.w).toInt()] = TILE_SMALLSAPHIRE;
            diamonds[(x + y * this.w).toInt()] = new Diamond(2);
            totalValue += 2;
          }
          
          if (yesorno == 12) {
            tiles[(x + y * this.w).toInt()] = TILE_BIGSAPHIRE;
            diamonds[(x + y * this.w).toInt()] = new Diamond(4);
            totalValue += 4;
            continue;
          }

          if (yesorno == 5 ||yesorno == 20) {
            tiles[(x + y * this.w).toInt()] = TILE_ROCK;
          }
          continue;
        }


        int yesorno = r.nextInt(40);

        if (yesorno == 1 ||yesorno == 2) {
          tiles[(x + y * this.w).toInt()] = TILE_SMALLDIAMOND;
          diamonds[(x + y * this.w).toInt()] = new Diamond(5);
          totalValue += 5;
          continue;
        }

        if (yesorno == 18) {
          tiles[(x + y * this.w).toInt()] = TILE_BIGDIAMOND;
          diamonds[(x + y * this.w).toInt()] = new Diamond(10);
          totalValue += 10;
          continue;
        }

        if (yesorno == 12) {
          tiles[(x + y * this.w).toInt()] = TILE_BIGSAPHIRE;
          diamonds[(x + y * this.w).toInt()] = new Diamond(4);
          totalValue += 4;
          continue;
        }

        if (yesorno == 5 || yesorno == 10 || yesorno == 20) {
          tiles[(x + y * this.w).toInt()] = TILE_ROCK;
          continue;
        }


        tiles[(x + y * this.w).toInt()] = 0;
      }
    }
  }

  void render(CanvasRenderingContext2D ctx, num posx, num posy, num w, num h) {
    num hs = h + scrollY;
    num sy = posy + scrollY;

    for (int y = sy; y < hs; y++) {
      for (int x = posx.toInt(); x < w; x++) {
        if (y >= this.h) {
          continue;
        }
        if (this.tiles[x + y * w] == -1) {
          ctx.fillStyle = "#000";
          ctx.fillRect(x * sheet.scale * sheet.tilesize, y * sheet.scale * sheet.tilesize, sheet.scale * sheet.tilesize, sheet.scale * sheet.tilesize);
          continue;
        }

        if (this.tiles[x + y * w] == 999) {
          ctx.fillStyle = "#F0F";
          ctx.fillRect(x * sheet.scale * sheet.tilesize, y * sheet.scale * sheet.tilesize, sheet.scale * sheet.tilesize, sheet.scale * sheet.tilesize);
        }
        this.sheet.renderTile(ctx, x * sheet.scale * sheet.tilesize, y * sheet.scale * sheet.tilesize, this.tiles[x + y * w]);
      }
    }
  }

  void renderEntities(CanvasRenderingContext2D ctx) {
    for (int i = 0; i < drillers.length; i++) {
      Driller d = drillers[i];
      d.render(ctx);
    }

    for (ParticleEmitter p in emitters) {
      p.render(ctx);
    }
  }

  void tick() {

    for (int i = 0; i < emitters.length; i++) {
      ParticleEmitter p = emitters[i];
      p.tick();
      if (p.dead) {
        emitters.removeAt(i--);
      }
    }

    for (int i = 0; i < drillers.length; i++) {
      Driller d = drillers[i];
      if (!d.dead) {
        d.tick();
      }

    }
  }

  void setScrollY(num scroll) {
    this.scrollY = -1 * (scroll / 32).ceil();
  }

  void drillDown(Driller src, num posx, num posy, num index) {
    int x = (posx / 32).floor();
    int y = (posy / 32).floor();

    if (doesCollide(x, y)) {
      src.dead = true;
      this.drillends[src].dead = true;
      if (Sample.collision.loaded) {
        Sample.collision.play();
      }
      if (this.isBedrock(x, y)) {
        endGame();
      }

      if (checkForGameEnd()) {
        this.game.setState(Game.STATE_PLAYEND);

      }

      return;
    }

    getDiamond(x, y);

    this.tiles[x + y * w] = index;
    this.drillends[src] = new DrillEnd(x + y * w, Driller.DirectionDOWN);
    this.emitters.add(new ParticleEmitter(x.toDouble() * 32 + 16.0, y.toDouble() * 32 + 16.0, 200));
    if (Sample.explode.loaded) {
      Sample.explode.play();
    }
  }

  bool isBedrock(int x, int y) {
    int id = tiles[x + y * w];
    if (id == TILE_BEDROCK) {
      return true;
    }
    return false;
  }

  void endGame() {
    this.game.setState(Game.STATE_PLAYEND);
  }

  void getDiamond(int x, int y) {
    if (this.diamonds.containsKey(x + y * w)) {
      Diamond d = this.diamonds[x + y * w];
      this.money += d.value;
      this.diamonds.remove(x + y * w);
      if (Sample.pickup.loaded) {
        Sample.pickup.play();
      }
    }
  }

  void drillRight(Driller src, num posx, num posy, num index) {
    int x = (posx / 32).floor();
    int y = (posy / 32).floor();

    if (doesCollide(x, y)) {
      src.dead = true;
      this.drillends[src].dead = true;
      if (Sample.collision.loaded) {
        Sample.collision.play();
      }

      if (checkForGameEnd()) {
        this.game.setState(Game.STATE_PLAYEND);

      }
      return;
    }

    getDiamond(x, y);

    this.tiles[x + y * w] = index;
    this.drillends[src] = new DrillEnd(x + y * w, Driller.DirectionRIGHT);
    this.emitters.add(new ParticleEmitter(x.toDouble() * 32 + 16.0, y.toDouble() * 32 + 16.0, 200));
    if (Sample.explode.loaded) {
      Sample.explode.play();
    }
  }

  void drillLeft(Driller src, num posx, num posy, num index) {

    int x = (posx / 32).floor();
    int y = (posy / 32).floor();

    if (doesCollide(x, y)) {
      src.dead = true;
      this.drillends[src].dead = true;
      if (Sample.collision.loaded) {
        Sample.collision.play();
      }

      if (checkForGameEnd()) {
        this.game.setState(Game.STATE_PLAYEND);

      }

      return;
    }

    getDiamond(x, y);

    this.tiles[x + y * w] = index;
    this.drillends[src] = new DrillEnd(x + y * w, Driller.DirectionLEFT);
    this.emitters.add(new ParticleEmitter(x.toDouble() * 32 + 16.0, y.toDouble() * 32 + 16.0, 200));
    if (Sample.explode.loaded) {
      Sample.explode.play();
    }
  }

  bool clickOnDrillerEnd(num posx, num posy) {
    int x = (posx / sheet.tilesize / sheet.scale).floor();
    int y = (posy / sheet.tilesize / sheet.scale).floor();
    int index = x + y * w;

    for (Driller driller in this.drillends.keys) {
      DrillEnd d = this.drillends[driller];
      if (d.index == index) {
        if (d.dead) {
          return false;
        }

        d.direction = getNextDirection(driller.direction, d.direction);
        this.tiles[x + y * w] = this.getNextTile(driller.direction, d.direction);
        driller.nextDirection = d.direction;

        if (Sample.move.loaded) {
          Sample.move.play();
        }
        return true;
      }
    }
    return false;
  }

  int getNextDirection(int now, int dir) {
    if (now == Driller.DirectionDOWN) {
      if (dir == Driller.DirectionDOWN) {
        return Driller.DirectionLEFT;
      }

      if (dir == Driller.DirectionLEFT) {
        return Driller.DirectionRIGHT;
      }

      if (dir == Driller.DirectionRIGHT) {
        return Driller.DirectionDOWN;
      }
    }

    if (now == Driller.DirectionLEFT) {
      if (dir == Driller.DirectionLEFT) {
        return Driller.DirectionDOWN;
      }
      return Driller.DirectionLEFT;
    }

    if (now == Driller.DirectionRIGHT) {
      if (dir == Driller.DirectionRIGHT) {
        return Driller.DirectionDOWN;
      }
      return Driller.DirectionRIGHT;
    }

    return Driller.DirectionDOWN;
  }

  bool doesCollide(num x, num y) {
    if (x < 0) {
      return true;
    }

    if (x >= this.w) {
      return true;
    }

    int id = this.tiles[x + y * w];
    if (id == TILE_PIPELEFTORRIGHT) {
      return true;
    }

    if (id == TILE_BEDROCK) {
      return true;
    }

    if (id == TILE_PIPEDOWN) {
      return true;
    }

    if (id == TILE_PIPEDOWNLEFT) {
      return true;
    }

    if (id == TILE_PIPEDOWNRIGHT) {
      return true;
    }

    if (id == TILE_ROCK) {
      return true;
    }

    return false;
  }

  int getNextTile(int now, int dir) {
    if (now == Driller.DirectionDOWN) {
      if (dir == Driller.DirectionLEFT) {
        return 2 * 8 + 3;
      }
      if (dir == Driller.DirectionRIGHT) {
        return 2 * 8 + 2;
      }

      if (dir == Driller.DirectionDOWN) {
        return 3;
      }
    }

    if (now == Driller.DirectionLEFT) {
      if (dir == Driller.DirectionDOWN) {
        return 8 + 2;
      }
      return 8 + 4;
    }

    if (now == Driller.DirectionRIGHT) {
      if (dir == Driller.DirectionDOWN) {
        return 8 + 3;
      }
      return 8 + 4;
    }
    return 3;
  }

  bool isBuildable(num posx, num posy) {

    int x = (posx / sheet.tilesize / sheet.scale).floor();
    int y = (posy / sheet.tilesize / sheet.scale).floor();

    if (y > this.h) {
      return false;
    }

    int i = this.tiles[x + y * this.w];

    if (i == 2 && y == 4) {
      for (Driller d in this.drillers) {
        if (d.x == x * 32) {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  bool checkForGameEnd() {
    int deadcounter = 0;
    for (Driller d in this.drillers) {
      if (d.dead) {
        deadcounter++;
      }
    }
    
    if(deadcounter == drillers.length && money < 10){
      return true;
    }
    
    return deadcounter == this.w;
  }

  void addDriller(num posx, num posy, int type) {
    if (type == 0) {
      //ensure the right positions
      int x = (posx / sheet.tilesize / sheet.scale).floor() * 32;
      int y = (posy / sheet.tilesize / sheet.scale).floor() * 32;
      this.drillers.add(new Oildriller(posx.toDouble(), y.toDouble(), sheet, this));
      if (Sample.done.loaded) {
        Sample.done.play();
      }
    }
  }

  void renderScf(CanvasRenderingContext2D ctx, num posx, num posy, int type) {
    if (type == 0) {
      //ensure the right positions
      int x = (posx / sheet.tilesize / sheet.scale).floor() * 32;
      int y = (posy / sheet.tilesize / sheet.scale).floor() * 32;
      this.sheet.renderVariableTile(ctx, x.toDouble(), y.toDouble(), 4, 32, 1);
    }
  }
  
  void reset(){
      this.money = 10;
      this.totalValue = 0;
      this.drillends.clear();
      this.tiles = new List(this.w*this.h);
      this.drillers.clear();
      this.emitters.clear();
      this.diamonds.clear();
      this.generateWorld();
    }
}
