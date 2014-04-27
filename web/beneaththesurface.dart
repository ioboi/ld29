library ld29;


import 'dart:html';
import 'dart:math';
import 'dart:web_audio';

part 'game.dart';
part 'entity.dart';
part 'tilesheet.dart';
part 'world.dart';



void main() {
  Sample.init();
  Game g = new Game(document.getElementById("board"));
  g.start();
}
