import 'dart:html';
import 'dart:async';

const String BLACK = '#BADA55';
const String WHITE = '#FFFFFF';
final Duration ONE_SECOND = new Duration(seconds:1);

ButtonElement generateButton;
ButtonElement runButton;
ButtonElement cancelButton;

Board board;
Timer timer;

void main() {

  generateButton = querySelector("#generateButton");
  generateButton.onClick.listen( createBoard );
  
  runButton = querySelector("#runButton");
  runButton.onClick.listen( startRunning );
  
  cancelButton = querySelector('#cancelButton');
  cancelButton.onClick.listen( stopRunning );
  
}

createBoard( Event e ) {
  InputElement rowsInput = querySelector("#rows");
  InputElement columnsInput = querySelector("#columns");
  
  Element circles = querySelector("#board");
  circles.children.clear();
  
  final int rows = int.parse( rowsInput.value );
  final int columns = int.parse( columnsInput.value );
  final int dX = 75;
  final int dY = 75;
  
  board = new Board( rows, columns );
  
  for (int i=0; i < rows; i++) {
    for (int j=0; j < columns; j++ ) {
      board.putItem( new Circle( circles, i*dY, j*dX),
          i, j );
    }
  }
  
  runButton.disabled = false;  
}

startRunning(Event _) {
  timer = new Timer.periodic( ONE_SECOND, (_) => board.run() );
  flipButtonState();
}

stopRunning(Event _) {
  timer.cancel();
  flipButtonState();
}

flipButtonState() {
  runButton.disabled = !runButton.disabled;
  cancelButton.disabled = !cancelButton.disabled;
}

class Circle {
  DivElement c = new DivElement();
  bool filled = false;
  int neighborCount = 0;
  
  Circle( Element parent, int top, int left ) {
    c.className = 'circle';
    c.style
      ..position = "absolute"
      ..top = "${top}px"
      ..left = "${left}px";
      
    c.onClick.listen( _flipState );
    parent.children.add(c);
  }
  
  _flipState( Event e ) => (filled) ? clear() : fill();
  
  clear() {
    c.style.background = WHITE;
    filled=false;
  }
  
  fill() {
    c.style.background = BLACK;
    filled=true;
  }
}

// 'typedef' lets you 'type' a function, 
//  so you can get compile-time hints
typedef void CellVisitor( Circle c, int i, int j );

class Board { 
  int length;
  int width;
  List<List<Circle>> _board; 
  
  static final List< List<int> > _VISIT_ORDER = [
    [-1,-1], [-1,0], [-1,1],
    [0, -1],          [0,1],
    [1, -1], [1, 0],  [1,1]
  ];
  
  Board( int rows, int columns ) {
    length = rows;
    width = columns;
    _board = new List<List<Circle>>(rows);
    for (int i=0; i < rows; i++) {
      _board[i] = new List<Circle>( columns );
    }
  }
  
  putItem( Circle c, int row, int column) {
    _board[row][column] = c;
  }
  
  // Allow clients to 'clock' the game one iteration
  void run() {
    _eachCell( _markNeighbors );
    _eachCell( _enforceRules );
  }
  
  // Internal iterator method that takes a function
  // and applies it to each cell. Note the '_' prepended
  // to the name.  This is how Dart knows this is a private
  // method.
  void _eachCell( CellVisitor visitor ) {
    for (int i=0; i < length ; i++) {
      for (int j=0; j < width; j++ ) {
        visitor( _board[i][j], i, j );
      }
    }
  }
  
  // callback function that operates on the board
  // when it's yielded a Cell, and its position.
  void _markNeighbors( Circle c, int i, int j ) {
    int neighbors = 0;
    
    _VISIT_ORDER.forEach( (List<int> offsets) {
      int dy = offsets[0];
      int dx = offsets[1];
      Circle neighbor = _itemAt( i + dx, j + dy );
      if (null != neighbor) {
        neighbors += neighbor.filled ? 1 : 0;
      }
    }); 
    c.neighborCount = neighbors;
  }
  
  // Implements logic to retrieve an item from
  // the internal board, with appropriate bounds checking
  Circle _itemAt( int i, int j ) {
    if ( (i < 0) || (i > length-1)) {
      return null;
    }
    if ( (j < 0) || (j > width-1 ) ) {
      return null;
    }
    
    return _board[i][j];
  }
  
  void _enforceRules( Circle c, int i, int j) {
    if (c.filled) {
      final neighbors = c.neighborCount;
      if ( (neighbors < 2) || (neighbors > 3)) {
        c.clear(); // dead, rule #1
      }
      //2 or 3, you're still alive!
    } else if (c.neighborCount == 3) {
        c.fill();
    }
    
    //reset our neighbor count
    c.neighborCount = 0;
  }
}


